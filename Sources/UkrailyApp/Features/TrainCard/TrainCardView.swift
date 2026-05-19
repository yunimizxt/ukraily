import SwiftUI
import SwiftData
import UkrailyCore

struct TrainCardView: View {

    @StateObject private var viewModel: TrainCardViewModel
    @Environment(\.modelContext) private var context
    @State private var bannerMessage: String? = nil

    init(serviceID: String) {
        _viewModel = StateObject(wrappedValue: TrainCardViewModel(serviceID: serviceID))
    }

    var body: some View {
        ZStack {
            Color.ukrailyBackground.ignoresSafeArea()

            if let service = viewModel.service {
                ScrollView {
                    VStack(spacing: 16) {
                        mainCard(service: service)
                        callingPointsCard(service: service)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }

                // Live status banner (UIKit)
                VStack {
                    LiveStatusBanner(message: $bannerMessage)
                        .frame(height: 44)
                        .padding(.horizontal)
                        .padding(.top, 8)
                    Spacer()
                }
            } else if viewModel.loadState.isLoading {
                ProgressView("Loading train…")
                    .foregroundStyle(.secondary)
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
                }
            }
        }
        .task { await viewModel.load() }
    }

    // MARK: - Main card

    private func mainCard(service: TrainService) -> some View {
        VStack(alignment: .leading, spacing: 16) {

            // Header row: route + live dot
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
                PulsingDotView()
                    .frame(width: 30, height: 30)
            }

            // Time row
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
                    Image(systemName: "arrow.right")
                        .foregroundStyle(.secondary)
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

            // Countdown + delay badge
            HStack {
                CountdownLabel(targetDate: service.estimatedDeparture ?? service.scheduledDeparture)
                    .font(.title3.monospacedDigit())
                    .foregroundStyle(.ukrailyAccent)
                DelayBadgeView(status: service.status)
                Spacer()
                if let platform = service.platform {
                    PlatformPill(platform: platform)
                }
            }

            // Progress bar
            if service.scheduledArrival != nil {
                TrainCardProgressBar(service: service)
                    .frame(height: 10)
                    .padding(.vertical, 4)
            }

            // Status badge
            StatusBadge(status: service.status)
        }
        .padding()
        .background(Color.ukrailyCard)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Calling points

    private func callingPointsCard(service: TrainService) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Calling at")
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 8)

            ForEach(Array(service.callingPoints.enumerated()), id: \.element.id) { index, cp in
                CallingPointRow(
                    callingPoint: cp,
                    isFirst: index == 0,
                    isLast: index == service.callingPoints.count - 1
                )
                .padding(.horizontal)
                if index < service.callingPoints.count - 1 {
                    Divider().background(Color.white.opacity(0.06)).padding(.leading, 34)
                }
            }
            .padding(.bottom, 16)
        }
        .background(Color.ukrailyCard)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}
