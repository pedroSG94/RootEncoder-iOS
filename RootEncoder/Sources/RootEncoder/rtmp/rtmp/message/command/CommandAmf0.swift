//
// Created by Pedro  on 16/7/22.
// Copyright (c) 2022 pedroSG94. All rights reserved.
//

import Foundation

public class CommandAmf0: RtmpCommand {

    public override init(name: String = "", commandId: Int = 0, timeStamp: Int = 0, streamId: Int = 0, basicHeader: BasicHeader = BasicHeader(chunkType: ChunkType.TYPE_0, chunkStreamId: Int(ChunkStreamId.OVER_CONNECTION.rawValue))) {
        super.init(name: name, commandId: commandId, timeStamp: timeStamp, streamId: streamId, basicHeader: basicHeader)
    }

    override func getType() -> MessageType {
        MessageType.COMMAND_AMF0
    }
}
