import SwiftUI

struct PermissionPrimingStepView: View {
    @Bindable var model: OnboardingModel

    var body: some View {
        VStack(spacing: 28) {
            Image(systemName: "hand.raised")
                .font(.system(size: 40, weight: .medium))
                .foregroundStyle(.tint)

            VStack(spacing: 8) {
                Text("Before you begin")
                    .font(.largeTitle.bold())
                Text("Study Block may ask macOS for a couple of permissions while you set things up. Here's why.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 18) {
                permissionRow(
                    icon: "network",
                    title: "Automate Google Chrome",
                    detail: "Reads your open tabs' addresses to suggest study sites, and redirects blocked sites during a session. Only domains are kept — never page content — and only while you're setting up or a session is running."
                )
                permissionRow(
                    icon: "bell",
                    title: "Send notifications",
                    detail: "Lets Study Block tell you when a session finishes, even if the app isn't in front."
                )
            }
            .padding(20)
            .studySurface(cornerRadius: 16)
            .frame(maxWidth: 460)

            Text("If you turn on Do Not Disturb for sessions later, macOS will separately ask to check your Focus status and control the menu bar.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 460)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func permissionRow(
        icon: String,
        title: String,
        detail: String
    ) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
