# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

iOS App Template using **Clean Architecture + MVVM**, built with **Swift 6.2**, targeting **iOS 18.0+**. The project is organized into 4 local Swift packages under `LocalLibraries/` plus a thin App target.

## Build & Test Commands

```bash
# Run all unit tests via Fastlane (preferred)
fastlane unit_test

# Run tests for a specific package directly
xcodebuild test -scheme CommonLayer -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
xcodebuild test -scheme DataLayer -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
xcodebuild test -scheme DomainLayer -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
xcodebuild test -scheme PresentationLayer -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# Lint and format
./scripts/run_swiftlint.sh
./scripts/run_swiftformat.sh

# Dead code detection
periphery scan
```

## Architecture

### Layer Hierarchy and Dependencies

```
App Target (thin shell — only @main, imports PresentationLayer, renders MainView())
    ↓
PresentationLayer (main orchestrating layer)
    ├── Views (SwiftUI), ViewModels (@Observable), AppRouter (navigation)
    ├── DI Containers (Factory: RepositoriesContainer, ServicesContainer, ToolingContainer)
    ├── imports: CommonLayer, DataLayer, DomainLayer, FactoryKit
    ↓
DomainLayer
    ├── UseCases/ — stateless single business operations
    ├── StateManagers/ — @Observable final class objects holding live app state
    ├── DomainLayerProtocols (separate target) — repository/service protocol contracts
    ├── imports: CommonLayer, DataLayer
    ↓
DataLayer
    ├── Repositories, API clients
    ├── imports: CommonLayer, DomainLayerProtocols
    ↓
CommonLayer
    └── Shared models, error types (AppErrors), extensions
```

### Key Architectural Decisions

**DI containers live in PresentationLayer, not the App target.** PresentationLayer has visibility into all layers and wires everything up. The App target is a minimal shell — adding a new feature requires zero changes to it.

**DomainLayer has two kinds of objects:**
- **Use Cases** — stateless, encapsulate a single operation (fetch, create, delete), return results
- **StateManagers** — `@Observable final class`, hold the live source of truth for a domain concern (e.g., user list, search results). Registered as singletons so all screens share the same instance. SwiftUI views automatically redraw when StateManager properties change.

**ViewModels are thin coordinators** — they connect a view to StateManagers/use cases, they do not duplicate state that lives in a StateManager.

**Navigation** uses `AppRouter` (`@Observable`) with `NavigationPath` for stack navigation, plus `SheetDestination` and `FullScreenDestination` enums for modals. Views apply routing via `.routingProvided`, `.sheetDestinations(_:)`, `.fullScreenDestination(_:)`.

### Swift 6 Concurrency

All four packages use identical Swift settings:
- `defaultIsolation: MainActor.self` — everything is MainActor-isolated by default
- `InferIsolatedConformances` and `NonisolatedNonsendingByDefault` upcoming features enabled
- All public types should be `Sendable`

## Conventions

- **Testing framework:** Swift Testing (`@Test`, `#expect`) — not XCTest
- **DI library:** Factory (imported as `FactoryKit`), containers use `SharedContainer` + `AutoRegistering`, default scope is `.singleton`
- **Observation:** Use Swift `@Observable` macro (not Combine's `ObservableObject`)
- **ViewModels:** `@Observable final class`, dependencies marked `@ObservationIgnored`, state properties `private(set)`
- **Views:** Receive ViewModel via `@State private var viewModel`, call `viewModel.setUp()` in `.task`
- **File naming:** `[Entity]StateManager.swift`, `[Action][Entity]UseCase.swift`, `[Feature]ViewModel.swift`, `[Feature]View.swift`, `[Name]RepositoryProtocol.swift`
- **DI registration:** Add as extensions on existing containers in `PresentationLayer/DI/` (e.g., `ServicesContainer+User.swift`)
- **Line length:** 150 warning, 200 error (SwiftLint); max width 150 (SwiftFormat)
- **Indent:** 4 spaces
- **SwiftLint enforces:** `sorted_imports`, `implicit_return`, no `AnyView`, no `foregroundColor` (use `foregroundStyle`), no `nonisolated func ... async` (use `@concurrent`)

## Feature Implementation Path

See `FEATURE_IMPLEMENTATION_GUIDE.md` for the full step-by-step guide. The short version:

1. Model in `CommonLayer/Models/`
2. Protocol in `DomainLayerProtocols/Protocols/`
3. Repository in `DataLayer/Repositories/`
4. Use Case in `DomainLayer/UseCases/`
5. StateManager in `DomainLayer/StateManagers/`
6. ViewModel + View in `PresentationLayer/Pages/[FeatureName]/`
7. DI registration in `PresentationLayer/DI/`
8. Route in `AppRouter.swift` (if needed)
9. Tests per layer
