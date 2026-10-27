import SwiftUI

@main
struct MyApp: App {
    @State private var env = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(env)
                .preferredColorScheme(env.preferredColorScheme)
                .environment(\.layoutDirection, env.isRTL ? .rightToLeft : .leftToRight)
                .onOpenURL { url in
                    env.handleURL(url)
                }
        }
    }
}
