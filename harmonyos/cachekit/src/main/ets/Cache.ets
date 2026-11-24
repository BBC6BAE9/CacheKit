import { fileIo as fs } from '@kit.CoreFileKit';
import { buffer, util } from '@kit.ArkTS';

// Seconds between the Unix epoch and Foundation's reference date.
const FOUNDATION_EPOCH_SECONDS: number = 978307200;

export interface CacheCodec<V> {
  encode(value: V): Object;
  decode(value: Object): V;
}

class Entry<V> {
  key: string;
  value: V;
  expiredTimestamp: number;

  constructor(key: string, value: V, expires: number) {
    this.key = key;
    this.value = value;
    this.expiredTimestamp = expires;
  }
}

export class InMemoryCache<V> {
  readonly expirationInterval: number;
  protected entries: Map<string, Entry<V>> = new Map<string, Entry<V>>();
  private clock: () => number;

  constructor(expirationInterval: number, nowMillis: () => number = () => Date.now()) {
    this.expirationInterval = expirationInterval;
    this.clock = nowMillis;
  }

  protected now(): number {
    return this.clock() / 1000 - FOUNDATION_EPOCH_SECONDS;
  }

  setValue(value: V | null, key: string): void {
    if (value === null) {
      this.removeValue(key);
      return;
    }
    this.entries.set(key, new Entry<V>(key, value, this.now() + this.expirationInterval));
  }

  value(key: string): V | null {
    const entry = this.entries.get(key);
    if (entry === undefined) return null;
    if (this.now() <= entry.expiredTimestamp) return entry.value;
    this.removeValue(key);
    return null;
  }

  removeValue(key: string): void { this.entries.delete(key); }
  removeAllValues(): void { this.entries.clear(); }
}

export class DiskCache<V> extends InMemoryCache<V> {
  private path: string;
  private codec: CacheCodec<V>;

  constructor(directory: string, filename: string, expirationInterval: number, codec: CacheCodec<V>) {
    super(expirationInterval);
    if (filename.trim().length === 0 || filename.includes('/') || filename.includes('\u0000')) {
      throw new Error('Expected a cache filename');
    }
    this.path = directory + '/' + filename + '.cache';
    this.codec = codec;
  }

  saveToDisk(): void {
    const snapshot: Entry<Object>[] = [];
    const cutoff = this.now();
    this.entries.forEach((entry: Entry<V>, key: string) => {
      if (cutoff > entry.expiredTimestamp) {
        this.entries.delete(key);
      } else {
        snapshot.push(new Entry<Object>(key, this.codec.encode(entry.value), entry.expiredTimestamp));
      }
    });
    const text = JSON.stringify(snapshot);
    const temporary = this.path + '.' + util.generateRandomUUID() + '.tmp';
    const file = fs.openSync(temporary, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY);
    try {
      try {
        if (fs.writeSync(file.fd, text) !== buffer.byteLength(text, 'utf8')) {
          throw new Error('Incomplete cache file write');
        }
      } finally {
        fs.closeSync(file);
      }
      fs.renameSync(temporary, this.path);
    } catch (error) {
      fs.unlinkSync(temporary);
      throw error as Error;
    }
  }

  loadFromDisk(): void {
    const records = JSON.parse(fs.readTextSync(this.path)) as Entry<Object>[];
    if (!Array.isArray(records)) throw new Error('Expected a cache entry array');
    const decoded: Entry<V>[] = [];
    records.forEach((record: Entry<Object>) => {
      if (!record || typeof record.key !== 'string' || typeof record.expiredTimestamp !== 'number'
        || !Number.isFinite(record.expiredTimestamp) || record.value === undefined || record.value === null) {
        throw new Error('Invalid cache entry');
      }
      decoded.push(new Entry<V>(record.key, this.codec.decode(record.value), record.expiredTimestamp));
    });
    decoded.forEach((entry: Entry<V>) => { this.entries.set(entry.key, entry); });
  }
}
