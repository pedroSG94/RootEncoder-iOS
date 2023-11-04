# RootEncoder iOS

RootEncoder iOS (rtmp-rtsp-stream-client-swift) is a stream encoder to push video/audio to media servers using protocols RTMP, RTSP and SRT with all code written in Swift


## Status

The project is not stable yet.
For now, the min iOS version required is iOS14 but I have plan to downgrade it a bit. 
Swift 5 is required because RTMP and RTSP protocol use async await in sockets.

## Features

- [x] H264 and AAC support
- [x] Switch camera while streaming
- [x] RTSP TCP/UDP
- [x] RTSPS
- [x] RTSP auth (basic and digest)
- [x] RTMP
- [x] RTMPS
- [X] Real time filters (with Metal). For now, support only filters with CIImage but I have plan to add filters using vertex and fragment
- [X] Reconnection (RTMP and RTSP)
- [X] Stream from device display (DisplayRtsp/DisplayRtmp)
- [X] H265 support (RTSP)
- [X] Get upload bandwidth used (RTMP and RTSP)

## Incoming features

I will develop this features but not in this order.

- [ ] RTMP auth (adobe and llnw)
- [ ] H265 support (RTMP)
- [ ] Local video record
- [ ] Stream from file (FromFileRtsp/FromFileRtmp)
- [ ] Upload to cocoapod or similar
- [ ] Minors features: video bitrate on fly, adaptative bitrate.
- [ ] SRT (maybe the last one)
