import SwiftUI

@main
struct ClockAppMain: App {
    @State private var settings = ClockSettings()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(settings)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 880, height: 520)

        Settings {
            SettingsView()
                .environment(settings)
                .frame(width: 320)
                .padding(16)
        }
    }
}
