import Foundation

/// アナログ時計の針の角度（12時方向を 0 度とした時計回りの度数）。
public struct ClockHands: Equatable, Sendable {
    public var hour: Double
    public var minute: Double
    public var second: Double

    public init(hour: Double, minute: Double, second: Double) {
        self.hour = hour
        self.minute = minute
        self.second = second
    }

    /// 指定した日時・タイムゾーンから各針の角度を求める。
    ///
    /// - Parameters:
    ///   - date: 表示したい時刻。
    ///   - timeZone: 計算に使うタイムゾーン。
    ///   - sweepingSeconds: `true` ならミリ秒を含めて秒針を連続的に動かす。
    ///     `false` なら 1 秒ごとにカチッと進む（クォーツ時計風）。
    public init(date: Date, timeZone: TimeZone = .current, sweepingSeconds: Bool = true) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        let parts = calendar.dateComponents([.hour, .minute, .second, .nanosecond], from: date)
        let hour = Double(parts.hour ?? 0).truncatingRemainder(dividingBy: 12)
        let minute = Double(parts.minute ?? 0)
        let fraction = sweepingSeconds ? Double(parts.nanosecond ?? 0) / 1_000_000_000 : 0
        let second = Double(parts.second ?? 0) + fraction

        // 上位の針は下位の針の進み具合を引き継いで滑らかに動かす。
        self.second = second * 6
        self.minute = (minute + second / 60) * 6
        self.hour = (hour + (minute + second / 60) / 60) * 30
    }
}
