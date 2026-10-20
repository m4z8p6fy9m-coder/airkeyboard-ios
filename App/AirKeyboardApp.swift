import SwiftUI
import UIKit

@main struct AirKeyboardApp: App {
    @StateObject private var model = AppModel()
    @AppStorage("appearance") private var appearance = "dark"
    var body: some Scene {
        WindowGroup {
            RootView().environmentObject(model)
                .preferredColorScheme(appearance == "system" ? nil : appearance == "light" ? .light : .dark)
                .tint(Color(uiColor: UIColor { traits in
                    UIColor(hex: traits.userInterfaceStyle == .dark ? "#83E5CE" : "#17695D")
                }))
        }
    }
}
