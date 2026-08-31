import Foundation
import Observation

/// ユーザー設定。値は UserDefaults を唯一の保存先とし、
/// Observation には computed property 経由で変更を通知する。
@Observable
final class ClockSettings {
    /// 24 時間表記にするか。
    var uses24HourClock: Bool {
        get { value(for: Keys.uses24HourClock, keyPath: \.uses24HourClock) }
        set { setValue(newValue, for: Keys.uses24HourClock, keyPath: \.uses24HourClock) }
    }

    /// 秒を表示するか（デジタル表示・秒針の両方に効く）。
    var showsSeconds: Bool {
        get { value(for: Keys.showsSeconds, keyPath: \.showsSeconds) }
        set { setValue(newValue, for: Keys.showsSeconds, keyPath: \.showsSeconds) }
    }

    /// 秒針を連続的に動かすか。false なら 1 秒ごとに刻む。
    var sweepingSeconds: Bool {
        get { value(for: Keys.sweepingSeconds, keyPath: \.sweepingSeconds) }
        set { setValue(newValue, for: Keys.sweepingSeconds, keyPath: \.sweepingSeconds) }
    }

    /// アナログ時計に文字盤の数字を出すか。
    var showsNumerals: Bool {
        get { value(for: Keys.showsNumerals, keyPath: \.showsNumerals) }
        set { setValue(newValue, for: Keys.showsNumerals, keyPath: \.showsNumerals) }
    }

    @ObservationIgnored private let store: UserDefaults

    init(store: UserDefaults = .standard) {
        self.store = store
        store.register(defaults: [
            Keys.uses24HourClock: true,
            Keys.showsSeconds: true,
            Keys.sweepingSeconds: true,
            Keys.showsNumerals: false
        ])
    }

    private func value(for key: String, keyPath: KeyPath<ClockSettings, Bool>) -> Bool {
        access(keyPath: keyPath)
        return store.bool(forKey: key)
    }

    private func setValue(_ newValue: Bool, for key: String, keyPath: KeyPath<ClockSettings, Bool>) {
        withMutation(keyPath: keyPath) {
            store.set(newValue, forKey: key)
        }
    }

    private enum Keys {
        static let uses24HourClock = "uses24HourClock"
        static let showsSeconds = "showsSeconds"
        static let sweepingSeconds = "sweepingSeconds"
        static let showsNumerals = "showsNumerals"
    }
}
