import ClockCore
import SwiftUI

@main
struct ClockAppMain: App {
    @State private var settings = ClockSettings()
    @State private var syncMonitor = TimeSyncMonitor()

    init() {
        FontRegistrar.registerBundledFonts()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(settings)
                .environment(syncMonitor)
                .frame(
                    minWidth: Theme.canvasSize.width * Theme.minimumScale,
                    minHeight: Theme.canvasSize.height * Theme.minimumScale
                )
                .task { await syncMonitor.run() }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: Theme.canvasSize.width, height: Theme.canvasSize.height)

        Settings {
            SettingsView()
                .environment(settings)
        }
    }
}
