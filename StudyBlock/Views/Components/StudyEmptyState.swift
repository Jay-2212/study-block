import SwiftUI

/// One shared empty-state voice for onboarding, Settings, and site/app
/// selection lists. `compact` renders an inline icon+text row that fits
/// inside a Form section or card; the full-size `ContentUnavailableView`
/// variant is for page-level empty states with room to breathe.
struct StudyEmptyState: View {
    let title: String
    let systemImage: String
    var description: String?
    var actionTitle: String?
    var action: (() -> Void)?
    var compact = false

    var body: some View {
        if compact {
            compactBody
        } else {
            ContentUnavailableView {
                Label(title, systemImage: systemImage)
            } description: {
                if let description {
                    Text(description)
                }
            } actions: {
                if let actionTitle, let action {
                    Button(actionTitle, action: action)
                }
            }
        }
    }

    private var compactBody: some View {
        VStack(spacing: 6) {
            Label(title, systemImage: systemImage)
                .foregroundStyle(.secondary)
            if let description {
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.callout)
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
    }
}
