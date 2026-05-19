import SwiftUI
import UserNotifications

struct SettingsView: View {

    @AppStorage("notif.preDeparture") private var preDeparture = true
    @AppStorage("notif.delays") private var delays = true
    @AppStorage("notif.platformChange") private var platformChange = true
    @AppStorage("notif.cancellations") private var cancellations = true

    @State private var authStatus: UNAuthorizationStatus = .notDetermined

    var body: some View {
        ZStack {
            Color.ukrailyBackground.ignoresSafeArea()
            List {
                if authStatus == .denied {
                    Section {
                        Label("Notifications are disabled for Ukraily in Settings.", systemImage: "bell.slash")
                            .foregroundStyle(.orange)
                            .font(.footnote)
                        Button("Open Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                    }
                }

                Section("Notifications") {
                    Toggle("Departure reminders (T-30, T-10)", isOn: $preDeparture)
                    Toggle("Delay alerts (5 / 15 / 30 min)", isOn: $delays)
                    Toggle("Platform change alerts", isOn: $platformChange)
                    Toggle("Cancellation alerts", isOn: $cancellations)
                }

                Section("Data") {
                    LabeledContent("Live data", value: "National Rail · Darwin")
                    LabeledContent("Real-time feed", value: "Darwin Push Port v16")
                }

                Section("About") {
                    LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Settings")
        .task { await checkAuthStatus() }
    }

    private func checkAuthStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run { authStatus = settings.authorizationStatus }
    }
}

// MARK: - User preferences helpers

extension UserDefaults {
    static var notificationsEnabled: (preDeparture: Bool, delays: Bool, platformChange: Bool, cancellations: Bool) {
        (
            preDeparture:   standard.bool(forKey: "notif.preDeparture"),
            delays:         standard.bool(forKey: "notif.delays"),
            platformChange: standard.bool(forKey: "notif.platformChange"),
            cancellations:  standard.bool(forKey: "notif.cancellations")
        )
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
