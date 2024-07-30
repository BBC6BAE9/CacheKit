# Cache

Cache is a lightweight disk caching tool commonly used to store data returned from network requests.

# Quick Start

1、Init cache

```Swift
import Cache

let cache = DiskCache<[xxx]>(filename:"iptv_channels", expirationInterval: 30 * 24 * 60 * 60)
```

2、Write cache to disk

```swift
cache.setValue(channels, forKey: keyString)
try? await cache.saveToDisk()

```

3、Load cache from disk

```Swift
cache.loadFromDisk()
```

4、Remove cache from disk

```swift
cache.removeValue(forKey: keyString)
```

# Apps
<a href="https://apps.apple.com/hk/app/%E8%85%BE%E8%AE%AF%E8%A7%86%E9%A2%91-%E5%B7%B4%E9%BB%8E%E5%A5%A5%E8%BF%90%E5%85%A8%E7%A8%8B%E7%9B%B4%E5%87%BB/id458318329?itscg=30200&amp;itsct=apps_box_appicon" style="width: 170px; height: 170px; border-radius: 22%; overflow: hidden; display: inline-block; vertical-align: middle;"><img src="https://is1-ssl.mzstatic.com/image/thumb/Purple211/v4/29/cc/91/29cc9159-f5d6-e224-154d-15b15e0e385b/AppIcon-1x_U007emarketing-0-8-0-0-sRGB-85-220-0.png/540x540bb.jpg" alt="腾讯视频-巴黎奥运全程直击" style="width: 170px; height: 170px; border-radius: 22%; overflow: hidden; display: inline-block; vertical-align: middle;"></a>
<a href="https://apps.apple.com/hk/app/xptv/id6473160495?itscg=30200&amp;itsct=apps_box_appicon" style="width: 170px; height: 170px; border-radius: 22%; overflow: hidden; display: inline-block; vertical-align: middle;"><img src="https://is1-ssl.mzstatic.com/image/thumb/Purple221/v4/66/76/a7/6676a7ac-73f1-b7f7-1fbc-82384cd2b337/AppIcon-0-0-1x_U007epad-0-10-0-85-220.png/540x540bb.jpg" alt="XPTV" style="width: 170px; height: 170px; border-radius: 22%; overflow: hidden; display: inline-block; vertical-align: middle;"></a>
