import Foundation

/// フッター右端に出す時刻同期の状態。
///
/// デザインでは同期済みを `NTP OK`（アクセント色）、それ以外を `NTP —`（副色）で
/// 表示する。実際の同期確認は未実装のため、既定は `.unknown` のまま。
/// SNTP 問い合わせなどを実装したら `.synchronized` を返すように差し替える。
public enum TimeSyncStatus: Equatable, Sendable {
    case synchronized
    case unknown

    public var label: String {
        switch self {
        case .synchronized: return "NTP OK"
        case .unknown: return "NTP —"
        }
    }
}

/// 同期状態の供給元。実装を差し替えられるようにプロトコルにしてある。
public protocol TimeSyncStatusProviding: Sendable {
    var status: TimeSyncStatus { get }
}

/// 何も確認しない既定の実装。常に `.unknown` を返す。
public struct UnverifiedTimeSyncStatusProvider: TimeSyncStatusProviding {
    public init() {}
    public var status: TimeSyncStatus { .unknown }
}
