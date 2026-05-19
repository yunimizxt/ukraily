import SwiftUI

@MainActor
final class RootCoordinator: ObservableObject {

    @Published var path: [AppRoute] = []

    func push(_ route: AppRoute) {
        path.append(route)
    }

    func pop() {
        _ = path.popLast()
    }

    func popToRoot() {
        path.removeAll()
    }

    func navigate(to route: AppRoute) {
        path = [route]
    }
}
