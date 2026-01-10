/**
 * Media Service Unit Tests
 * Tests for 9 media processing functions
 */

import { describe, it, expect, jest, beforeEach, afterEach } from '@jest/globals';
import * as admin from 'firebase-admin';

// Mock sharp
const mockSharp = {
  resize: jest.fn().mockReturnThis(),
  jpeg: jest.fn().mockReturnThis(),
  toBuffer: jest.fn(),
};
jest.mock('sharp', () => jest.fn(() => mockSharp));

// Mock fluent-ffmpeg
const mockFfmpeg = jest.fn();
const mockFfmpegInstance = {
  screenshots: jest.fn().mockReturnThis(),
  on: jest.fn().mockReturnThis(),
};
mockFfmpeg.ffprobe = jest.fn();
jest.mock('fluent-ffmpeg', () => mockFfmpeg);

// Mock Google Cloud Vision
const mockVisionClient = {
  safeSearchDetection: jest.fn(),
};
jest.mock('@google-cloud/vision', () => ({
  ImageAnnotatorClient: jest.fn(() => mockVisionClient),
}));

// Mock Google Cloud Speech
const mockSpeechClient = {
  longRunningRecognize: jest.fn(),
  recognize: jest.fn(),
};
jest.mock('@google-cloud/speech', () => ({
  SpeechClient: jest.fn(() => mockSpeechClient),
}));

// Mock UUID
jest.mock('uuid', () => ({
  v4: jest.fn(() => 'test-uuid-1234'),
}));

// Mock Firebase Admin
jest.mock('firebase-admin', () => ({
  firestore: {
    FieldValue: {
      serverTimestamp: jest.fn(() => 'SERVER_TIMESTAMP'),
    },
  },
}));

// Mock shared utils
const mockDb = {
  collection: jest.fn(),
};

const mockBucket = {
  file: jest.fn(),
  upload: jest.fn(),
};

const mockStorage = {
  bucket: jest.fn(() => mockBucket),
};

jest.mock('../../src/shared/utils', () => ({
  verifyAuth: jest.fn(),
  handleError: jest.fn((error) => error),
  logInfo: jest.fn(),
  logError: jest.fn(),
  db: mockDb,
  storage: mockStorage,
}));

// Import after mocks
import {
  compressUploadedImage,
  compressImage,
  processUploadedVideo,
  generateVideoThumbnail,
  transcribeVoiceMessage,
  transcribeAudio,
  batchTranscribe,
  cleanupDisappearingMedia,
  markMediaAsDisappearing,
} from '../../src/media';

const { verifyAuth } = require('../../src/shared/utils');

describe('Media Service', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    (verifyAuth as jest.Mock).mockResolvedValue('user-123');
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  // ========== 1. COMPRESS UPLOADED IMAGE ==========

  describe('compressUploadedImage', () => {
    it('should compress an uploaded image successfully', async () => {
      const mockFile = {
        download: jest.fn().mockResolvedValue([Buffer.from('image-data')]),
      };
      const mockNewFile = {
        save: jest.fn().mockResolvedValue(undefined),
        makePublic: jest.fn().mockResolvedValue(['https://example.com/compressed.jpg']),
      };

      mockBucket.file.mockImplementation((path: string) => {
        if (path.includes('_compressed')) {
          return mockNewFile;
        }
        return mockFile;
      });

      // Mock sharp compression
      const compressedBuffer = Buffer.from('compressed-data');
      mockSharp.toBuffer.mockResolvedValue(compressedBuffer);

      const event = {
        bucket: 'test-bucket',
        data: {
          name: 'photos/test.jpg',
          contentType: 'image/jpeg',
        },
      };

      // @ts-ignore - Testing storage trigger
      await compressUploadedImage(event);

      expect(mockFile.download).toHaveBeenCalled();
      expect(mockSharp.resize).toHaveBeenCalledWith(1920, 1080, {
        fit: 'inside',
        withoutEnlargement: true,
      });
      expect(mockSharp.jpeg).toHaveBeenCalledWith({ quality: 85, mozjpeg: true });
      expect(mockNewFile.save).toHaveBeenCalled();
    });

    it('should skip non-image files', async () => {
      const event = {
        bucket: 'test-bucket',
        data: {
          name: 'videos/test.mp4',
          contentType: 'video/mp4',
        },
      };

      // @ts-ignore
      await compressUploadedImage(event);

      expect(mockBucket.file).not.toHaveBeenCalled();
    });

    it('should skip already compressed images', async () => {
      const event = {
        bucket: 'test-bucket',
        data: {
          name: 'photos/test_compressed.jpg',
          contentType: 'image/jpeg',
        },
      };

      // @ts-ignore
      await compressUploadedImage(event);

      expect(mockBucket.file).not.toHaveBeenCalled();
    });

    it('should further compress if file is larger than 2MB', async () => {
      const mockFile = {
        download: jest.fn().mockResolvedValue([Buffer.from('image-data')]),
      };
      const mockNewFile = {
        save: jest.fn().mockResolvedValue(undefined),
        makePublic: jest.fn().mockResolvedValue(['https://example.com/compressed.jpg']),
      };

      mockBucket.file.mockImplementation((path: string) => {
        if (path.includes('_compressed')) {
          return mockNewFile;
        }
        return mockFile;
      });

      // First compression > 2MB, second compression < 2MB
      const largeBuf = Buffer.alloc(3 * 1024 * 1024); // 3MB
      const smallBuf = Buffer.alloc(1 * 1024 * 1024); // 1MB

      mockSharp.toBuffer
        .mockResolvedValueOnce(largeBuf)
        .mockResolvedValueOnce(smallBuf);

      const event = {
        bucket: 'test-bucket',
        data: {
          name: 'photos/large.jpg',
          contentType: 'image/jpeg',
        },
      };

      // @ts-ignore
      await compressUploadedImage(event);

      expect(mockSharp.resize).toHaveBeenCalledWith(1280, 720, { fit: 'inside' });
      expect(mockSharp.jpeg).toHaveBeenCalledWith({ quality: 75, mozjpeg: true });
    });
  });

  // ========== 2. COMPRESS IMAGE ==========

  describe('compressImage', () => {
    const mockFetch = global.fetch as jest.Mock;

    beforeEach(() => {
      global.fetch = jest.fn().mockResolvedValue({
        arrayBuffer: jest.fn().mockResolvedValue(new ArrayBuffer(1024)),
      });
    });

    it('should compress an image from URL successfully', async () => {
      const compressedBuffer = Buffer.alloc(1024 * 1024); // 1MB
      mockSharp.toBuffer.mockResolvedValue(compressedBuffer);

      const mockFile = {
        save: jest.fn().mockResolvedValue(undefined),
        getSignedUrl: jest
          .fn()
          .mockResolvedValue(['https://storage.googleapis.com/compressed.jpg']),
      };
      mockBucket.file.mockReturnValue(mockFile);

      const request = {
        auth: { uid: 'user-123' },
        data: {
          imageUrl: 'https://example.com/image.jpg',
          maxSizeMB: 2,
          quality: 85,
        },
      };

      // @ts-ignore
      const result = await compressImage(request);

      expect(global.fetch).toHaveBeenCalledWith('https://example.com/image.jpg');
      expect(mockSharp.resize).toHaveBeenCalled();
      expect(mockFile.save).toHaveBeenCalled();
      expect(result.success).toBe(true);
      expect(result.compressedUrl).toBeDefined();
      expect(result.compressionRatio).toBeGreaterThan(0);
    });

    it('should reject if imageUrl is missing', async () => {
      const request = {
        auth: { uid: 'user-123' },
        data: {},
      };

      // @ts-ignore
      await expect(compressImage(request)).rejects.toThrow('imageUrl is required');
    });

    it('should compress further if initial compression exceeds maxSizeMB', async () => {
      const largeBuf = Buffer.alloc(3 * 1024 * 1024); // 3MB
      const smallBuf = Buffer.alloc(1 * 1024 * 1024); // 1MB

      mockSharp.toBuffer
        .mockResolvedValueOnce(largeBuf)
        .mockResolvedValueOnce(smallBuf);

      const mockFile = {
        save: jest.fn().mockResolvedValue(undefined),
        getSignedUrl: jest
          .fn()
          .mockResolvedValue(['https://storage.googleapis.com/compressed.jpg']),
      };
      mockBucket.file.mockReturnValue(mockFile);

      const request = {
        auth: { uid: 'user-123' },
        data: {
          imageUrl: 'https://example.com/large.jpg',
          maxSizeMB: 2,
          quality: 85,
        },
      };

      // @ts-ignore
      const result = await compressImage(request);

      expect(mockSharp.resize).toHaveBeenCalledWith(1280, 720, { fit: 'inside' });
      expect(mockSharp.jpeg).toHaveBeenCalledWith({ quality: 75, mozjpeg: true });
      expect(result.success).toBe(true);
    });

    it('should require authentication', async () => {
      (verifyAuth as jest.Mock).mockRejectedValue(new Error('Unauthorized'));

      const request = {
        auth: null,
        data: { imageUrl: 'https://example.com/image.jpg' },
      };

      // @ts-ignore
      await expect(compressImage(request)).rejects.toThrow('Unauthorized');
    });
  });

  // ========== 3. PROCESS UPLOADED VIDEO ==========

  describe('processUploadedVideo', () => {
    it('should process an uploaded video successfully', async () => {
      const mockFile = {
        download: jest.fn().mockResolvedValue(undefined),
      };
      mockBucket.file.mockReturnValue(mockFile);
      mockBucket.upload.mockResolvedValue(undefined);

      // Mock ffmpeg for thumbnail generation
      mockFfmpeg.mockImplementation(() => mockFfmpegInstance);
      mockFfmpegInstance.on.mockImplementation(function (this: any, event: string, callback: any) {
        if (event === 'end') {
          callback();
        }
        return this;
      });

      // Mock ffprobe for metadata
      mockFfmpeg.ffprobe.mockImplementation((path: string, callback: any) => {
        callback(null, {
          format: { duration: 30 },
        });
      });

      const event = {
        bucket: 'test-bucket',
        data: {
          name: 'videos/test.mp4',
          contentType: 'video/mp4',
        },
      };

      // @ts-ignore
      await processUploadedVideo(event);

      expect(mockFile.download).toHaveBeenCalled();
      expect(mockFfmpeg).toHaveBeenCalled();
      expect(mockBucket.upload).toHaveBeenCalled();
    });

    it('should skip non-video files', async () => {
      const event = {
        bucket: 'test-bucket',
        data: {
          name: 'photos/test.jpg',
          contentType: 'image/jpeg',
        },
      };

      // @ts-ignore
      await processUploadedVideo(event);

      expect(mockBucket.file).not.toHaveBeenCalled();
    });

    it('should flag videos longer than 60 seconds for review', async () => {
      const mockFile = {
        download: jest.fn().mockResolvedValue(undefined),
      };
      mockBucket.file.mockReturnValue(mockFile);
      mockBucket.upload.mockResolvedValue(undefined);

      const mockModerationAdd = jest.fn().mockResolvedValue(undefined);
      mockDb.collection.mockReturnValue({
        add: mockModerationAdd,
      });

      mockFfmpeg.mockImplementation(() => mockFfmpegInstance);
      mockFfmpegInstance.on.mockImplementation(function (this: any, event: string, callback: any) {
        if (event === 'end') {
          callback();
        }
        return this;
      });

      // Video longer than 60 seconds
      mockFfmpeg.ffprobe.mockImplementation((path: string, callback: any) => {
        callback(null, {
          format: { duration: 75 },
        });
      });

      const event = {
        bucket: 'test-bucket',
        data: {
          name: 'videos/long.mp4',
          contentType: 'video/mp4',
        },
      };

      // @ts-ignore
      await processUploadedVideo(event);

      expect(mockModerationAdd).toHaveBeenCalledWith({
        type: 'video_too_long',
        filePath: 'videos/long.mp4',
        duration: 75,
        uploadedAt: 'SERVER_TIMESTAMP',
      });
    });
  });

  // ========== 4. GENERATE VIDEO THUMBNAIL ==========

  describe('generateVideoThumbnail', () => {
    beforeEach(() => {
      global.fetch = jest.fn().mockResolvedValue({
        arrayBuffer: jest.fn().mockResolvedValue(new ArrayBuffer(1024)),
      });

      // Mock fs
      const fs = require('fs');
      fs.writeFileSync = jest.fn();
      fs.readFileSync = jest.fn(() => Buffer.from('thumbnail-data'));
    });

    it('should generate a video thumbnail successfully', async () => {
      mockFfmpeg.mockImplementation(() => mockFfmpegInstance);
      mockFfmpegInstance.on.mockImplementation(function (this: any, event: string, callback: any) {
        if (event === 'end') {
          callback();
        }
        return this;
      });

      const mockFile = {
        save: jest.fn().mockResolvedValue(undefined),
        getSignedUrl: jest
          .fn()
          .mockResolvedValue(['https://storage.googleapis.com/thumbnail.jpg']),
      };
      mockBucket.file.mockReturnValue(mockFile);

      const request = {
        auth: { uid: 'user-123' },
        data: {
          videoUrl: 'https://example.com/video.mp4',
          timestampSeconds: 2,
        },
      };

      // @ts-ignore
      const result = await generateVideoThumbnail(request);

      expect(global.fetch).toHaveBeenCalledWith('https://example.com/video.mp4');
      expect(mockFfmpeg).toHaveBeenCalled();
      expect(mockFile.save).toHaveBeenCalled();
      expect(result.success).toBe(true);
      expect(result.thumbnailUrl).toBeDefined();
    });

    it('should reject if videoUrl is missing', async () => {
      const request = {
        auth: { uid: 'user-123' },
        data: {},
      };

      // @ts-ignore
      await expect(generateVideoThumbnail(request)).rejects.toThrow('videoUrl is required');
    });

    it('should use default timestamp if not provided', async () => {
      mockFfmpeg.mockImplementation(() => mockFfmpegInstance);
      mockFfmpegInstance.screenshots.mockReturnValue(mockFfmpegInstance);
      mockFfmpegInstance.on.mockImplementation(function (this: any, event: string, callback: any) {
        if (event === 'end') {
          callback();
        }
        return this;
      });

      const mockFile = {
        save: jest.fn().mockResolvedValue(undefined),
        getSignedUrl: jest
          .fn()
          .mockResolvedValue(['https://storage.googleapis.com/thumbnail.jpg']),
      };
      mockBucket.file.mockReturnValue(mockFile);

      const request = {
        auth: { uid: 'user-123' },
        data: {
          videoUrl: 'https://example.com/video.mp4',
        },
      };

      // @ts-ignore
      const result = await generateVideoThumbnail(request);

      expect(mockFfmpegInstance.screenshots).toHaveBeenCalledWith(
        expect.objectContaining({
          timestamps: [1], // Default timestamp
        })
      );
      expect(result.success).toBe(true);
    });
  });

  // ========== 5. TRANSCRIBE VOICE MESSAGE ==========

  describe('transcribeVoiceMessage', () => {
    it('should transcribe a voice message successfully', async () => {
      const mockFile = {
        getMetadata: jest.fn().mockResolvedValue([
          {
            metadata: {
              languageCode: 'en-US',
              messageId: 'msg-123',
            },
          },
        ]),
      };
      mockBucket.file.mockReturnValue(mockFile);

      const mockOperation = {
        promise: jest.fn().mockResolvedValue([
          {
            results: [
              {
                alternatives: [
                  {
                    transcript: 'Hello, this is a test message.',
                  },
                ],
              },
            ],
          },
        ]),
      };

      mockSpeechClient.longRunningRecognize.mockResolvedValue([mockOperation]);

      const mockMessageUpdate = jest.fn().mockResolvedValue(undefined);
      mockDb.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue({
          update: mockMessageUpdate,
        }),
      });

      const event = {
        bucket: 'test-bucket',
        data: {
          name: 'voice/message.wav',
          contentType: 'audio/wav',
        },
      };

      // @ts-ignore
      await transcribeVoiceMessage(event);

      expect(mockSpeechClient.longRunningRecognize).toHaveBeenCalledWith({
        config: {
          encoding: 'LINEAR16',
          sampleRateHertz: 16000,
          languageCode: 'en-US',
          enableAutomaticPunctuation: true,
        },
        audio: {
          uri: 'gs://test-bucket/voice/message.wav',
        },
      });

      expect(mockMessageUpdate).toHaveBeenCalledWith({
        transcription: 'Hello, this is a test message.',
        transcribedAt: 'SERVER_TIMESTAMP',
      });
    });

    it('should skip non-audio files', async () => {
      const event = {
        bucket: 'test-bucket',
        data: {
          name: 'photos/test.jpg',
          contentType: 'image/jpeg',
        },
      };

      // @ts-ignore
      await transcribeVoiceMessage(event);

      expect(mockSpeechClient.longRunningRecognize).not.toHaveBeenCalled();
    });

    it('should use default language if not in metadata', async () => {
      const mockFile = {
        getMetadata: jest.fn().mockResolvedValue([
          {
            metadata: {
              messageId: 'msg-123',
            },
          },
        ]),
      };
      mockBucket.file.mockReturnValue(mockFile);

      const mockOperation = {
        promise: jest.fn().mockResolvedValue([
          {
            results: [
              {
                alternatives: [{ transcript: 'Test' }],
              },
            ],
          },
        ]),
      };

      mockSpeechClient.longRunningRecognize.mockResolvedValue([mockOperation]);

      const mockMessageUpdate = jest.fn().mockResolvedValue(undefined);
      mockDb.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue({
          update: mockMessageUpdate,
        }),
      });

      const event = {
        bucket: 'test-bucket',
        data: {
          name: 'voice/message.wav',
          contentType: 'audio/wav',
        },
      };

      // @ts-ignore
      await transcribeVoiceMessage(event);

      expect(mockSpeechClient.longRunningRecognize).toHaveBeenCalledWith(
        expect.objectContaining({
          config: expect.objectContaining({
            languageCode: 'en-US', // Default
          }),
        })
      );
    });
  });

  // ========== 6. TRANSCRIBE AUDIO ==========

  describe('transcribeAudio', () => {
    beforeEach(() => {
      global.fetch = jest.fn().mockResolvedValue({
        arrayBuffer: jest.fn().mockResolvedValue(new ArrayBuffer(1024)),
      });
    });

    it('should transcribe audio successfully', async () => {
      mockSpeechClient.recognize.mockResolvedValue([
        {
          results: [
            {
              alternatives: [
                {
                  transcript: 'This is a test transcription.',
                  confidence: 0.95,
                },
              ],
            },
          ],
        },
      ]);

      const request = {
        auth: { uid: 'user-123' },
        data: {
          audioUrl: 'https://example.com/audio.wav',
          languageCode: 'en-US',
        },
      };

      // @ts-ignore
      const result = await transcribeAudio(request);

      expect(global.fetch).toHaveBeenCalledWith('https://example.com/audio.wav');
      expect(mockSpeechClient.recognize).toHaveBeenCalledWith({
        config: {
          encoding: 'LINEAR16',
          sampleRateHertz: 16000,
          languageCode: 'en-US',
          enableAutomaticPunctuation: true,
        },
        audio: {
          content: expect.any(String),
        },
      });

      expect(result.success).toBe(true);
      expect(result.transcription).toBe('This is a test transcription.');
      expect(result.confidence).toBe(0.95);
    });

    it('should reject if audioUrl is missing', async () => {
      const request = {
        auth: { uid: 'user-123' },
        data: {},
      };

      // @ts-ignore
      await expect(transcribeAudio(request)).rejects.toThrow('audioUrl is required');
    });

    it('should use default language code if not provided', async () => {
      mockSpeechClient.recognize.mockResolvedValue([
        {
          results: [
            {
              alternatives: [
                {
                  transcript: 'Test',
                  confidence: 0.9,
                },
              ],
            },
          ],
        },
      ]);

      const request = {
        auth: { uid: 'user-123' },
        data: {
          audioUrl: 'https://example.com/audio.wav',
        },
      };

      // @ts-ignore
      const result = await transcribeAudio(request);

      expect(mockSpeechClient.recognize).toHaveBeenCalledWith(
        expect.objectContaining({
          config: expect.objectContaining({
            languageCode: 'en-US', // Default
          }),
        })
      );
      expect(result.success).toBe(true);
    });
  });

  // ========== 7. BATCH TRANSCRIBE ==========

  describe('batchTranscribe', () => {
    beforeEach(() => {
      global.fetch = jest.fn().mockResolvedValue({
        arrayBuffer: jest.fn().mockResolvedValue(new ArrayBuffer(1024)),
      });
    });

    it('should batch transcribe multiple audio files successfully', async () => {
      mockSpeechClient.recognize.mockResolvedValue([
        {
          results: [
            {
              alternatives: [
                {
                  transcript: 'Transcription result.',
                  confidence: 0.92,
                },
              ],
            },
          ],
        },
      ]);

      const request = {
        auth: { uid: 'user-123' },
        data: {
          audioUrls: [
            'https://example.com/audio1.wav',
            'https://example.com/audio2.wav',
            'https://example.com/audio3.wav',
          ],
          languageCode: 'en-US',
        },
      };

      // @ts-ignore
      const result = await batchTranscribe(request);

      expect(global.fetch).toHaveBeenCalledTimes(3);
      expect(mockSpeechClient.recognize).toHaveBeenCalledTimes(3);
      expect(result.success).toBe(true);
      expect(result.transcriptions).toHaveLength(3);
      expect(result.totalProcessed).toBe(3);
      expect(result.transcriptions[0]).toEqual({
        audioUrl: 'https://example.com/audio1.wav',
        transcription: 'Transcription result.',
        confidence: 0.92,
      });
    });

    it('should reject if audioUrls is missing or empty', async () => {
      const request = {
        auth: { uid: 'user-123' },
        data: {},
      };

      // @ts-ignore
      await expect(batchTranscribe(request)).rejects.toThrow('audioUrls is required');

      const request2 = {
        auth: { uid: 'user-123' },
        data: { audioUrls: [] },
      };

      // @ts-ignore
      await expect(batchTranscribe(request2)).rejects.toThrow('audioUrls is required');
    });

    it('should handle mixed success and failure in batch', async () => {
      mockSpeechClient.recognize
        .mockResolvedValueOnce([
          {
            results: [
              {
                alternatives: [{ transcript: 'Success', confidence: 0.9 }],
              },
            ],
          },
        ])
        .mockResolvedValueOnce([
          {
            results: [
              {
                alternatives: [{ transcript: 'Success 2', confidence: 0.85 }],
              },
            ],
          },
        ]);

      const request = {
        auth: { uid: 'user-123' },
        data: {
          audioUrls: [
            'https://example.com/audio1.wav',
            'https://example.com/audio2.wav',
          ],
        },
      };

      // @ts-ignore
      const result = await batchTranscribe(request);

      expect(result.success).toBe(true);
      expect(result.totalProcessed).toBe(2);
    });
  });

  // ========== 8. CLEANUP DISAPPEARING MEDIA ==========

  describe('cleanupDisappearingMedia', () => {
    it('should cleanup disappearing media older than 24 hours', async () => {
      const mockSnapshot = {
        size: 3,
        forEach: jest.fn((callback) => {
          callback({
            ref: { id: 'msg-1' },
            data: () => ({ mediaUrl: 'https://example.com/file1.jpg' }),
          });
          callback({
            ref: { id: 'msg-2' },
            data: () => ({ mediaUrl: 'https://example.com/file2.jpg' }),
          });
          callback({
            ref: { id: 'msg-3' },
            data: () => ({ mediaUrl: 'https://example.com/file3.jpg' }),
          });
        }),
      };

      const mockQuery = {
        where: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue(mockSnapshot),
      };

      mockDb.collection.mockReturnValue(mockQuery);

      const mockBatch = {
        delete: jest.fn(),
        commit: jest.fn().mockResolvedValue(undefined),
      };
      (mockDb as any).batch = jest.fn(() => mockBatch);

      const mockFile = {
        delete: jest.fn().mockResolvedValue(undefined),
      };
      mockBucket.file.mockReturnValue(mockFile);

      // @ts-ignore
      await cleanupDisappearingMedia({});

      expect(mockQuery.where).toHaveBeenCalledWith('disappearing', '==', true);
      expect(mockQuery.where).toHaveBeenCalledWith('createdAt', '<', expect.any(Date));
      expect(mockBatch.delete).toHaveBeenCalledTimes(3);
      expect(mockFile.delete).toHaveBeenCalledTimes(3);
      expect(mockBatch.commit).toHaveBeenCalled();
    });

    it('should handle no disappearing media to cleanup', async () => {
      const mockSnapshot = {
        size: 0,
        forEach: jest.fn(),
      };

      const mockQuery = {
        where: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue(mockSnapshot),
      };

      mockDb.collection.mockReturnValue(mockQuery);

      const mockBatch = {
        delete: jest.fn(),
        commit: jest.fn().mockResolvedValue(undefined),
      };
      (mockDb as any).batch = jest.fn(() => mockBatch);

      // @ts-ignore
      await cleanupDisappearingMedia({});

      expect(mockBatch.delete).not.toHaveBeenCalled();
      expect(mockBatch.commit).toHaveBeenCalled();
    });

    it('should continue cleanup even if some file deletions fail', async () => {
      const mockSnapshot = {
        size: 2,
        forEach: jest.fn((callback) => {
          callback({
            ref: { id: 'msg-1' },
            data: () => ({ mediaUrl: 'https://example.com/file1.jpg' }),
          });
          callback({
            ref: { id: 'msg-2' },
            data: () => ({ mediaUrl: 'https://example.com/file2.jpg' }),
          });
        }),
      };

      const mockQuery = {
        where: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue(mockSnapshot),
      };

      mockDb.collection.mockReturnValue(mockQuery);

      const mockBatch = {
        delete: jest.fn(),
        commit: jest.fn().mockResolvedValue(undefined),
      };
      (mockDb as any).batch = jest.fn(() => mockBatch);

      const mockFile = {
        delete: jest
          .fn()
          .mockRejectedValueOnce(new Error('Delete failed'))
          .mockResolvedValueOnce(undefined),
      };
      mockBucket.file.mockReturnValue(mockFile);

      // @ts-ignore
      await cleanupDisappearingMedia({});

      expect(mockFile.delete).toHaveBeenCalledTimes(2);
      expect(mockBatch.commit).toHaveBeenCalled();
    });
  });

  // ========== 9. MARK MEDIA AS DISAPPEARING ==========

  describe('markMediaAsDisappearing', () => {
    it('should mark media as disappearing successfully', async () => {
      const mockUpdate = jest.fn().mockResolvedValue(undefined);
      const mockGet = jest.fn().mockResolvedValue({
        exists: true,
        data: () => ({ senderId: 'user-123', mediaUrl: 'https://example.com/file.jpg' }),
      });

      mockDb.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue({
          get: mockGet,
          update: mockUpdate,
        }),
      });

      const request = {
        auth: { uid: 'user-123' },
        data: {
          messageId: 'msg-123',
          disappearing: true,
        },
      };

      // @ts-ignore
      const result = await markMediaAsDisappearing(request);

      expect(mockUpdate).toHaveBeenCalledWith({
        disappearing: true,
        markedDisappearingAt: 'SERVER_TIMESTAMP',
      });
      expect(result.success).toBe(true);
      expect(result.message).toContain('disappearing');
    });

    it('should mark media as permanent successfully', async () => {
      const mockUpdate = jest.fn().mockResolvedValue(undefined);
      const mockGet = jest.fn().mockResolvedValue({
        exists: true,
        data: () => ({ senderId: 'user-123' }),
      });

      mockDb.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue({
          get: mockGet,
          update: mockUpdate,
        }),
      });

      const request = {
        auth: { uid: 'user-123' },
        data: {
          messageId: 'msg-123',
          disappearing: false,
        },
      };

      // @ts-ignore
      const result = await markMediaAsDisappearing(request);

      expect(mockUpdate).toHaveBeenCalledWith({
        disappearing: false,
        markedDisappearingAt: 'SERVER_TIMESTAMP',
      });
      expect(result.message).toContain('permanent');
    });

    it('should reject if messageId is missing', async () => {
      const request = {
        auth: { uid: 'user-123' },
        data: {},
      };

      // @ts-ignore
      await expect(markMediaAsDisappearing(request)).rejects.toThrow('messageId is required');
    });

    it('should reject if message not found', async () => {
      const mockGet = jest.fn().mockResolvedValue({
        exists: false,
      });

      mockDb.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue({
          get: mockGet,
        }),
      });

      const request = {
        auth: { uid: 'user-123' },
        data: {
          messageId: 'nonexistent',
          disappearing: true,
        },
      };

      // @ts-ignore
      await expect(markMediaAsDisappearing(request)).rejects.toThrow('Message not found');
    });

    it('should reject if user does not own the message', async () => {
      const mockGet = jest.fn().mockResolvedValue({
        exists: true,
        data: () => ({ senderId: 'other-user' }),
      });

      mockDb.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue({
          get: mockGet,
        }),
      });

      const request = {
        auth: { uid: 'user-123' },
        data: {
          messageId: 'msg-123',
          disappearing: true,
        },
      };

      // @ts-ignore
      await expect(markMediaAsDisappearing(request)).rejects.toThrow('Not authorized');
    });
  });

  // ========== INTEGRATION TESTS ==========

  describe('Integration Tests', () => {
    it('should handle complete image upload and compression workflow', async () => {
      // 1. Upload triggers compression
      const mockFile = {
        download: jest.fn().mockResolvedValue([Buffer.from('image-data')]),
      };
      const mockNewFile = {
        save: jest.fn().mockResolvedValue(undefined),
        makePublic: jest.fn().mockResolvedValue(['https://example.com/compressed.jpg']),
      };

      mockBucket.file.mockImplementation((path: string) => {
        if (path.includes('_compressed')) {
          return mockNewFile;
        }
        return mockFile;
      });

      const compressedBuffer = Buffer.alloc(1024 * 1024);
      mockSharp.toBuffer.mockResolvedValue(compressedBuffer);

      const event = {
        bucket: 'test-bucket',
        data: {
          name: 'photos/user123/profile.jpg',
          contentType: 'image/jpeg',
        },
      };

      // @ts-ignore
      await compressUploadedImage(event);

      expect(mockNewFile.save).toHaveBeenCalled();
      expect(mockNewFile.makePublic).toHaveBeenCalled();
    });

    it('should handle complete video upload workflow with thumbnail and validation', async () => {
      const mockFile = {
        download: jest.fn().mockResolvedValue(undefined),
      };
      mockBucket.file.mockReturnValue(mockFile);
      mockBucket.upload.mockResolvedValue(undefined);

      mockFfmpeg.mockImplementation(() => mockFfmpegInstance);
      mockFfmpegInstance.on.mockImplementation(function (this: any, event: string, callback: any) {
        if (event === 'end') {
          callback();
        }
        return this;
      });

      mockFfmpeg.ffprobe.mockImplementation((path: string, callback: any) => {
        callback(null, {
          format: { duration: 45 },
        });
      });

      const event = {
        bucket: 'test-bucket',
        data: {
          name: 'videos/intro.mp4',
          contentType: 'video/mp4',
        },
      };

      // @ts-ignore
      await processUploadedVideo(event);

      expect(mockFile.download).toHaveBeenCalled();
      expect(mockBucket.upload).toHaveBeenCalled();
    });

    it('should handle complete audio transcription workflow', async () => {
      // 1. Voice message upload triggers transcription
      const mockFile = {
        getMetadata: jest.fn().mockResolvedValue([
          {
            metadata: {
              languageCode: 'en-US',
              messageId: 'msg-123',
            },
          },
        ]),
      };
      mockBucket.file.mockReturnValue(mockFile);

      const mockOperation = {
        promise: jest.fn().mockResolvedValue([
          {
            results: [
              {
                alternatives: [{ transcript: 'Hello there!' }],
              },
            ],
          },
        ]),
      };

      mockSpeechClient.longRunningRecognize.mockResolvedValue([mockOperation]);

      const mockMessageUpdate = jest.fn().mockResolvedValue(undefined);
      mockDb.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue({
          update: mockMessageUpdate,
        }),
      });

      const event = {
        bucket: 'test-bucket',
        data: {
          name: 'voice/msg123.wav',
          contentType: 'audio/wav',
        },
      };

      // @ts-ignore
      await transcribeVoiceMessage(event);

      expect(mockMessageUpdate).toHaveBeenCalledWith({
        transcription: 'Hello there!',
        transcribedAt: 'SERVER_TIMESTAMP',
      });
    });

    it('should handle disappearing media lifecycle', async () => {
      // 1. Mark as disappearing
      const mockUpdate = jest.fn().mockResolvedValue(undefined);
      const mockGet = jest.fn().mockResolvedValue({
        exists: true,
        data: () => ({ senderId: 'user-123', mediaUrl: 'https://example.com/secret.jpg' }),
      });

      mockDb.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue({
          get: mockGet,
          update: mockUpdate,
        }),
      });

      const request = {
        auth: { uid: 'user-123' },
        data: {
          messageId: 'msg-secret',
          disappearing: true,
        },
      };

      // @ts-ignore
      await markMediaAsDisappearing(request);

      expect(mockUpdate).toHaveBeenCalledWith({
        disappearing: true,
        markedDisappearingAt: 'SERVER_TIMESTAMP',
      });

      // 2. Cleanup after 24 hours
      const mockSnapshot = {
        size: 1,
        forEach: jest.fn((callback) => {
          callback({
            ref: { id: 'msg-secret' },
            data: () => ({ mediaUrl: 'https://example.com/secret.jpg' }),
          });
        }),
      };

      const mockQuery = {
        where: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue(mockSnapshot),
      };

      mockDb.collection.mockReturnValue(mockQuery);

      const mockBatch = {
        delete: jest.fn(),
        commit: jest.fn().mockResolvedValue(undefined),
      };
      (mockDb as any).batch = jest.fn(() => mockBatch);

      const mockFileDelete = {
        delete: jest.fn().mockResolvedValue(undefined),
      };
      mockBucket.file.mockReturnValue(mockFileDelete);

      // @ts-ignore
      await cleanupDisappearingMedia({});

      expect(mockFileDelete.delete).toHaveBeenCalled();
      expect(mockBatch.commit).toHaveBeenCalled();
    });
  });

  // ========== EDGE CASES ==========

  describe('Edge Cases', () => {
    it('should handle image compression with very small images', async () => {
      const smallBuffer = Buffer.alloc(100); // 100 bytes
      mockSharp.toBuffer.mockResolvedValue(smallBuffer);

      const mockFile = {
        save: jest.fn().mockResolvedValue(undefined),
        getSignedUrl: jest.fn().mockResolvedValue(['https://example.com/small.jpg']),
      };
      mockBucket.file.mockReturnValue(mockFile);

      global.fetch = jest.fn().mockResolvedValue({
        arrayBuffer: jest.fn().mockResolvedValue(new ArrayBuffer(100)),
      });

      const request = {
        auth: { uid: 'user-123' },
        data: { imageUrl: 'https://example.com/small.jpg' },
      };

      // @ts-ignore
      const result = await compressImage(request);

      expect(result.success).toBe(true);
      expect(result.compressedSize).toBeLessThan(2 * 1024 * 1024);
    });

    it('should handle audio transcription with empty results', async () => {
      mockSpeechClient.recognize.mockResolvedValue([
        {
          results: [],
        },
      ]);

      global.fetch = jest.fn().mockResolvedValue({
        arrayBuffer: jest.fn().mockResolvedValue(new ArrayBuffer(1024)),
      });

      const request = {
        auth: { uid: 'user-123' },
        data: {
          audioUrl: 'https://example.com/silent.wav',
        },
      };

      // @ts-ignore
      const result = await transcribeAudio(request);

      expect(result.success).toBe(true);
      expect(result.transcription).toBeUndefined();
    });

    it('should handle video exactly at 60 second limit', async () => {
      const mockFile = {
        download: jest.fn().mockResolvedValue(undefined),
      };
      mockBucket.file.mockReturnValue(mockFile);
      mockBucket.upload.mockResolvedValue(undefined);

      mockFfmpeg.mockImplementation(() => mockFfmpegInstance);
      mockFfmpegInstance.on.mockImplementation(function (this: any, event: string, callback: any) {
        if (event === 'end') {
          callback();
        }
        return this;
      });

      mockFfmpeg.ffprobe.mockImplementation((path: string, callback: any) => {
        callback(null, {
          format: { duration: 60 }, // Exactly 60 seconds
        });
      });

      const mockModerationAdd = jest.fn();
      mockDb.collection.mockReturnValue({
        add: mockModerationAdd,
      });

      const event = {
        bucket: 'test-bucket',
        data: {
          name: 'videos/exact60.mp4',
          contentType: 'video/mp4',
        },
      };

      // @ts-ignore
      await processUploadedVideo(event);

      // Should not flag for review (60 seconds is within limit)
      expect(mockModerationAdd).not.toHaveBeenCalled();
    });
  });
});
