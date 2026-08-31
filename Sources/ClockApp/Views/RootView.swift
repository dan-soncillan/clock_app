import ClockCore
import SwiftUI

/// メイン画面。アナログとデジタルを 1 画面に並べて表示する。
struct RootView: View {
    @Environment(ClockSettings.self) private var settings
    @Environment(\.colorScheme) private var colorScheme

    @State private var isShowingSettings = false

    /// 表示に使うタイムゾーン。将来ワールドクロックに広げるならここを差し替える。
    var timeZone: TimeZone = .current

    var body: some View {
        TimelineView(schedule) { context in
            content(for: context.date)
        }
        .background(Theme.windowBackground(for: colorScheme).ignoresSafeArea())
        .frame(minWidth: 520, minHeight: 420)
    }

    /// 秒針を滑らかに動かすときだけ毎フレーム更新し、それ以外は 1 秒おきに留める。
    private var schedule: AnyTimelineSchedule {
        if settings.showsSeconds && settings.sweepingSeconds {
            return AnyTimelineSchedule(AnimationTimelineSchedule())
        }
        return AnyTimelineSchedule(PeriodicTimelineSchedule(from: .now, by: 1))
    }

    private func content(for date: Date) -> some View {
        GeometryReader { proxy in
            VStack(spacing: Theme.contentSpacing) {
                header

                if proxy.size.width >= Theme.stackBreakpoint {
                    HStack(spacing: Theme.contentSpacing) {
                        analogCard(date: date)
                        digitalCard(date: date)
                    }
                } else {
                    VStack(spacing: Theme.contentSpacing) {
                        analogCard(date: date)
                        digitalCard(date: date)
                    }
                }
            }
            .padding(Theme.contentSpacing)
        }
    }

    private var header: some View {
        HStack {
            Text("Clock")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)

            Spacer()

            Button {
                isShowingSettings.toggle()
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 13, weight: .semibold))
            }
            .buttonStyle(.borderless)
            .help("表示設定")
            .popover(isPresented: $isShowingSettings, arrowEdge: .bottom) {
                SettingsView()
                    .frame(width: 260)
                    .padding(16)
            }
        }
    }

    private func analogCard(date: Date) -> some View {
        GlassCard {
            AnalogClockView(
                date: date,
                timeZone: timeZone,
                showsSeconds: settings.showsSeconds,
                sweepingSeconds: settings.sweepingSeconds,
                showsNumerals: settings.showsNumerals
            )
        }
    }

    private func digitalCard(date: Date) -> some View {
        GlassCard {
            DigitalClockView(
                date: date,
                formatter: ClockFormatter(
                    timeZone: timeZone,
                    uses24HourClock: settings.uses24HourClock
                ),
                showsSeconds: settings.showsSeconds
            )
        }
    }
}
