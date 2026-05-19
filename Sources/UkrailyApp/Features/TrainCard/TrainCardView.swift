import SwiftUI
import SwiftData

struct TrainCardView: View {

    @StateObject private var viewModel: TrainCardViewModel
    @Environment(\.modelContext) private var context

    init(serviceID: String) {
        _viewModel = StateObject(wrappedValue: TrainCardViewModel(serviceID: serviceID))
    }

    /// Preview / test initialiser with a pre-loaded mock service.
    init(previewService: TrainService) {
        _viewModel = StateObject(wrappedValue: TrainCardViewModel(previewService: previewService))
    }

    var body: some View {
        ZStack {
            Color.ukrailyBackground.ignoresSafeArea()

            Group {
                switch viewModel.loadState {
                case .idle:
                    Color.clear

                case .loading:
                    ProgressView("Loading train…")
                        .foregroundStyle(.secondary)

                case .loaded:
                    if let service = viewModel.service {
                        loadedContent(service: service)
                    }

                case .error(let error):
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundStyle(.orange)
                        Text(error.localizedDescription)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Retry") { Task { await viewModel.load(context: context) } }
                            .buttonStyle(.bordered)
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.toggleTracking(context: context)
                } label: {
                    Image(systemName: viewModel.isTracked ? "bell.fill" : "bell")
                        .symbolEffect(.bounce, value: viewModel.isTracked)
                }
            }
        }
        .task { await viewModel.load(context: context) }
    }

    // MARK: - Loaded state

    @ViewBuilder
    private func loadedContent(service: TrainService) -> some View {
        ZStack(alignment: .top) {
            ScrollView {
                VStack(spacing: 16) {
                    mainCard(service: service)
                    if !service.callingPoints.isEmpty {
                        callingPointsCard(service: service)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }

            // Live status banner overlays top of content
            if viewModel.bannerMessage != nil {
                LiveStatusBanner(message: $viewModel.bannerMessage)
                    .frame(height: 44)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: viewModel.bannerMessage != nil)
    }

    // MARK: - Main card

    private func mainCard(service: TrainService) -> some View {
        VStack(alignment: .leading, spacing: 16) {

            // Header: route + live dot
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(service.origin.crsCode)
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        Image(systemName: "arrow.right")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(service.destination.crsCode)
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                    }
                    Text("\(service.origin.name) → \(service.destination.name)")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text(service.operatorName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if !service.isCancelled {
                    PulsingDotView()
                        .frame(width: 30, height: 30)
                }
            }

            // Times
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Departs")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(service.scheduledDeparture, format: .dateTime.hour().minute())
                        .font(.title.bold().monospacedDigit())
                        .foregroundStyle(.white)
                }
                if let arr = service.scheduledArrival {
                    Spacer()
                    Image(systemName: "arrow.right").foregroundStyle(.secondary)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Arrives")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(arr, format: .dateTime.hour().minute())
                            .font(.title.bold().monospacedDigit())
                            .foregroundStyle(.white)
                    }
                }
            }

            // Countdown + delay + platform
            HStack {
                if !service.isCancelled {
                    CountdownLabel(targetDate: service.estimatedDeparture ?? service.scheduledDeparture)
                        .font(.title3.monospacedDigit())
                        .foregroundStyle(.ukrailyAccent)
                }
                DelayBadgeView(status: service.status)
                Spacer()
                if let platform = service.platform {
                    PlatformPill(platform: platform)
                }
            }

            // Progress scrubber (only shown while journey is in progress)
            if service.scheduledArrival != nil && !service.isCancelled {
                TrainCardProgressBar(service: service)
                    .frame(height: 10)
                    .padding(.vertical, 4)
            }

            StatusBadge(status: service.status)
        }
        .padding()
        .background(Color.ukrailyCard)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Calling points card

    private func callingPointsCard(service: TrainService) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Calling at")
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 8)

            let points = service.callingPoints
            ForEach(Array(points.enumerated()), id: \.element.id) { index, cp in
                CallingPointRow(
                    callingPoint: cp,
                    isFirst: index == 0,
                    isLast: index == points.count - 1
                )
                .padding(.horizontal)
                if index < points.count - 1 {
                    Divider()
                        .background(Color.white.opacity(0.06))
                        .padding(.leading, 34)
                }
            }
            .padding(.bottom, 16)
        }
        .background(Color.ukrailyCard)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Previews

#Preview("On time") {
    NavigationStack {
        TrainCardView(previewService: MockData.onTimeService)
            .modelContainer(for: [TrackedJourney.self, SavedStation.self], inMemory: true)
    }
}

#Preview("7 min delay") {
    NavigationStack {
        TrainCardView(previewService: MockData.delayedService)
            .modelContainer(for: [TrackedJourney.self, SavedStation.self], inMemory: true)
    }
}

#Preview("Cancelled") {
    NavigationStack {
        TrainCardView(previewService: MockData.cancelledService)
            .modelContainer(for: [TrackedJourney.self, SavedStation.self], inMemory: true)
    }
}
