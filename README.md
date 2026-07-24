# RootEncoder iOS

[![Release](https://img.shields.io/github/v/release/pedroSG94/RootEncoder-iOS)](https://github.com/pedroSG94/RootEncoder-iOS/releases/latest)

RootEncoder iOS (rtmp-rtsp-stream-client-swift) is a stream encoder to push video/audio to media servers using protocols RTMP, RTSP with all code written in Swift


## Status

The project is not stable yet.

## Features

- [X] Required iOS 14 and Swift 5
- [X] H264, H265 and AAC support
- [X] Switch camera while streaming
- [X] RTSP TCP/UDP
- [X] RTSPS
- [X] RTSP auth (basic and digest)
- [X] RTMP auth (adobe and llnw)
- [X] RTMP
- [X] RTMPS
- [X] Real time filters (with Metal)
- [X] Reconnection (RTMP and RTSP)
- [X] Stream from device display (DisplayRtsp/DisplayRtmp)
- [X] Get upload bandwidth used (RTMP and RTSP)
- [X] Local video record

## Compile

Minimum requirements: iOS 14 and Swift 5.10.

### Adding it from Xcode

1. Open your project and go to `File > Add Package Dependencies...` (or `Project > Package Dependencies > +`).
2. Paste this URL in the search bar:
```
https://github.com/pedroSG94/RootEncoder-iOS
```

Select exact version is recommended.

### Adding it from Package.swift

```swift
dependencies: [
    .package(url: "https://github.com/pedroSG94/RootEncoder-iOS.git", from: "0.1.1")
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: [
            .product(name: "RootEncoder", package: "RootEncoder-iOS")
        ]
    )
]
```

### Import

The library exposes a single module with all the protocols included:
```swift
import RootEncoder
```

## Use examples:

### RTMP

https://github.com/pedroSG94/RootEncoder-iOS/blob/master/app/RtmpSwiftUIView.swift

### RTSP

https://github.com/pedroSG94/RootEncoder-iOS/blob/master/app/RtspSwiftUIView.swift

## Incoming features

- [ ] Stream from file and others video/audio sources
- [ ] Make RTMP module equivalent in features to Android version
- [ ] Make RTSP module equivalent in features to Android version
- [ ] SRT
- [ ] WHIP
