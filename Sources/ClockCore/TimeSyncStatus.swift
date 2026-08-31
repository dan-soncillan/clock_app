import Foundation

/// フッター右端に出す時刻同期の状態。
///
/// デザイン上の見た目は 2 通り（`NTP OK` と `NTP —`）だが、
/// 内部ではどうしてそうなったかを保持しておく。ツールチップに出す。
public enum TimeSyncStatus: Equatable, Sendable {
    /// まだ確認していない。
    case unknown
    /// 問い合わせ中。
    case checking
    /// 許容範囲に収まっている。
    case synchronized(offset: TimeInterval)
    /// 応答は得られたが、時計がずれている。
    case drifted(offset: TimeInterval)
    /// 問い合わせに失敗した。
    case failed(reason: String)

    /// 同期済みと見なすずれの上限（秒）。
    public static let tolerance: TimeInterval = 2

    /// 測定結果から状態を決める。
    public static func from(_ measurement: NTPMeasurement) -> TimeSyncStatus {
        abs(measurement.offset) <= tolerance
            ? .synchronized(offset: measurement.offset)
            : .drifted(offset: measurement.offset)
    }

    /// フッターに出す文字列。
    public var label: String {
        switch self {
        case .synchronized: return "NTP OK"
        default: return "NTP —"
        }
    }

    public var isSynchronized: Bool {
        if case .synchronized = self { return true }
        return false
    }

    /// ツールチップに出す説明。ずれの実測値を確認できる。
    public var detailText: String {
        switch self {
        case .unknown:
            return "時刻同期は未確認です。クリックで確認します。"
        case .checking:
            return "時刻サーバーに問い合わせ中…"
        case .synchronized(let offset):
            return "時刻サーバーとのずれ \(Self.millisecondsText(offset))。クリックで再確認します。"
        case .drifted(let offset):
            return "時計が \(Self.millisecondsText(offset)) ずれています。クリックで再確認します。"
        case .failed(let reason):
            return "時刻同期を確認できません（\(reason)）。クリックで再試行します。"
        }
    }

    private static func millisecondsText(_ offset: TimeInterval) -> String {
        let milliseconds = (offset * 1000).rounded()
        return "\(milliseconds > 0 ? "+" : "")\(Int(milliseconds)) ms"
    }
}
