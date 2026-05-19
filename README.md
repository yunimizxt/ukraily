# Ukraily

A UK Railway tracking app for iOS, inspired by [Flighty](https://www.flightyapp.com/).

Track live train journeys with real-time delays, platform changes, and departure countdowns.

## Features

- **Live departure boards** — search any UK station
- **Journey tracking** — Flighty-style animated train card
- **Push notifications** — delays, platform changes, cancellations
- **Home screen widgets** — next train at a glance (small, medium, lock screen)
- **Apple Watch** — glanceable journey status on your wrist

## Tech Stack

- Swift 5.9 + iOS 17+
- SwiftUI + UIKit hybrid
- Swift Package Manager
- SwiftData for persistence
- [Darwin OpenLDBWS](https://realtime.nationalrail.co.uk/OpenLDBWSRegistration/) for live train data
- Darwin Push Port (STOMP over WebSocket) for real-time updates

## Development Setup

### Requirements

- macOS 14+ with Xcode 15+
- VS Code with the [Swift extension](https://marketplace.visualstudio.com/items?itemName=sswg.swift-lang)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) for project generation

```bash
brew install xcodegen
```

### API Key

1. Register at https://realtime.nationalrail.co.uk/OpenLDBWSRegistration/
2. Copy the example config:
   ```bash
   cp DarwinAPIKey.xcconfig.example DarwinAPIKey.xcconfig
   ```
3. Paste your key into `DarwinAPIKey.xcconfig`

### Build

```bash
# Generate Xcode project (needed for device/simulator builds)
xcodegen generate

# Open in VS Code
code .

# Run unit tests (no simulator required)
swift test
```

## Project Structure

```
Sources/
├── UkrailyCore/       Shared business logic (networking, models, persistence)
├── UkrailyApp/        iOS app (SwiftUI + UIKit)
├── UkrailyWidgets/    WidgetKit home screen widget
└── UkrailyWatch/      Apple Watch companion app
Tests/
└── UkrailyCoreTests/  Unit tests
```

## Data Sources

- **Darwin OpenLDBWS** — Live Departure Boards SOAP API (free, requires registration)
- **Darwin Push Port v16** — Real-time train movement feed (STOMP/WebSocket)

Both provided by [Network Rail](https://www.networkrail.co.uk/who-we-are/our-data-and-the-rail-industry/open-data-feeds/).
