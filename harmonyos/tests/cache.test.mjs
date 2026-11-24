// Host contract tests. Run with Node 24+. Native kit calls use a filesystem adapter.
import assert from 'node:assert/strict';
import * as fs from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { stripTypeScriptTypes } from 'node:module';
import { test } from 'node:test';

const source = fs.readFileSync(new URL('../cachekit/src/main/ets/Cache.ets', import.meta.url), 'utf8');
const adapter = `
import * as native from 'node:fs';
import { randomUUID } from 'node:crypto';
const util = { generateRandomUUID: randomUUID };
const buffer = Buffer;
const fs = {
  OpenMode: { CREATE: native.constants.O_CREAT, WRITE_ONLY: native.constants.O_WRONLY },
  openSync: (path, flags) => ({ fd: native.openSync(path, flags) }),
  closeSync: file => native.closeSync(file.fd),
  writeSync: native.writeSync,
  readTextSync: path => native.readFileSync(path, 'utf8'),
  renameSync: native.renameSync,
  unlinkSync: native.unlinkSync
};
`;
const code = stripTypeScriptTypes(source.replace(/^import .* from '@kit\.[^']+';$/gm, ''));
const { DiskCache, InMemoryCache } = await import('data:text/javascript;base64,' +
  Buffer.from(adapter + code).toString('base64'));
const codec = {
  encode: value => value,
  decode: raw => { assert.equal(typeof raw, 'string'); return raw; }
};
function fixture(t) {
  const dir = fs.mkdtempSync(join(tmpdir(), 'cachekit-'));
  t.after(() => fs.rmSync(dir, { recursive: true, force: true }));
  return { dir, path: join(dir, 'threads.cache'), cache: (ttl = 600) => new DiskCache(dir, 'threads', ttl, codec) };
}

test('expiration uses a strict boundary and reads do not renew it', () => {
  let clock = 0;
  const cache = new InMemoryCache(1, () => clock);
  cache.setValue('first', 'key');
  clock = 1000;
  assert.equal(cache.value('key'), 'first');
  clock++;
  assert.equal(cache.value('key'), null);
});

test('explicit save, load, merge, replacement and removal', t => {
  const f = fixture(t), writer = f.cache(), reader = f.cache();
  assert.throws(() => reader.loadFromDisk());
  writer.setValue('旧消息🌙', 'key');
  writer.saveToDisk();
  writer.setValue('new', 'key');
  reader.setValue('local', 'other');
  reader.loadFromDisk();
  assert.equal(reader.value('key'), '旧消息🌙');
  assert.equal(reader.value('other'), 'local');
  writer.saveToDisk();
  reader.loadFromDisk();
  assert.equal(reader.value('key'), 'new');
  writer.setValue(null, 'key');
  writer.saveToDisk();
  reader.removeAllValues();
  reader.loadFromDisk();
  assert.equal(reader.value('key'), null);
});

test('expired entries are omitted from disk', t => {
  const f = fixture(t), cache = f.cache(-1);
  cache.setValue('gone', 'key');
  cache.saveToDisk();
  assert.deepEqual(JSON.parse(fs.readFileSync(f.path)), []);
});

test('decodes Foundation timestamps and rejects a partial restore', t => {
  const f = fixture(t), cache = f.cache();
  const entry = { key: 'one', value: 'fixture', expiredTimestamp: 8000000000 };
  fs.writeFileSync(f.path, JSON.stringify([entry]));
  cache.loadFromDisk();
  assert.equal(cache.value('one'), 'fixture');
  fs.writeFileSync(f.path, JSON.stringify([{ ...entry, value: 'bad' }, {}]));
  assert.throws(() => cache.loadFromDisk());
  assert.equal(cache.value('one'), 'fixture');
});

test('a serialization failure preserves the previous saved snapshot', t => {
  const f = fixture(t), cache = f.cache();
  cache.setValue('previous', 'key');
  cache.saveToDisk();
  const broken = new DiskCache(f.dir, 'threads', 600, {
    encode() { throw new Error('cannot encode'); }, decode: codec.decode
  });
  broken.setValue('next', 'key');
  assert.throws(() => broken.saveToDisk());
  const restored = f.cache();
  restored.loadFromDisk();
  assert.equal(restored.value('key'), 'previous');
});
