# RootEncoder iOS

RootEncoder (rtmp-rtsp-stream-client-swift) is a stream encoder to push video/audio to media servers using protocols RTMP, RTSP and SRT with all code written in Swift

For now the min iOS version required is iOS14 but I have plan to downgrade it a bit.

## Features

- [x] H264 and AAC support
- [x] Switch camera while streaming
- [x] RTSP TCP/UDP
- [x] RTSPS
- [x] RTSP auth (basic and digest)
- [x] RTMP
- [x] RTMPS

## Incoming features

I will develop this features but not in this order.

- [ ] RTMP auth (adobe and llnw)
- [ ] H265 support (RTMP and RTSP)
- [ ] Reconnection (RTMP and RTSP)
- [ ] Get upload bandwidth used (RTMP and RTSP)
- [ ] Local video record
- [ ] Real time filters (with OpenGl and/or Metal)
- [ ] Stream from device display (DisplayRtsp/DisplayRtmp)
- [ ] Stream from file (FromFileRtsp/FromFileRtmp)
- [ ] Upload to cocoapod or similar
- [ ] Minors features: video bitrate on fly, adaptative bitrate.
- [ ] SRT
