import SwiftUI
import SwiftData
import UkrailyCore

struct DepartureBoardView: View {

    @StateObject private var viewModel: DepartureBoardViewModel
    @EnvironmentObject private var coordinator: RootCoordinator
    @Environment(\.modelContext) private var context

    init(crs: String, stationName: String) {
        _viewModel = StateObject(wrappedValue: DepartureBoardViewModel(crs: crs, stationName: stationName))
    }

    var body: some View {
        ZStack {
            Color.ukrailyBackground.ignoresSafeArea()

            Group {
                switch viewModel.loadState {
                case .idle:
                    Color.clear.onAppear { Task { await viewModel.load() } }
                case .loading:
                    ProgressView("Loading departures…")
                        .foregroundStyle(.secondary)
                case .loaded:
                    boardList
                case .error(let error):
                    errorView(error)
                }
            }
        }
        .navigationTitle(viewModel.stationName)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Refresh") { Task { await viewModel.refresh() } }
                    .disabled(viewModel.loadState.isLoading)
            }
        }
        .refreshable { await viewModel.refresh() }
    }

    // MARK: - Subviews

    private var boardList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(viewModel.services) { service in
                    ServiceRowView(service: service) {
                        coordinator.push(.trainCard(serviceID: service.serviceID))
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }

    private func errorView(_ error: Error) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.orange)
            Text(error.localizedDescription)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("Try Again") { Task { await viewModel.refresh() } }
                .buttonStyle(.bordered)
        }
        .padding()
    }
}

struct ServiceRowView: View {

    let service: TrainService
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Time column
                VStack(alignment: .leading, spacing: 2) {
                    Text(service.scheduledDeparture, format: .dateTime.hour().minute())
                        .font(.title3.monospacedDigit().bold())
                        .foregroundStyle(.white)
                    if let estimated = service.estimatedDeparture,
                       estimated != service.scheduledDeparture {
                        Text(estimated, format: .dateTime.hour().minute())
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.orange)
                    }
                }
                .frame(width: 52, alignment: .leading)

                // Destination + operator
                VStack(alignment: .leading, spacing: 2) {
                    Text(service.destination.name)
                        .font(.body.bold())
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text(service.operatorName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Platform + status
                VStack(alignment: .trailing, spacing: 4) {
                    StatusBadge(status: service.status)
                    if let platform = service.platform {
                        PlatformPill(platform: platform)
                    }
                }
            }
            .padding()
            .background(Color.ukrailyCard)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}

// MARK: - Previews

private struct DepartureBoardPreviewViewModel: View {
    var body: some View {
        let vm = DepartureBoardViewModel(crs: "PAD", stationName: "London Paddington")
        let _ = {
            vm.services = [MockData.onTimeService, MockData.delayedService, MockData.cancelledService]
            vm.loadState = .loaded
        }()
        return DepartureBoardViewContent(viewModel: vm)
    }
}

// Extracted testable sub-view so preview doesn't require a live network call
private struct DepartureBoardViewContent: View {
    @ObservedObject var viewModel: DepartureBoardViewModel
    @StateObject private var coordinator = RootCoordinator()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ukrailyBackground.ignoresSafeArea()
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(viewModel.services) { service in
                            ServiceRowView(service: service) {}
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
            }
            .navigationTitle(viewModel.stationName)
        }
        .environmentObject(coordinator)
    }
}

#Preview("Departure board") {
    DepartureBoardViewContent(
        viewModel: {
            let vm = DepartureBoardViewModel(crs: "PAD", stationName: "London Paddington")
            vm.services = [MockData.onTimeService, MockData.delayedService, MockData.cancelledService]
            vm.loadState = .loaded
            return vm
        }()
    )
    .modelContainer(for: [TrackedJourney.self, SavedStation.self], inMemory: true)
}
