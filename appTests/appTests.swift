//
//  appTests.swift
//  appTests
//
//  Created by Pedro on 04/09/2020.
//  Copyright © 2020 pedroSG94. All rights reserved.
//

import XCTest
@testable import app

class appTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
       
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testStapAH265() {
        let expectedStapA: [UInt8] = [128, 224, 0, 1, 0, 169, 138, 199, 7, 91, 205, 21, 96, 1, 0, 7, 0, 0, 0, 1, 2, 3, 4, 0, 7, 0, 0, 0, 1, 10, 11, 12]
        let fakeSps: [UInt8] = [0x00, 0x00, 0x00, 0x01, 0x02, 0x03, 0x04]
        let fakePps: [UInt8] = [0x00, 0x00, 0x00, 0x01, 0x0A, 0x0B, 0x0C]
        let fakeVps: [UInt8] = [0x00, 0x00, 0x00, 0x01, 0x0D, 0x0E, 0x0F]
        
        let header: [UInt8] = [0x00, 0x00, 0x00, 0x01, 0x05, 0x00]
        let fakeH265 = header + [UInt8](repeating: 0x00, count: 2500)
        
        let packet1Size = RtpConstants.MTU - 28 - RtpConstants.rtpHeaderLength - 3
        let chunk1 = fakeH265[header.count..<header.count + packet1Size]
        let chunk2 = fakeH265[header.count + packet1Size..<fakeH265.count]
        let expectedRtp: [UInt8] = [128, 96, 0, 2, 0, 169, 138, 199, 7, 91, 205, 21, 98, 1, 130] + chunk1
        let expectedRtp2: [UInt8] = [128, 224, 0, 3, 0, 169, 138, 199, 7, 91, 205, 21, 98, 1, 66] + chunk2
        
        //128, 96, 0, 2, 0, 169, 138, 199, 7, 91, 205, 21, 98, 1, 0
        //128, 224, 0, 3, 0, 169, 138, 199, 7, 91, 205, 21, 98, 1, 64
        let h265Packet = H265Packet(sps: fakeSps, pps: fakePps)
        h265Packet.setSSRC(ssrc: 123456789)
        let frame = Frame(buffer: fakeH265, length: UInt32(fakeH265.count), timeStamp: 123456789, flag: 1)
        var frames = [RtpFrame]()
        h265Packet.createAndSendPacket(
            data: frame,
            callback: { (rtpFrame) in
                frames.append(rtpFrame)
            }
        )

        assert(frames.count == 3)
        assert(frames[0].buffer == expectedStapA)
        assert(frames[1].buffer == expectedRtp)
        assert(frames[2].buffer == expectedRtp2)
    }

}
