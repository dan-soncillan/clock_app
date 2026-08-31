import SwiftUI

/// 中身をすりガラス風のカードで包む。アナログ／デジタル両方の土台に使う。
struct GlassCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme

    var content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous)

        content
            .padding(Theme.cardPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.ultraThinMaterial, in: shape)
            .overlay(shape.strokeBorder(Theme.cardStroke(for: colorScheme), lineWidth: 1))
            .shadow(color: Theme.shadow(for: colorScheme), radius: 24, x: 0, y: 12)
    }
}
