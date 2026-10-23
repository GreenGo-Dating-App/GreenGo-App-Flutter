/**
 * Provider API keys in Secret Manager (owner decision 2026-10-23: keys are
 * stored ONLY in Secret Manager, never in Firestore, code, .env or logs).
 *
 *   secret  AI_KEY_<PROVIDER_ID upper>   e.g. AI_KEY_QWEN_FLASH
 *
 * The admin panel saves a key through `adminAi` (superAdmin + fresh 2FA),
 * which adds a NEW secret version and disables the older ones. Functions read
 * the `latest` version at call time, cached 60 s per instance, so a new key
 * works within a minute and without a redeploy.
 *
 * One-time IAM (see docs/ai-providers/SETUP.md): the functions' runtime
 * service account needs, on secrets named AI_KEY_*:
 *   roles/secretmanager.secretAccessor   (read)
 *   roles/secretmanager.admin            (create secret, add/disable versions)
 * granted with an IAM condition on the AI_KEY_ prefix.
 */
import { SecretManagerServiceClient } from '@google-cloud/secret-manager';

const TTL_MS = 60_000;
const cache = new Map<string, { at: number; value: string | null }>();
let client: SecretManagerServiceClient | null = null;

export interface SecretStore {
  read(name: string): Promise<string | null>;
  write(name: string, value: string): Promise<void>;
  remove(name: string): Promise<void>;
}

const projectId = () =>
  process.env.GCLOUD_PROJECT || process.env.GCP_PROJECT ||
  (process.env.FIREBASE_CONFIG ? JSON.parse(process.env.FIREBASE_CONFIG).projectId : '');

const sm = () => (client ??= new SecretManagerServiceClient());

export function secretNameFor(keyName: string): string {
  return `AI_KEY_${keyName.toUpperCase()}`;
}

const gcpStore: SecretStore = {
  async read(name) {
    try {
      const [v] = await sm().accessSecretVersion({
        name: `projects/${projectId()}/secrets/${name}/versions/latest`,
      });
      const data = v.payload?.data;
      const s = data ? Buffer.from(data as Uint8Array).toString('utf8').trim() : '';
      return s || null;
    } catch (e: any) {
      // NOT_FOUND (5) = no key saved yet; anything else is logged without detail.
      if (e?.code !== 5) console.warn(`secrets: read ${name} failed (${e?.code ?? 'error'})`);
      return null;
    }
  },
  async write(name, value) {
    const parent = `projects/${projectId()}`;
    const secret = `${parent}/secrets/${name}`;
    try {
      await sm().getSecret({ name: secret });
    } catch (e: any) {
      if (e?.code !== 5) throw e;
      await sm().createSecret({
        parent,
        secretId: name,
        secret: { replication: { automatic: {} }, labels: { owner: 'ai-router' } },
      });
    }
    const [added] = await sm().addSecretVersion({
      parent: secret,
      payload: { data: Buffer.from(value, 'utf8') },
    });
    // Only one live key per provider: disable every older enabled version.
    const [versions] = await sm().listSecretVersions({ parent: secret, filter: 'state:ENABLED' });
    await Promise.all(versions
      .filter((v) => v.name && v.name !== added.name)
      .map((v) => sm().disableSecretVersion({ name: v.name! }).catch(() => undefined)));
  },
  async remove(name) {
    try {
      await sm().deleteSecret({ name: `projects/${projectId()}/secrets/${name}` });
    } catch (e: any) {
      if (e?.code !== 5) throw e;
    }
  },
};

let store: SecretStore = gcpStore;
/** Test hook. */
export function _setSecretStore(s: SecretStore | null) {
  store = s ?? gcpStore;
  cache.clear();
}

/** The provider's key, or null when none was saved. */
export async function readProviderKey(keyName: string): Promise<string | null> {
  const name = secretNameFor(keyName);
  const hit = cache.get(name);
  if (hit && Date.now() - hit.at < TTL_MS) return hit.value;
  const value = await store.read(name);
  cache.set(name, { at: Date.now(), value });
  return value;
}

export async function writeProviderKey(keyName: string, value: string): Promise<void> {
  const name = secretNameFor(keyName);
  await store.write(name, value);
  cache.set(name, { at: Date.now(), value });
}

export async function removeProviderKey(keyName: string): Promise<void> {
  const name = secretNameFor(keyName);
  await store.remove(name);
  cache.delete(name);
}
