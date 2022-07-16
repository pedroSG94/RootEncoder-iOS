//
// Created by Pedro  on 16/7/22.
// Copyright (c) 2022 pedroSG94. All rights reserved.
//

import Foundation

public class DataAmf3: Data {

    public override init(name: String = "", timeStamp: Int = 0, streamId: Int = 0, basicHeader: BasicHeader = BasicHeader(chunkType: ChunkType.TYPE_0, chunkStreamId: Int(ChunkStreamId.OVER_CONNECTION.rawValue))) {
        super.init(name: name, timeStamp: timeStamp, streamId: streamId, basicHeader: basicHeader)
    }

    override func getType() -> MessageType {
        MessageType.DATA_AMF3
    }
}