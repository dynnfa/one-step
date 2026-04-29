import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationSplitView {
            Text("One Step")
                .font(.headline)
                .padding()
        } detail: {
            Text("Create a long-term goal to begin.")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 860, minHeight: 560)
    }
}

#Preview {
    ContentView()
}
