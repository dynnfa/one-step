import SwiftUI

struct EmptyStateView: View {
    let onCreate: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "target")
                .font(.system(size: 44, weight: .regular))
                .foregroundStyle(.tint)
            Text("Start with one long-term goal.")
                .font(.title2.bold())
            Text("Pick a daily action you can honestly confirm from the desktop.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
            Button("Create Goal", action: onCreate)
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
