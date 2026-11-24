# CacheKit for HarmonyOS

Native ArkTS HAR for HarmonyOS 5.0.0 (API 12) and later. Open this directory in
DevEco Studio and build the cachekit module with the HarmonyOS 6.1.1 SDK.
From this directory, with the DevEco tools on PATH, run:

```sh
hvigorw --mode module -p module=cachekit@default assembleHar
```

Copy `cachekit/build/default/outputs/default/cachekit.har` into your app module's
`libs/` directory and add `"@bbc6bae9/cachekit": "file:./libs/cachekit.har"`
to that module's oh-package.json5 dependencies. Run `ohpm install`.

```typescript
import { CacheCodec, DiskCache, InMemoryCache } from '@bbc6bae9/cachekit';

class StringCodec implements CacheCodec<string> {
  encode(value: string): Object { return value; }
  decode(raw: Object): string {
    if (typeof raw !== 'string') throw new Error('Expected a string');
    return raw as string;
  }
}

const memory = new InMemoryCache<string>(60);
memory.setValue('ready', 'status');
const status = memory.value('status');

// Pass the calling application's context.cacheDir.
const disk = new DiskCache<string>(context.cacheDir, 'channels', 3600, new StringCodec());
disk.setValue('news', 'last');
disk.saveToDisk();
```

Disk calls are synchronous. Own the cache on a worker when file IO could block
the UI, and use one writer per file. Saving replaces the snapshot via a temporary
file in the same directory. Loading merges by key after the entire file decodes.
Missing files, invalid records and IO failures throw. Cache files may be reclaimed
by the OS. Expiry intervals are seconds. Reads preserve the original expiry.
The JSON envelope uses Swift CacheKit's reference date and matches the Android
module when all platforms use matching value encodings.

Run host contract tests with `node --test tests/cache.test.mjs` (Node 24+).
These exercise the ArkTS implementation with a Node filesystem adapter.
