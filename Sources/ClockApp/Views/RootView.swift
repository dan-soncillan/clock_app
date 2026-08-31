import ClockCore
import SwiftUI

/// メイン画面。
///
/// レイアウトはデザイン基準の 980 × 620 の座標系で組み、
/// 実ウィンドウのサイズにはまとめて拡大縮小をかける。
/// こうすると配置を組み替えずに、文字盤と文字が同じ倍率で追従する。
struct RootView: View {
    @Environment(ClockSettings.self) private var settings

    /// 表示に使うタイムゾーン。ワールドクロックに広げるならここを差し替える。
    var timeZone: TimeZone = .current
    var syncStatus: TimeSyncStatus = UnverifiedTimeSyncStatusProvider().status

    var body: some View {
        GeometryReader { proxy in
            let scale = min(
                proxy.size.width / Theme.canvasSize.width,
                proxy.size.height / Theme.canvasSize.height
            )

            TimelineView(schedule) { context in
                canvas(for: context.date)
            }
            .frame(width: Theme.canvasSize.width, height: Theme.canvasSize.height)
            .scaleEffect(scale)
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .background(Theme.windowBackground)
        .preferredColorScheme(.dark)
    }

    /// 秒針を滑らかに動かすときだけ毎フレーム更新し、それ以外は 1 秒おきに留める。
    private var schedule: AnyTimelineSchedule {
        if settings.showSeconds && settings.smoothSweep {
            return AnyTimelineSchedule(AnimationTimelineSchedule())
        }
        return AnyTimelineSchedule(PeriodicTimelineSchedule(from: .now, by: 1))
    }

    private func canvas(for date: Date) -> some View {
        VStack(spacing: 0) {
            TitleBarView()

            HStack(spacing: 22) {
                AnalogClockView(
                    date: date,
                    timeZone: timeZone,
                    showSeconds: settings.showSeconds,
                    smoothSweep: settings.smoothSweep,
                    weight: settings.weight,
                    accent: settings.accent.color
                )

                DigitalPanelView(
                    date: date,
                    formatter: ClockFormatter(timeZone: timeZone, uses24HourClock: settings.use24h),
                    progress: CalendarProgress(date: date, timeZone: timeZone),
                    showSeconds: settings.showSeconds,
                    weight: settings.weight,
                    accent: settings.accent.color
                )
            }
            .padding(EdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 22))
            .frame(maxHeight: .infinity)

            FooterView(syncStatus: syncStatus)
        }
        .background(Theme.windowBackground)
    }
}
