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
            Text("Break it into milestones. Complete one day at a time.")
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
