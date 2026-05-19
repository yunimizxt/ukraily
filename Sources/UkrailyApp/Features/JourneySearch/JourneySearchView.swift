import SwiftUI

struct JourneySearchView: View {

    let originCRS: String
    let destinationCRS: String

    @StateObject private var viewModel: JourneySearchViewModel
    @EnvironmentObject private var coordinator: RootCoordinator

    init(originCRS: String, destinationCRS: String) {
        self.originCRS = originCRS
        self.destinationCRS = destinationCRS
        _viewModel = StateObject(wrappedValue: JourneySearchViewModel(originCRS: originCRS, destinationCRS: destinationCRS))
    }

    var body: some View {
        ZStack {
            Color.ukrailyBackground.ignoresSafeArea()

            Group {
                switch viewModel.loadState {
                case .idle:
                    Color.clear.onAppear { Task { await viewModel.search() } }
                case .loading:
                    ProgressView("Searching…").foregroundStyle(.secondary)
                case .loaded:
                    if viewModel.services.isEmpty {
                        Text("No trains found for this journey.")
                            .foregroundStyle(.secondary)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 10) {
                                ForEach(viewModel.services) { service in
                                    ServiceRowView(service: service) {
                                        coordinator.push(.trainCard(serviceID: service.serviceID))
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                case .error(let e):
                    Text(e.localizedDescription).foregroundStyle(.red).padding()
                }
            }
        }
        .navigationTitle("\(originCRS) → \(destinationCRS)")
    }
}

@MainActor
final class JourneySearchViewModel: ObservableObject {
    @Published var services: [TrainService] = []
    @Published var loadState: LoadState = .idle

    let originCRS: String
    let destinationCRS: String

    init(originCRS: String, destinationCRS: String) {
        self.originCRS = originCRS
        self.destinationCRS = destinationCRS
    }

    func search() async {
        loadState = .loading
        do {
            services = try await JourneyRepository.shared.searchJourneys(from: originCRS, to: destinationCRS)
            loadState = .loaded
        } catch {
            loadState = .error(error)
        }
    }
}
