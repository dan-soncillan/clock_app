import ClockCore
import SwiftUI

/// 高さ 46px のフッター。左にフォントウェイト切替、右に表示形式と同期状態。
struct FooterView: View {
    @Environment(ClockSettings.self) private var settings
    @Environment(TimeSyncMonitor.self) private var syncMonitor

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 10) {
                Text("FONT WEIGHT")
                    .font(AppFont.archivo(size: 10, weight: 600))
                    .tracking(em: 0.2, size: 10)
                    .foregroundStyle(Theme.textLabel)

                weightSegments
            }

            Spacer(minLength: 0)

            HStack(spacing: 16) {
                Text(formatLabel)
                    .foregroundStyle(Theme.textFooter)
                syncIndicator
            }
            .font(AppFont.archivo(size: 11, weight: 500))
            .tracking(em: 0.12, size: 11)
        }
        .padding(.horizontal, 22)
        .frame(height: Theme.footerHeight)
        .background(Theme.chromeBackground)
        .overlay(alignment: .top) {
            Rectangle().fill(Theme.borderChrome).frame(height: 1)
        }
    }

    /// 時刻同期の状態。クリックで再確認でき、実測のずれはツールチップに出す。
    private var syncIndicator: some View {
        let status = syncMonitor.status
        return Text(status.label)
            .foregroundStyle(status.isSynchronized ? settings.accent.color : Theme.textFooter)
            .contentShape(Rectangle())
            .onTapGesture { Task { await syncMonitor.refresh() } }
            .help(status.detailText)
            .accessibilityLabel(Text(status.detailText))
    }

    private var formatLabel: String {
        "\(settings.use24h ? "24H" : "12H") · \(settings.smoothSweep ? "SWEEP" : "TICK")"
    }

    private var weightSegments: some View {
        HStack(spacing: 4) {
            ForEach(ClockSettings.weightOptions, id: \.self) { option in
                WeightSegment(
                    value: option,
                    isSelected: settings.weight == option,
                    action: { settings.weight = option }
                )
            }
        }
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: Theme.segmentCornerRadius, style: .continuous)
                .fill(Theme.segmentTrack)
        )
    }
}

/// ウェイト切替の 1 コマ。選択中は白背景、未選択はホバーでうっすら反応する。
private struct WeightSegment: View {
    var value: Int
    var isSelected: Bool
    var action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Text("\(value)")
            .font(AppFont.archivo(size: 11, weight: 600))
            .tracking(em: 0.06, size: 11)
            .monospacedDigit()
            .foregroundStyle(isSelected ? Theme.windowBackground : Theme.textTertiary)
            .padding(.horizontal, 11)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: Theme.segmentItemCornerRadius, style: .continuous)
                    .fill(background)
            )
            .contentShape(Rectangle())
            .onTapGesture(perform: action)
            .onHover { isHovering = $0 }
            .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
            .accessibilityLabel(Text("フォントウェイト \(value)"))
    }

    private var background: Color {
        if isSelected { return Theme.textPrimary }
        return isHovering ? Theme.segmentHover : .clear
    }
}
