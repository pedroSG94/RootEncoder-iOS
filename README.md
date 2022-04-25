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

- RTSP H265 (Frozen for now)
- Local video record
- Upload to cocoa or similar
- RTMP (included RTMPS and auth)
- Real time filters
- Stream from device display (DisplayRtsp/DisplayRtmp)
- Stream from file (FromFileRtsp/FromFileRtmp)
- Minors features: video bitrate on fly, adaptative bitrate, multiple streams, etc.

### H265 frozen reason (Any help or suggestion is welcome)

If you encode frames in H265 only the first frame is an IDR (IDR_N_LP in my case). 
After that, the encoder use CRA_NUT as key frame but it is not working to start stream.