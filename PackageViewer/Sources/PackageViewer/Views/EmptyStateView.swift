import SwiftUI

struct EmptyStateView: View {
    let message: String
    let icon: String?

    init(message: String, icon: String? = nil) {
        self.message = message
        self.icon = icon
    }

    var body: some View {
        VStack(spacing: 16) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)
            }

            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
