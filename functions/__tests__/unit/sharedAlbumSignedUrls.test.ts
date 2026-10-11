/**
 * getSharedAlbum short-lived URLs: which album URLs may be signed, and the
 * fall-back to the stored URL when signing is not configured.
 */
import { ALBUM_URL_TTL_MS, albumObjectPath, signAlbumUrls } from '../../src/profiles/privateProfileTriggers';

const B = 'greengo-chat.appspot.com';
const dl = (path: string, bucket = B) =>
  `https://firebasestorage.googleapis.com/v0/b/${bucket}/o/${encodeURIComponent(path)}?alt=media&token=abc`;

describe('albumObjectPath', () => {
  it('accepts a download URL in the owner folder', () => {
    expect(albumObjectPath(dl('profiles/owner/photos/1.jpg'), 'owner', B)).toBe('profiles/owner/photos/1.jpg');
  });
  it('refuses other folders, other users, other buckets and junk', () => {
    expect(albumObjectPath(dl('verifications/owner/selfie.jpg'), 'owner', B)).toBeNull();
    expect(albumObjectPath(dl('profiles/victim/photos/1.jpg'), 'owner', B)).toBeNull();
    expect(albumObjectPath(dl('profiles/owner2/photos/1.jpg'), 'owner', B)).toBeNull();
    expect(albumObjectPath(dl('profiles/owner/../victim/x.jpg'), 'owner', B)).toBeNull();
    expect(albumObjectPath(dl('profiles/owner/photos/1.jpg', 'other-bucket'), 'owner', B)).toBeNull();
    expect(albumObjectPath('https://example.com/v0/b/x/o/profiles%2Fowner%2Fa.jpg', 'owner', B)).toBeNull();
    expect(albumObjectPath('not a url', 'owner', B)).toBeNull();
    expect(albumObjectPath(42, 'owner', B)).toBeNull();
  });
});

describe('signAlbumUrls', () => {
  const now = Date.UTC(2026, 9, 9);

  it('signs owner-folder photos for ALBUM_URL_TTL_MS and leaves the rest untouched', async () => {
    const calls: Array<[string, number]> = [];
    const out = await signAlbumUrls(
      [dl('profiles/owner/photos/1.jpg'), 'https://cdn.example.com/x.jpg', dl('verifications/owner/s.jpg')],
      'owner',
      { bucket: B, now, sign: async (p, exp) => { calls.push([p, exp]); return `https://signed/${p}`; } },
    );
    expect(out).toEqual([
      'https://signed/profiles/owner/photos/1.jpg',
      'https://cdn.example.com/x.jpg',
      dl('verifications/owner/s.jpg'),
    ]);
    expect(calls).toEqual([['profiles/owner/photos/1.jpg', now + ALBUM_URL_TTL_MS]]);
    expect(ALBUM_URL_TTL_MS).toBe(10 * 60 * 1000);
  });

  it('falls back to the stored URL when signing fails (no signBlob permission)', async () => {
    const url = dl('profiles/owner/photos/1.jpg');
    const warn = jest.spyOn(console, 'warn').mockImplementation(() => undefined);
    const out = await signAlbumUrls([url, url], 'owner', {
      bucket: B,
      sign: async () => { throw new Error('iam.serviceAccounts.signBlob denied'); },
    });
    expect(out).toEqual([url, url]);
    expect(warn).toHaveBeenCalledTimes(1);
    warn.mockRestore();
  });

  it('is a no-op without a bucket or signer', async () => {
    const url = dl('profiles/owner/photos/1.jpg');
    await expect(signAlbumUrls([url], 'owner', { bucket: null })).resolves.toEqual([url]);
  });
});
