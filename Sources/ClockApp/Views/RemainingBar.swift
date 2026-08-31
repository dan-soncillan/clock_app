import SwiftUI

/// 残量バー。塗りは「残り」を表すので、トラックの右端から伸びる。
struct RemainingBar: View {
    /// 0...1。1 で全幅。
    var fraction: Double
    var accent: Color

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Theme.barCornerRadius, style: .continuous)

        GeometryReader { proxy in
            HStack(spacing: 0) {
                Spacer(minLength: 0)
                Rectangle()
                    .fill(accent)
                    .frame(width: proxy.size.width * min(max(fraction, 0), 1))
            }
        }
        .frame(height: 4)
        .background(Theme.barTrack)
        .clipShape(shape)
    }
}

/// バーの下に置く目盛りラベル。両端揃え、等間隔。
struct AxisLabels: View {
    var labels: [String]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(labels.enumerated()), id: \.offset) { index, label in
                if index > 0 { Spacer(minLength: 0) }
                Text(label)
                    .font(AppFont.archivo(size: 9.5, weight: 500))
                    .tracking(em: 0.14, size: 9.5)
                    .foregroundStyle(Theme.textAxis)
            }
        }
    }
}
