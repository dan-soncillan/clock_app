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

    /// 一番下のバーの目標年齢。生年月日はコードに置かず、設定（⌘,）から入力する。
    private static let targetAge = 80

    var body: some View {
        GeometryReader { proxy in
            timeline(scale: scale(for: proxy.size), windowSize: proxy.size)
        }
        .background(Theme.windowBackground)
        .background(WindowConfigurator())
        .preferredColorScheme(.dark)
    }

    /// 基準サイズに対する倍率。縦横のうち収まる方に合わせる。
    private func scale(for windowSize: CGSize) -> CGFloat {
        min(
            windowSize.width / Theme.canvasSize.width,
            windowSize.height / Theme.canvasSize.height
        )
    }

    /// 秒針を滑らかに動かすときだけ毎フレーム更新し、それ以外は 1 秒おきに留める。
    ///
    /// スケジュールは型消去せず、分岐して具体型のまま渡す。`.animation` は
    /// SwiftUI 側で画面のリフレッシュに同期させる特別な扱いを受けるため。
    @ViewBuilder
    private func timeline(scale: CGFloat, windowSize: CGSize) -> some View {
        if settings.showSeconds && settings.smoothSweep {
            TimelineView(.animation) { context in
                scaled(canvas(for: context.date), scale: scale, windowSize: windowSize)
            }
        } else {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                scaled(canvas(for: context.date), scale: scale, windowSize: windowSize)
            }
        }
    }

    /// 基準サイズで組んだ画面を、実ウィンドウに合わせて拡大縮小して中央に置く。
    private func scaled(_ content: some View, scale: CGFloat, windowSize: CGSize) -> some View {
        content
            .frame(width: Theme.canvasSize.width, height: Theme.canvasSize.height)
            .scaleEffect(scale)
            .frame(width: windowSize.width, height: windowSize.height)
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
                    life: settings.birthday.map { birthday in
                        LifeProgress(
                            date: date,
                            birthday: birthday,
                            targetAge: Self.targetAge,
                            timeZone: timeZone
                        )
                    },
                    targetAge: Self.targetAge,
                    showSeconds: settings.showSeconds,
                    weight: settings.weight,
                    accent: settings.accent.color
                )
            }
            .padding(EdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 22))
            .frame(maxHeight: .infinity)

            FooterView()
        }
        .background(Theme.windowBackground)
    }
}
