//
// Created by Pedro  on 24/4/22.
// Copyright (c) 2022 pedroSG94. All rights reserved.
// timestamp = 3 bytes (timestamp of packet. If is greater than or
// equal to 16777215 (hexadecimal 0xFFFFFF), this field MUST be 16777215)
//
// message length = 3 bytes (packet size)
//
// message type id = 1 byte (represented by MessageType class)
//
// message stream id = 4 bytes (transactionId as little endian format)

import Foundation

public enum ChunkType: UInt8 {
  /**
   * 11 bytes long.
   * This type MUST be used at the start of a chunk stream, and whenever the stream timestamp goes
   * backward (e.g., because of a backward seek).
   *
   * +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   * | timestamp |message length |
   * +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   * | message length (cont) |message type id| msg stream id |
   * +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   * | message stream id (cont) |
   * +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   */
    case TYPE_0 = 0x00

    /**
     * 7 bytes long.
     * The message stream ID is not included; this chunk takes the same stream ID as the preceding chunk.
     * Streams with variable-sized messages (for example, many video formats)
     * SHOULD use this format for the first chunk of each new message after the first
     *
     * +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
     * | timestamp delta |message length |
     * +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
     * | message length (cont) |message type id|
     * +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
     */
    case TYPE_1 = 0x01

    /**
     * 3 bytes long.
     * Neither the stream ID nor the
     * message length is included; this chunk has the same stream ID and
     * message length as the preceding chunk. Streams with constant-sized
     * messages (for example, some audio and data formats) SHOULD use this
     * format for the first chunk of each message after the first.
     *
     * +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
     * | timestamp delta |
     * +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
     */
    case TYPE_2 = 0x02

    /**
     * Have no message header
     * When a single message is split into chunks, all chunks of a message except
     * the first one SHOULD use this type
     */
    case TYPE_3 = 0x03
}