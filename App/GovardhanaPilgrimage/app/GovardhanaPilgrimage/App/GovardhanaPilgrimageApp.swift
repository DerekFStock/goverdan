import SwiftUI

@main
struct GovardhanaPilgrimageApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView(model: model)
        }
    }
}

