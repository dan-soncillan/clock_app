import SwiftUI

/// 表示設定。ポップオーバーと環境設定ウインドウ（⌘,）の両方から使う。
struct SettingsView: View {
    @Environment(ClockSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings

        Form {
            Toggle("24時間表記", isOn: $settings.uses24HourClock)
            Toggle("秒を表示", isOn: $settings.showsSeconds)
            Toggle("秒針を滑らかに動かす", isOn: $settings.sweepingSeconds)
                .disabled(!settings.showsSeconds)
            Toggle("文字盤に数字を表示", isOn: $settings.showsNumerals)
        }
        .toggleStyle(.switch)
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
    }
}
