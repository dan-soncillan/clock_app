import Foundation
import Observation
import SwiftUI

/// アクセント色の選択肢（デザイントークンで確定している 4 色）。
enum AccentColor: String, CaseIterable, Identifiable {
    case red
    case orange
    case blue
    case green

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .red: return Color(hex: 0xE5372C)
        case .orange: return Color(hex: 0xF0522B)
        case .blue: return Color(hex: 0x3B7DD8)
        case .green: return Color(hex: 0x2FA36B)
        }
    }

    var label: String {
        switch self {
        case .red: return "レッド"
        case .orange: return "オレンジ"
        case .blue: return "ブルー"
        case .green: return "グリーン"
        }
    }
}

/// ユーザー設定。値は UserDefaults を唯一の保存先とし、
/// Observation には computed property 経由で変更を通知する。
@Observable
final class ClockSettings {
    /// フッターで選べるフォントウェイト。
    static let weightOptions = [400, 500, 600, 700, 800]

    /// デジタル時刻・秒・文字盤数字の太さ。
    var weight: Int {
        get {
            access(keyPath: \.weight)
            return store.integer(forKey: Keys.weight)
        }
        set {
            withMutation(keyPath: \.weight) { store.set(newValue, forKey: Keys.weight) }
        }
    }

    /// 秒針とデジタル秒表示の ON/OFF。
    var showSeconds: Bool {
        get { flag(Keys.showSeconds, keyPath: \.showSeconds) }
        set { setFlag(newValue, Keys.showSeconds, keyPath: \.showSeconds) }
    }

    /// 秒針のスムーズ運針 ON/OFF。
    var smoothSweep: Bool {
        get { flag(Keys.smoothSweep, keyPath: \.smoothSweep) }
        set { setFlag(newValue, Keys.smoothSweep, keyPath: \.smoothSweep) }
    }

    /// 24 時間表記 / 12 時間表記。
    var use24h: Bool {
        get { flag(Keys.use24h, keyPath: \.use24h) }
        set { setFlag(newValue, Keys.use24h, keyPath: \.use24h) }
    }

    /// 生年月日。コードには置かず、この Mac の UserDefaults にだけ保存する。
    /// 未設定なら nil で、一番下のバーは値を伏せる。
    var birthday: DateComponents? {
        get {
            access(keyPath: \.birthday)
            guard let raw = store.string(forKey: Keys.birthday) else { return nil }
            let parts = raw.split(separator: "-").compactMap { Int($0) }
            guard parts.count == 3 else { return nil }
            return DateComponents(year: parts[0], month: parts[1], day: parts[2])
        }
        set {
            withMutation(keyPath: \.birthday) {
                if let newValue,
                   let year = newValue.year, let month = newValue.month, let day = newValue.day {
                    store.set(String(format: "%04d-%02d-%02d", year, month, day), forKey: Keys.birthday)
                } else {
                    store.removeObject(forKey: Keys.birthday)
                }
            }
        }
    }

    /// 秒針・秒数字・残りバー・同期表示の色。
    var accent: AccentColor {
        get {
            access(keyPath: \.accent)
            return store.string(forKey: Keys.accent).flatMap(AccentColor.init(rawValue:)) ?? .red
        }
        set {
            withMutation(keyPath: \.accent) { store.set(newValue.rawValue, forKey: Keys.accent) }
        }
    }

    @ObservationIgnored private let store: UserDefaults

    init(store: UserDefaults = .standard) {
        self.store = store
        store.register(defaults: [
            Keys.weight: 700,
            Keys.showSeconds: true,
            Keys.smoothSweep: true,
            Keys.use24h: true,
            Keys.accent: AccentColor.red.rawValue
        ])
    }

    private func flag(_ key: String, keyPath: KeyPath<ClockSettings, Bool>) -> Bool {
        access(keyPath: keyPath)
        return store.bool(forKey: key)
    }

    private func setFlag(_ newValue: Bool, _ key: String, keyPath: KeyPath<ClockSettings, Bool>) {
        withMutation(keyPath: keyPath) { store.set(newValue, forKey: key) }
    }

    private enum Keys {
        static let weight = "weight"
        static let showSeconds = "showSeconds"
        static let smoothSweep = "smoothSweep"
        static let use24h = "use24h"
        static let accent = "accent"
        static let birthday = "birthday"
    }
}
