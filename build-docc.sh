##!/bin/sh

xcrun xcodebuild docbuild \
    -scheme CacheKit \
    -destination 'generic/platform=iOS Simulator' \
    -derivedDataPath "$PWD/.derivedData"

xcrun docc process-archive transform-for-static-hosting \
    "$PWD/.derivedData/Build/Products/Debug-iphonesimulator/CacheKit.doccarchive" \
    --output-path ".docs" \
    --hosting-base-path "cachekit"

echo '<script>window.location.href += "/documentation/givenwithlove"</script>' > .docs/index.html
