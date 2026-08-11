import SwiftUI
import UptoCore

// How the presence appears next to your name in a server member list.
struct MemberListRowView: View {
    let displayName: String
    let statusText: String

    var body: some View {
        HStack(spacing: 8) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(LinearGradient(colors: [.indigo, .purple], startPoint: .top, endPoint: .bottom))
                    .frame(width: 32, height: 32)
                Circle()
                    .fill(.green)
                    .frame(width: 10, height: 10)
                    .overlay(Circle().stroke(Color(red: 0.169, green: 0.176, blue: 0.192), lineWidth: 2))
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(displayName)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.white)
                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(1)
                    .connectorTarget(.memberListStatus)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color(red: 0.169, green: 0.176, blue: 0.192), in: RoundedRectangle(cornerRadius: 10))
    }
}
