/**
 * Storage trigger for the My pictures library (logic: mediaLibrary.ts).
 * Kept in its own module so the pure library helpers (imported by the face
 * rule, the moderation pipeline and appeals) do not define a Storage trigger
 * - and resolve the Firebase config - wherever they are loaded.
 */
import { onObjectDeleted } from 'firebase-functions/v2/storage';
import '../shared/firebaseAdmin';
import { logError } from '../shared/utils';
import { handleLibraryObjectDeleted } from './mediaLibrary';

/** Keeps the library free of dead URLs (see handleLibraryObjectDeleted). */
export const onMediaObjectDeleted = onObjectDeleted(
  { memory: '512MiB', timeoutSeconds: 60 },
  async (event) => {
    const objectPath = event.data.name || '';
    if (!/^(profiles|communities|chat_images|group_media)\//.test(objectPath)) return;
    try {
      await handleLibraryObjectDeleted({
        objectPath,
        generation: event.data.generation,
        meta: (event.data.metadata || {}) as Record<string, string>,
      });
    } catch (e) {
      logError(`[mediaLibrary] delete sync failed for ${objectPath}`, e);
    }
  },
);
