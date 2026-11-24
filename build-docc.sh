#!/bin/sh
set -eu

cd "$(dirname "$0")"
graphs="$PWD/.derivedData/CacheKit-symbols"
mkdir -p "$graphs"
swift build --target CacheKit \
    -Xswiftc -emit-symbol-graph \
    -Xswiftc -emit-symbol-graph-dir -Xswiftc "$graphs"

xcrun docc convert apple/Sources/CacheKit/CacheKit.docc \
    --additional-symbol-graph-dir "$graphs" \
    --fallback-display-name CacheKit \
    --fallback-bundle-identifier CacheKit \
    --output-path .docs \
    --transform-for-static-hosting \
    --hosting-base-path CacheKit

echo '<script>window.location.href += "/documentation/cachekit"</script>' > .docs/index.html
