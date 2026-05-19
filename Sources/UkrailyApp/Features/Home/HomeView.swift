import SwiftUI
import SwiftData
import UkrailyCore

struct HomeView: View {

    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var coordinator = RootCoordinator()
    @Query(sort: \SavedStation.addedAt, order: .reverse)
    private var savedStations: [SavedStation]

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            ZStack {
                Color.ukrailyBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        headerSection
                        if !savedStations.isEmpty {
                            savedStationsSection
                        }
                        quickSearchSection
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .navigationDestination(for: AppRoute.self) { route in
                destinationView(for: route)
            }
            .searchable(text: $viewModel.searchQuery, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search stations")
            .onChange(of: viewModel.searchQuery) { _, query in
                viewModel.updateSearch(query)
            }
        }
        .environmentObject(coordinator)
    }

    // MARK: - Subviews

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Ukraily")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)
            Text("UK Railway, live.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 12)
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
            let results = viewModel.searchQuery.isEmpty
                ? [Station.londonPaddington, .londonKingsCross, .londonWaterloo, .manchester, .bristol]
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
