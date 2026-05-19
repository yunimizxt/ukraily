import SwiftUI
import SwiftData

struct HomeView: View {

    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var coordinator = RootCoordinator()
    @Query(sort: \SavedStation.addedAt, order: .reverse) private var savedStations: [SavedStation]
    @Query(
        filter: #Predicate<TrackedJourney> { $0.isActive },
        sort: \TrackedJourney.scheduledDeparture
    ) private var activeJourneys: [TrackedJourney]

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            ZStack {
                Color.ukrailyBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        headerSection
                        if !activeJourneys.isEmpty {
                            trackedJourneysSection
                        }
                        if !savedStations.isEmpty {
                            savedStationsSection
                        }
                        quickSearchSection
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .navigationDestination(for: AppRoute.self) { route in
                destinationView(for: route)
            }
            .searchable(
                text: $viewModel.searchQuery,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search stations"
            )
            .onChange(of: viewModel.searchQuery) { _, query in
                viewModel.updateSearch(query)
            }
            .onReceive(NotificationCenter.default.publisher(for: .openJourney)) { note in
                if let id = note.object as? UUID,
                   let journey = activeJourneys.first(where: { $0.id == id }) {
                    coordinator.push(.trainCard(serviceID: journey.serviceID))
                }
            }
        }
        .environmentObject(coordinator)
    }

    // MARK: - Subviews

    private var headerSection: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Ukraily")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                Text("UK Railway, live.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 16) {
                Button {
                    coordinator.push(.trackedJourneys)
                } label: {
                    Image(systemName: activeJourneys.isEmpty ? "tram" : "tram.fill")
                        .font(.title3)
                        .foregroundStyle(activeJourneys.isEmpty ? Color.secondary : Color.ukrailyAccent)
                        .overlay(alignment: .topTrailing) {
                            if !activeJourneys.isEmpty {
                                Text("\(activeJourneys.count)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(3)
                                    .background(Color.ukrailyAccent)
                                    .clipShape(Circle())
                                    .offset(x: 6, y: -6)
                            }
                        }
                }
                Button {
                    coordinator.push(.settings)
                } label: {
                    Image(systemName: "gearshape")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.top, 12)
    }

    private var trackedJourneysSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("My Trains")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(activeJourneys) { journey in
                        TrackedJourneyChip(journey: journey) {
                            coordinator.push(.trainCard(serviceID: journey.serviceID))
                        }
                    }
                }
            }
        }
    }

    private var savedStationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Saved Stations")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(savedStations) { saved in
                        StationChip(station: saved.station) {
                            coordinator.push(.departureBoard(crs: saved.crsCode, name: saved.name))
                        }
                    }
                }
            }
        }
    }

    private var quickSearchSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(viewModel.searchQuery.isEmpty ? "Popular Stations" : "Results")
            let results: [Station] = viewModel.searchQuery.isEmpty
                ? [.londonPaddington, .londonKingsCross, .londonWaterloo, .manchester, .bristol]
                : viewModel.searchResults
            ForEach(results) { station in
                StationRow(station: station) {
                    coordinator.push(.departureBoard(crs: station.crsCode, name: station.name))
                }
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(.white)
    }

    @ViewBuilder
    private func destinationView(for route: AppRoute) -> some View {
        switch route {
        case .departureBoard(let crs, let name):
            DepartureBoardView(crs: crs, stationName: name)
        case .trainCard(let serviceID):
            TrainCardView(serviceID: serviceID)
        case .trackedJourneys:
            TrackedJourneysView()
        case .journeySearch(let originCRS, let destinationCRS):
            JourneySearchView(originCRS: originCRS, destinationCRS: destinationCRS)
        case .settings:
            SettingsView()
        }
    }
}

// MARK: - Tracked journey chip

struct TrackedJourneyChip: View {
    let journey: TrackedJourney
    let action: () -> Void

    private var statusColor: Color {
        if journey.lastStatusRaw == 2 { return .red }
        if journey.lastKnownDelayMinutes > 0 { return .orange }
        return .green
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 7, height: 7)
                    Text(journey.scheduledDeparture, format: .dateTime.hour().minute())
                        .font(.caption.bold().monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                Text("\(journey.originName.components(separatedBy: " ").first ?? journey.originCRS)")
                    .font(.footnote.bold())
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Image(systemName: "arrow.down")
                    .font(.system(size: 8))
                    .foregroundStyle(.secondary)
                Text("\(journey.destinationName.components(separatedBy: " ").first ?? journey.destinationCRS)")
                    .font(.footnote.bold())
                    .foregroundStyle(.white)
                    .lineLimit(1)
                if let platform = journey.lastKnownPlatform {
                    PlatformPill(platform: platform)
                }
                if journey.lastKnownDelayMinutes > 0 {
                    Text("+\(journey.lastKnownDelayMinutes) min")
                        .font(.caption2.bold())
                        .foregroundStyle(.orange)
                }
            }
            .frame(width: 90)
            .padding(12)
            .background(Color.ukrailyCard)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}

// MARK: - Small Components

struct StationChip: View {
    let station: Station
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 2) {
                Text(station.crsCode)
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Text(station.name.components(separatedBy: " ").prefix(2).joined(separator: " "))
                    .font(.footnote.bold())
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.ukrailyCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

struct StationRow: View {
    let station: Station
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(station.name)
                        .font(.body.bold())
                        .foregroundStyle(.white)
                    Text(station.crsCode)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(Color.ukrailyCard)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}

extension Color {
    static let ukrailyBackground = Color(red: 0.07, green: 0.07, blue: 0.10)
    static let ukrailyCard       = Color(red: 0.13, green: 0.13, blue: 0.18)
    static let ukrailyAccent     = Color(red: 0.20, green: 0.60, blue: 1.00)
}

// MARK: - Previews

#Preview {
    HomeView()
        .modelContainer(for: [TrackedJourney.self, SavedStation.self], inMemory: true)
}
