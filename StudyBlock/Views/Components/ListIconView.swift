import AppKit
import SwiftUI

struct ListIconView: View {
    @Environment(ListIconStore.self) private var iconStore

    let source: ListIconSource
    var size: CGFloat = 20
    var fallbackColor: Color = .secondary

    var body: some View {
        Group {
            if let resolvedImage = iconStore.image(for: source) {
                Image(nsImage: resolvedImage)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: fallbackSystemImage)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(fallbackColor)
                    .padding(2)
            }
        }
        .frame(width: size, height: size)
        .task(id: source) {
            iconStore.load(source)
        }
        .accessibilityHidden(true)
    }

    private var fallbackSystemImage: String {
        switch source {
        case .website:
            "globe"
        case .application:
            "app"
        case .system(let name):
            name
        }
    }
}
