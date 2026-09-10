import SwiftUI

enum AppTheme {
    static let forest = Color(red: 0.055, green: 0.333, blue: 0.153)
    static let deepForest = Color(red: 0.025, green: 0.20, blue: 0.105)
    static let saffron = Color(red: 0.93, green: 0.65, blue: 0.16)
    static let coral = Color(red: 0.96, green: 0.39, blue: 0.29)
    static let canvas = Color(red: 0.985, green: 0.972, blue: 0.90)
    static let surface = Color(red: 1.0, green: 0.992, blue: 0.955)
}

struct RootView: View {
    @Bindable var model: AppModel

    var body: some View {
        NavigationStack(path: $model.navigationPath) {
            Group {
                if let errorMessage = model.errorMessage {
                    ContentUnavailableView(
                        "Content unavailable",
                        systemImage: "exclamationmark.triangle",
                        description: Text(errorMessage)
                    )
                } else {
                    HomeView(model: model)
                }
            }
            .navigationDestination(for: AppRoute.self) { route in
                DestinationView(route: route, model: model)
            }
        }
        .tint(AppTheme.forest)
        .toolbarBackground(AppTheme.canvas, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}
