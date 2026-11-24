import SwiftUI

struct ContentView: View {
    @StateObject private var store = AppStore()

    var body: some View {
        RootView(store: store)
            .environmentObject(store)
            .tint(JYColor.primary)
    }
}

#Preview {
    ContentView()
}
