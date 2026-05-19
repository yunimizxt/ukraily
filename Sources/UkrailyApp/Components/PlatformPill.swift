import SwiftUI

struct PlatformPill: View {

    let platform: String
    var changed: Bool = false

    var body: some View {
        HStack(spacing: 3) {
            Text("Plt")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(platform)
                .font(.caption.bold())
                .foregroundStyle(changed ? .orange : .white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(changed ? Color.orange.opacity(0.2) : Color.white.opacity(0.1))
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(changed ? Color.orange.opacity(0.5) : Color.white.opacity(0.15), lineWidth: 1))
    }
}
