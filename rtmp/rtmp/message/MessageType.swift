//
// Created by Pedro  on 4/7/22.
// Copyright (c) 2022 pedroSG94. All rights reserved.
//

import Foundation

/**
 * Created by pedro on 21/04/21.
 */
public enum MessageType: UInt8 {

    /**
   * Set Chunk Size, is used to notify the peer a new maximum chunk size to use.
   */
    case SET_CHUNK_SIZE = 0x01

    /**
   * Abort Message, is used to notify the peer if it is waiting for chunks
   * to complete a message, then to discard the partially received message
   * over a chunk stream and abort processing of that message.
   */
    case ABORT = 0x02

    /**
   * The client or the server sends the acknowledgment to the peer after
   * receiving bytes equal to the window size. The window size is the
   * maximum number of bytes that the sender sends without receiving
   * acknowledgment from the receiver.
   */
    case ACKNOWLEDGEMENT = 0x03

    /**
   * The client or the server sends this message to notify the peer about
   * the user control events. This message carries Event type and Event
   * data.
   * Also known as a PING message in some RTMP implementations.
   */
    case USER_CONTROL = 0x04

    /**
   * The client or the server sends this message to inform the peer which
   * window size to use when sending acknowledgment.
   * Also known as ServerBW ("server bandwidth") in some RTMP implementations.
   */
    case WINDOW_ACKNOWLEDGEMENT_SIZE = 0x05

    /**
   * The client or the server sends this message to update the output
   * bandwidth of the peer. The output bandwidth value is the same as the
   * window size for the peer.
   * Also known as ClientBW ("client bandwidth") in some RTMP implementations.
   */
    case SET_PEER_BANDWIDTH = 0x06

    /**
   * RTMP audio packet (0x08)
   * The client or the server sends this message to send audio data to the peer.
   */
    case AUDIO = 0x08

    /**
   * RTMP video packet (0x09)
   * The client or the server sends this message to send video data to the peer.
   */
    case VIDEO = 0x09

    /**
   * The client or the server sends this message to send Metadata or any
   * user data to the peer. Metadata includes details about the data (audio, video etc.)
   * like creation time, duration, theme and so on.
   * This is the AMF3-encoded version.
   */
    case DATA_AMF3 = 0x0F

    /**
   * A shared object is a Flash object (a collection of name value pairs)
   * that are in synchronization across multiple clients, instances, and
   * so on.
   * This is the AMF3 version: kMsgContainerEx=16 for AMF3.
   */
    case SHARED_OBJECT_AMF3 = 0x10

    /**
   * Command messages carry the AMF-encoded commands between the client
   * and the server.
   * A command message consists of command name, transaction ID, and command object that
   * contains related parameters.
   * This is the AMF3-encoded version.
   */
    case COMMAND_AMF3 = 0x11

    /**
   * The client or the server sends this message to send Metadata or any
   * user data to the peer. Metadata includes details about the data (audio, video etc.)
   * like creation time, duration, theme and so on.
   * This is the AMF0-encoded version.
   */
    case DATA_AMF0 = 0x012

    /**
   * A shared object is a Flash object (a collection of name value pairs)
   * that are in synchronization across multiple clients, instances, and
   * so on.
   * This is the AMF0 version: kMsgContainer=19 for AMF0.
   */
    case SHARED_OBJECT_AMF0 = 0x13

    /**
   * Command messages carry the AMF-encoded commands between the client
   * and the server.
   * A command message consists of command name, transaction ID, and command object that
   * contains related parameters.
   * This is the common AMF0 version, also known as INVOKE in some RTMP implementations.
   */
    case COMMAND_AMF0 = 0x14

    /**
   * An aggregate message is a single message that contains a list of sub-messages.
   */
    case AGGREGATE = 0x16
}