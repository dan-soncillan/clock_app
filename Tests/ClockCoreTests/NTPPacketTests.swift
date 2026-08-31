import XCTest
@testable import ClockCore

final class NTPPacketTests: XCTestCase {
    func testTimestampRoundTripsThroughTheWireFormat() {
        let original = Date(timeIntervalSince1970: 1_788_000_123.456)
        let restored = NTPTimestamp(date: original).date
        // 32bit の小数部の分解能はおよそ 0.23ns。
        XCTAssertEqual(restored.timeIntervalSince1970, original.timeIntervalSince1970, accuracy: 0.000001)
    }

    func testEpochIsCountedFrom1900() {
        let unixEpoch = NTPTimestamp(date: Date(timeIntervalSince1970: 0))
        XCTAssertEqual(unixEpoch.seconds, 2_208_988_800)
        XCTAssertEqual(unixEpoch.fraction, 0)
        XCTAssertTrue(NTPTimestamp(seconds: 0, fraction: 0).isZero)
    }

    func testClientRequestHasTheRightHeaderAndSize() {
        let sentAt = Date(timeIntervalSince1970: 1_788_000_000)
        let data = NTPPacket.clientRequest(transmit: NTPTimestamp(date: sentAt))

        XCTAssertEqual(data.count, NTPPacket.size)
        // 閏秒指示子 0 / バージョン 4 / モード 3（クライアント）。
        XCTAssertEqual(data[0], 0b00_100_011)

        // 送信時刻は 40 バイト目から入る。読み返せることを確認する。
        let echoed = NTPPacket(data: data)
        XCTAssertEqual(echoed?.transmit, NTPTimestamp(date: sentAt))
    }

    func testParsingAServerResponse() {
        let originate = Date(timeIntervalSince1970: 1_788_000_000)
        let receive = Date(timeIntervalSince1970: 1_788_000_000.02)
        let transmit = Date(timeIntervalSince1970: 1_788_000_000.03)

        let packet = NTPPacket(data: Self.serverResponse(
            stratum: 2, originate: originate, receive: receive, transmit: transmit
        ))

        XCTAssertEqual(packet?.mode, NTPPacket.serverMode)
        XCTAssertEqual(packet?.version, 4)
        XCTAssertEqual(packet?.stratum, 2)
        XCTAssertEqual(packet?.originate, NTPTimestamp(date: originate))
        XCTAssertEqual(packet?.receive, NTPTimestamp(date: receive))
        XCTAssertEqual(packet?.transmit, NTPTimestamp(date: transmit))
    }

    func testShortDataIsRejected() {
        XCTAssertNil(NTPPacket(data: Data(repeating: 0, count: 47)))
    }

    func testOffsetCancelsOutTheRoundTrip() {
        // こちらの時計が約9.5秒遅れていて、往復に1秒かかった場合。
        let base = Date(timeIntervalSince1970: 1_788_000_000)
        let measurement = NTPMeasurement(
            originate: base,
            receive: base.addingTimeInterval(10),
            transmit: base.addingTimeInterval(11),
            destination: base.addingTimeInterval(2)
        )
        XCTAssertEqual(measurement.offset, 9.5, accuracy: 0.0001)
        XCTAssertEqual(measurement.roundTripDelay, 1, accuracy: 0.0001)
    }

    func testSynchronizedClockHasNearlyZeroOffset() {
        let base = Date(timeIntervalSince1970: 1_788_000_000)
        let measurement = NTPMeasurement(
            originate: base,
            receive: base.addingTimeInterval(0.02),
            transmit: base.addingTimeInterval(0.03),
            destination: base.addingTimeInterval(0.05)
        )
        XCTAssertEqual(measurement.offset, 0, accuracy: 0.0001)
        XCTAssertTrue(TimeSyncStatus.from(measurement).isSynchronized)
    }

    func testLargeDriftIsNotReportedAsSynchronized() {
        let base = Date(timeIntervalSince1970: 1_788_000_000)
        let measurement = NTPMeasurement(
            originate: base,
            receive: base.addingTimeInterval(30),
            transmit: base.addingTimeInterval(30),
            destination: base.addingTimeInterval(0.05)
        )
        let status = TimeSyncStatus.from(measurement)
        XCTAssertFalse(status.isSynchronized)
        XCTAssertEqual(status.label, "NTP —")
        if case .drifted = status {} else { XCTFail("drifted になるはず: \(status)") }
    }

    func testLabelsFollowTheDesign() {
        XCTAssertEqual(TimeSyncStatus.synchronized(offset: 0).label, "NTP OK")
        XCTAssertEqual(TimeSyncStatus.unknown.label, "NTP —")
        XCTAssertEqual(TimeSyncStatus.checking.label, "NTP —")
        XCTAssertEqual(TimeSyncStatus.failed(reason: "応答なし").label, "NTP —")
    }

    /// テスト用のサーバー応答を組み立てる。
    private static func serverResponse(
        stratum: UInt8,
        originate: Date,
        receive: Date,
        transmit: Date
    ) -> Data {
        var data = Data(repeating: 0, count: NTPPacket.size)
        data[0] = (0 << 6) | (4 << 3) | NTPPacket.serverMode
        data[1] = stratum
        write(NTPTimestamp(date: originate), into: &data, at: 24)
        write(NTPTimestamp(date: receive), into: &data, at: 32)
        write(NTPTimestamp(date: transmit), into: &data, at: 40)
        return data
    }

    private static func write(_ timestamp: NTPTimestamp, into data: inout Data, at offset: Int) {
        for i in 0..<4 {
            data[offset + i] = UInt8(truncatingIfNeeded: timestamp.seconds >> (8 * (3 - i)))
            data[offset + 4 + i] = UInt8(truncatingIfNeeded: timestamp.fraction >> (8 * (3 - i)))
        }
    }
}
