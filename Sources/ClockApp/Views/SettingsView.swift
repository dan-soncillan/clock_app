import SwiftUI

/// 環境設定ウインドウ（⌘,）。
///
/// フォントウェイトはフッターで切り替えるので、ここにはそれ以外の
/// 永続設定だけを置く。
struct SettingsView: View {
    @Environment(ClockSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings

        Form {
            Toggle("24時間表記", isOn: $settings.use24h)
            Toggle("秒を表示", isOn: $settings.showSeconds)
            Toggle("秒針を滑らかに動かす", isOn: $settings.smoothSweep)
                .disabled(!settings.showSeconds)

            Picker("アクセント", selection: $settings.accent) {
                ForEach(AccentColor.allCases) { accent in
                    HStack {
                        Circle()
                            .fill(accent.color)
                            .frame(width: 10, height: 10)
                        Text(accent.label)
                    }
                    .tag(accent)
                }
            }
        }
        .toggleStyle(.switch)
        .formStyle(.grouped)
        .frame(width: 340)
    }
}
