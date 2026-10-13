import fs from 'fs';
import path from 'path';
import crypto from 'crypto';
import { AppError } from '../errors/AppError.js';

export interface UploadedFileInput {
  buffer: Buffer;
  mimetype: string;
  originalname: string;
  size: number;
}

export interface StoragePutResult {
  key: string;
  sizeBytes: number;
  mimeType: string;
}

export interface StorageService {
  put(file: UploadedFileInput): Promise<StoragePutResult>;
  getStream(key: string): fs.ReadStream;
  delete(key: string): Promise<void>;
  exists(key: string): Promise<boolean>;
}

// Security constants per ARCHITECTURE.md Section 6
const MAX_FILE_SIZE_BYTES = 25 * 1024 * 1024; // 25 MB max

const MIME_EXTENSION_MAP: Record<string, string> = {
  'application/pdf': '.pdf',
  'application/msword': '.doc',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document': '.docx',
  'image/jpeg': '.jpg',
  'image/png': '.png',
  'image/webp': '.webp',
};

const SAFE_KEY_REGEX = /^[a-zA-Z0-9_\-]+\.[a-zA-Z0-9]+$/;

export class LocalStorageService implements StorageService {
  private baseDir: string;
  private maxSizeBytes: number;
  private allowedMimeTypes: Record<string, string>;

  constructor(
    customDir?: string,
    maxSizeBytes?: number,
    allowedMimeTypes?: Record<string, string>
  ) {
    this.baseDir = customDir || path.resolve(process.cwd(), 'uploads', 'materials');
    this.maxSizeBytes = maxSizeBytes || MAX_FILE_SIZE_BYTES;
    this.allowedMimeTypes = allowedMimeTypes || MIME_EXTENSION_MAP;
    if (!fs.existsSync(this.baseDir)) {
      fs.mkdirSync(this.baseDir, { recursive: true });
    }
  }

  async put(file: UploadedFileInput): Promise<StoragePutResult> {
    // 1. File size check
    if (file.size > this.maxSizeBytes) {
      throw new AppError(
        'FILE_TOO_LARGE',
        `File size exceeds maximum allowed limit of ${Math.round(this.maxSizeBytes / (1024 * 1024))}MB`,
        400
      );
    }

    // 2. MIME type allowlist check
    const extension = this.allowedMimeTypes[file.mimetype.toLowerCase()];
    if (!extension) {
      throw new AppError(
        'INVALID_FILE_TYPE',
        `Unsupported file type '${file.mimetype}'. Allowed types: ${Object.keys(this.allowedMimeTypes).join(', ')}`,
        400
      );
    }

    // 3. Security: Generate random UUID key, never use user-supplied filename in disk path
    const randomKey = `${crypto.randomUUID()}${extension}`;
    const destinationPath = path.join(this.baseDir, randomKey);

    await fs.promises.writeFile(destinationPath, file.buffer);

    return {
      key: randomKey,
      sizeBytes: file.size,
      mimeType: file.mimetype,
    };
  }

  getStream(key: string): fs.ReadStream {
    // Security check against directory traversal
    if (!SAFE_KEY_REGEX.test(key) || key.includes('..') || key.includes('/') || key.includes('\\')) {
      throw new AppError('BAD_REQUEST', 'Invalid file storage key', 400);
    }

    const filePath = path.join(this.baseDir, key);
    if (!fs.existsSync(filePath)) {
      throw new AppError('NOT_FOUND', 'Requested file not found on storage', 404);
    }

    return fs.createReadStream(filePath);
  }

  async delete(key: string): Promise<void> {
    if (!SAFE_KEY_REGEX.test(key) || key.includes('..')) {
      return;
    }
    const filePath = path.join(this.baseDir, key);
    if (fs.existsSync(filePath)) {
      try {
        await fs.promises.unlink(filePath);
      } catch (_) {}
    }
  }

  async exists(key: string): Promise<boolean> {
    if (!SAFE_KEY_REGEX.test(key) || key.includes('..')) {
      return false;
    }
    const filePath = path.join(this.baseDir, key);
    return fs.existsSync(filePath);
  }
}

// Singleton storage instance
let storageInstance: StorageService = new LocalStorageService();

export function getStorageService(): StorageService {
  return storageInstance;
}

export function setStorageService(service: StorageService): void {
  storageInstance = service;
}

export const avatarStorageService = new LocalStorageService(
  path.resolve(process.cwd(), 'uploads', 'avatars'),
  5 * 1024 * 1024, // 5MB max for profile photos
  {
    'image/jpeg': '.jpg',
    'image/png': '.png',
    'image/webp': '.webp',
  }
);
