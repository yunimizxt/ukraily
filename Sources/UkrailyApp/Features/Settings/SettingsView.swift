import SwiftUI

struct SettingsView: View {
    var body: some View {
        ZStack {
            Color.ukrailyBackground.ignoresSafeArea()
            List {
                Section("Notifications") {
                    Toggle("Departure reminders", isOn: .constant(true))
                    Toggle("Delay alerts", isOn: .constant(true))
                    Toggle("Platform change alerts", isOn: .constant(true))
                }
                Section("About") {
                    LabeledContent("Version", value: "1.0.0")
                    LabeledContent("Data", value: "National Rail / Darwin")
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Settings")
    }
}
