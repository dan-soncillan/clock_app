import Foundation

/// NTP のタイムスタンプ。1900-01-01 を基点とした 32.32 の固定小数。
public struct NTPTimestamp: Equatable, Sendable {
    /// 1900-01-01 から 1970-01-01 までの秒数。
    public static let eraOffset: TimeInterval = 2_208_988_800

    public var seconds: UInt32
    public var fraction: UInt32

    public init(seconds: UInt32, fraction: UInt32) {
        self.seconds = seconds
        self.fraction = fraction
    }

    public init(date: Date) {
        let interval = date.timeIntervalSince1970 + Self.eraOffset
        let whole = interval.rounded(.down)
        seconds = UInt32(truncatingIfNeeded: Int64(whole))
        fraction = UInt32(min((interval - whole) * 4_294_967_296, 4_294_967_295))
    }

    public var date: Date {
        let interval = Double(seconds) + Double(fraction) / 4_294_967_296
        return Date(timeIntervalSince1970: interval - Self.eraOffset)
    }

    /// サーバーが値を埋めなかった場合は全ビット 0 になる。
    public var isZero: Bool { seconds == 0 && fraction == 0 }
}

/// SNTP のパケット（48 バイト）。必要なフィールドだけを扱う。
public struct NTPPacket: Equatable, Sendable {
    public static let size = 48

    /// クライアントが送るモード。
    public static let clientMode: UInt8 = 3
    /// サーバーが返すモード。
    public static let serverMode: UInt8 = 4

    public var leapIndicator: UInt8
    public var version: UInt8
    public var mode: UInt8
    /// 0 は Kiss-o'-Death（サーバーからの拒否）を意味する。
    public var stratum: UInt8
    /// クライアントが送信した時刻（T1）のエコー。
    public var originate: NTPTimestamp
    /// サーバーが受信した時刻（T2）。
    public var receive: NTPTimestamp
    /// サーバーが送信した時刻（T3）。
    public var transmit: NTPTimestamp

    /// クライアント要求を組み立てる。送信時刻以外は 0 でよい。
    public static func clientRequest(transmit: NTPTimestamp, version: UInt8 = 4) -> Data {
        var data = Data(repeating: 0, count: size)
        // 上位 2 bit = 閏秒指示子(0)、続く 3 bit = バージョン、下位 3 bit = モード。
        data[0] = (0 << 6) | ((version & 0b111) << 3) | (clientMode & 0b111)
        write(transmit, into: &data, at: 40)
        return data
    }

    public init?(data: Data) {
        guard data.count >= Self.size else { return nil }
        let bytes = [UInt8](data)

        leapIndicator = (bytes[0] >> 6) & 0b11
        version = (bytes[0] >> 3) & 0b111
        mode = bytes[0] & 0b111
        stratum = bytes[1]
        originate = Self.read(bytes, at: 24)
        receive = Self.read(bytes, at: 32)
        transmit = Self.read(bytes, at: 40)
    }

    private static func write(_ timestamp: NTPTimestamp, into data: inout Data, at offset: Int) {
        for i in 0..<4 {
            data[offset + i] = UInt8(truncatingIfNeeded: timestamp.seconds >> (8 * (3 - i)))
            data[offset + 4 + i] = UInt8(truncatingIfNeeded: timestamp.fraction >> (8 * (3 - i)))
        }
    }

    private static func read(_ bytes: [UInt8], at offset: Int) -> NTPTimestamp {
        var seconds: UInt32 = 0
        var fraction: UInt32 = 0
        for i in 0..<4 {
            seconds = (seconds << 8) | UInt32(bytes[offset + i])
            fraction = (fraction << 8) | UInt32(bytes[offset + 4 + i])
        }
        return NTPTimestamp(seconds: seconds, fraction: fraction)
    }
}

/// 1 回の問い合わせで得た 4 つの時刻から、ずれと往復時間を求める。
public struct NTPMeasurement: Equatable, Sendable {
    /// T1: クライアントが送信した時刻（こちらの時計）。
    public var originate: Date
    /// T2: サーバーが受信した時刻（正しい時計）。
    public var receive: Date
    /// T3: サーバーが送信した時刻（正しい時計）。
    public var transmit: Date
    /// T4: クライアントが受信した時刻（こちらの時計）。
    public var destination: Date

    public init(originate: Date, receive: Date, transmit: Date, destination: Date) {
        self.originate = originate
        self.receive = receive
        self.transmit = transmit
        self.destination = destination
    }

    /// こちらの時計がサーバーからどれだけずれているか（秒）。
    /// 正なら自分の時計が遅れている。往復の遅延は往路と復路で相殺される。
    public var offset: TimeInterval {
        (receive.timeIntervalSince(originate) + transmit.timeIntervalSince(destination)) / 2
    }

    /// 往復にかかった時間（秒）。サーバー内の滞留時間は差し引く。
    public var roundTripDelay: TimeInterval {
        destination.timeIntervalSince(originate) - transmit.timeIntervalSince(receive)
    }
}
