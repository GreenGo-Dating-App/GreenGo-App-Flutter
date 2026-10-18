/**
 * Encryption of the confirmed ID-document details (identity_records/{uid}).
 *
 * AES-256-GCM, a fresh random 96-bit IV per record, the uid bound as
 * additional authenticated data (a record copied to another uid does not
 * decrypt). The key comes from the Secret Manager secret ID_DATA_KEY:
 *
 *   ID_DATA_KEY = "<base64 32-byte key>"                     -> version "v1"
 *   ID_DATA_KEY = "v3:<base64 key>,v2:<base64 key>,..."       -> keyring
 *
 * In a keyring the FIRST entry encrypts new records; every entry decrypts.
 * Rotation = prepend a new version and keep the old ones until a re-encrypt
 * pass has rewritten every record (each record stores `keyVersion`).
 *
 * Pure module: no Firestore, no logging of plaintext.
 */
import * as crypto from 'crypto';

export const IDENTITY_ALG = 'AES-256-GCM';

/** The fields a reviewer confirms. All optional except what the UI requires. */
export interface IdentityFields {
  firstName: string;
  surname: string;
  dateOfBirth: string; // YYYY-MM-DD
  docType: string; // passport | id_card | driving_licence | residence_permit | other
  issuingCountry: string; // ISO 3166-1 alpha-2
  docNumber: string;
}

export const DOC_TYPES = ['passport', 'id_card', 'driving_licence', 'residence_permit', 'other'] as const;

export interface EncryptedBlob {
  alg: typeof IDENTITY_ALG;
  keyVersion: string;
  iv: string; // base64
  tag: string; // base64
  ciphertext: string; // base64
}

export interface Keyring {
  current: string;
  keys: Map<string, Buffer>;
}

/** Parses the ID_DATA_KEY secret value. Throws on a malformed key. */
export function parseKeyring(raw: string | undefined | null): Keyring {
  const value = (raw ?? '').trim();
  if (!value) throw new Error('ID_DATA_KEY is not configured');
  const keys = new Map<string, Buffer>();
  let current = '';
  const parts = value.includes(':') ? value.split(',') : [`v1:${value}`];
  for (const part of parts) {
    const idx = part.indexOf(':');
    const version = part.slice(0, idx).trim();
    const key = Buffer.from(part.slice(idx + 1).trim(), 'base64');
    if (!/^[A-Za-z0-9_-]{1,32}$/.test(version) || key.length !== 32) {
      throw new Error('ID_DATA_KEY is malformed (need base64 32-byte keys)');
    }
    if (!current) current = version;
    keys.set(version, key);
  }
  return { current, keys };
}

/** Normalizes and validates reviewer/user-entered fields. Throws a message code. */
export function normalizeIdentityFields(input: unknown): IdentityFields {
  const o = (input && typeof input === 'object' ? input : {}) as Record<string, unknown>;
  const str = (k: string, max: number): string => {
    const v = typeof o[k] === 'string' ? (o[k] as string).trim().replace(/\s+/g, ' ') : '';
    if (v.length > max) throw new Error(`invalid_${k}`);
    return v;
  };
  const f: IdentityFields = {
    firstName: str('firstName', 100),
    surname: str('surname', 100),
    dateOfBirth: str('dateOfBirth', 10),
    docType: str('docType', 32).toLowerCase(),
    issuingCountry: str('issuingCountry', 2).toUpperCase(),
    docNumber: str('docNumber', 40).toUpperCase(),
  };
  if (!f.firstName) throw new Error('invalid_firstName');
  if (!f.surname) throw new Error('invalid_surname');
  if (!/^\d{4}-\d{2}-\d{2}$/.test(f.dateOfBirth) || isNaN(Date.parse(`${f.dateOfBirth}T00:00:00Z`))) {
    throw new Error('invalid_dateOfBirth');
  }
  if (!(DOC_TYPES as readonly string[]).includes(f.docType)) throw new Error('invalid_docType');
  if (!/^[A-Z]{2}$/.test(f.issuingCountry)) throw new Error('invalid_issuingCountry');
  if (!/^[A-Z0-9<\- ]{3,40}$/.test(f.docNumber)) throw new Error('invalid_docNumber');
  return f;
}

export function encryptIdentity(fields: IdentityFields, uid: string, ring: Keyring): EncryptedBlob {
  const key = ring.keys.get(ring.current);
  if (!key) throw new Error('ID_DATA_KEY current version missing');
  const iv = crypto.randomBytes(12);
  const cipher = crypto.createCipheriv('aes-256-gcm', key, iv);
  cipher.setAAD(Buffer.from(`identity_records/${uid}`, 'utf8'));
  const ciphertext = Buffer.concat([cipher.update(JSON.stringify(fields), 'utf8'), cipher.final()]);
  return {
    alg: IDENTITY_ALG,
    keyVersion: ring.current,
    iv: iv.toString('base64'),
    tag: cipher.getAuthTag().toString('base64'),
    ciphertext: ciphertext.toString('base64'),
  };
}

export function decryptIdentity(blob: EncryptedBlob, uid: string, ring: Keyring): IdentityFields {
  if (!blob || blob.alg !== IDENTITY_ALG) throw new Error('unsupported_record');
  const key = ring.keys.get(blob.keyVersion);
  if (!key) throw new Error(`key_version_unavailable:${blob.keyVersion}`);
  const decipher = crypto.createDecipheriv('aes-256-gcm', key, Buffer.from(blob.iv, 'base64'));
  decipher.setAAD(Buffer.from(`identity_records/${uid}`, 'utf8'));
  decipher.setAuthTag(Buffer.from(blob.tag, 'base64'));
  const plain = Buffer.concat([
    decipher.update(Buffer.from(blob.ciphertext, 'base64')),
    decipher.final(),
  ]).toString('utf8');
  return JSON.parse(plain) as IdentityFields;
}
