# RootEncoder iOS

RootEncoder iOS (rtmp-rtsp-stream-client-swift) is a stream encoder to push video/audio to media servers using protocols RTMP, RTSP and SRT with all code written in Swift


## Status

The project is not stable yet.
For now, the min iOS version required is iOS14 but I have plan to downgrade it a bit. 
Swift 5 is required because RTMP and RTSP protocol use async await in sockets.

## Features

- [X] H264 and AAC support
- [X] Switch camera while streaming
- [X] RTSP TCP/UDP
- [X] RTSPS
- [X] RTSP auth (basic and digest)
- [X] RTMP auth (adobe and llnw)
- [X] RTMP
- [X] RTMPS
- [X] Real time filters (with Metal). For now, support only filters with CIImage but I have plan to add filters using vertex and fragment
- [X] Reconnection (RTMP and RTSP)
- [X] Stream from device display (DisplayRtsp/DisplayRtmp)
- [X] H265 support (RTSP and RTMP)
- [X] Get upload bandwidth used (RTMP and RTSP)
- [X] Local video record

## Compile

### SPM

In Xcode go to:
Project > Package dependencies > + > add this to the search bar:
```
https://github.com/pedroSG94/RootEncoder-iOS
```

## Use examples:

### RTMP

https://github.com/pedroSG94/RootEncoder-iOS/blob/master/app/RtmpSwiftUIView.swift

### RTSP

https://github.com/pedroSG94/RootEncoder-iOS/blob/master/app/RtspSwiftUIView.swift

## Incoming features

I will develop this features but not in this order.

- [ ] Stream from file (FromFileRtsp/FromFileRtmp)
- [ ] Upload to cocoapod
- [ ] Minors features: video bitrate on fly, adaptative bitrate.
- [ ] SRT (maybe the last one)
