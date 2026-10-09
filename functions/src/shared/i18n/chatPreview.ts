/**
 * Media-message labels for chat pushes / previews ("📷 Photo", "🎤 Voice
 * message"), localized with the same ARB keys the app's chatMessageTypeLabel
 * uses, so push and in-app preview read the same.
 */
import { ArbKey } from './catalog.generated';
import { t } from './index';

const MEDIA: Record<string, { emoji: string; key: ArbKey | null }> = {
  image: { emoji: '📷', key: 'chatPhoto' },
  video: { emoji: '🎥', key: 'chatVideo' },
  gif: { emoji: '', key: null }, // "GIF" is a format name, same everywhere
  sticker: { emoji: '✨', key: 'chatPreviewSticker' },
  voice: { emoji: '🎤', key: 'chatPreviewVoiceMessage' },
  voice_note: { emoji: '🎤', key: 'chatPreviewVoiceMessage' },
  voiceNote: { emoji: '🎤', key: 'chatPreviewVoiceMessage' },
  location: { emoji: '📍', key: 'chatLocation' },
  event: { emoji: '📅', key: 'chatPreviewEvent' },
};

/** True for message types whose preview is a label, not the content. */
export function isMediaType(type: string): boolean {
  return Object.prototype.hasOwnProperty.call(MEDIA, type);
}

/** Localized label for a media message type, or null for text/unknown types. */
export function mediaLabel(locale: unknown, type: string): string | null {
  const m = MEDIA[type];
  if (!m) return null;
  if (!m.key) return 'GIF';
  return `${m.emoji} ${t(locale, m.key)}`;
}

/** Truncate user text for a preview line. */
export function truncatePreview(text: string, max = 120): string {
  const clean = (text || '').trim();
  return clean.length > max ? `${clean.substring(0, max - 3)}...` : clean;
}
