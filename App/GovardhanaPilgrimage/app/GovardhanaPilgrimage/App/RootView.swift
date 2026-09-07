import SwiftUI

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
                    HomeView(stories: model.stories, works: model.works, storyPosition: model.storyPosition)
                }
            }
            .navigationDestination(for: AppRoute.self) { route in
                DestinationView(route: route, model: model)
            }
        }
    }
}
