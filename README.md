# rtmp-rtsp-stream-client-swift

Library to stream in rtmp and rtsp for IOS. All code in Swift.

## State

Actually any bug report will be ignored because it is not stable/usable.
Any feature request or suggestion is welcome.

I need to fix multiple things but it is working.

This project is under develop and it is not usable.
This will take so much time so don't expect anything about it.

## Features

- [x] Switch camera while streaming
- [x] RTSP TCP/UDP
- [x] RTSPS
- [x] RTSP auth (basic and digest)

### Incoming features

I will develop this features:

- RTSP H265 (close to finish. Encoder never produce a IDR nal type, I need to check it)
- Local video record
- Upload to cocoa or similar
- RTMP (included RTMPS and auth)
- Real time filters
- Stream from device display (DisplayRtsp/DisplayRtmp)
- Stream from file (FromFileRtsp/FromFileRtmp)
- Minors features: video bitrate on fly, adaptative bitrate, multiple streams, etc.
