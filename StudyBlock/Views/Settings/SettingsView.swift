import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            SitesSettingsView()
                .tabItem {
                    Label("Sites", systemImage: "globe")
                }

            SessionSettingsView()
                .tabItem {
                    Label("Sessions", systemImage: "timer")
                }

            StatsSettingsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar")
                }

            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
        }
        .padding(20)
    }
}
