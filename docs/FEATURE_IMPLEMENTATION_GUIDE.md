# Feature Implementation Guide

This guide explains how to implement new features in projects based on this iOS App Template. The template follows **Clean Architecture** with **MVVM** pattern, organized into four distinct layers where the **PresentationLayer is the central orchestrating layer** and the App target is a thin container.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                      App Target (Thin Shell)                    │
│                                                                 │
│   Only @main entry point — imports PresentationLayer            │
│   and renders MainView(). No logic, no DI, no configuration.   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                PresentationLayer (Main Layer)                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐  │
│  │    Views      │  │  ViewModels  │  │      AppRouter       │  │
│  │  (SwiftUI)    │  │ (@Observable)│  │    (Navigation)      │  │
│  └──────────────┘  └──────────────┘  └──────────────────────┘  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    DI Containers                         │   │
│  │  (RepositoriesContainer, ServicesContainer, Tooling)     │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                       DomainLayer                               │
│  ┌──────────────────────┐  ┌────────────────────────────────┐  │
│  │      Use Cases        │  │       StateManagers            │  │
│  │   (Business Logic)    │  │  (@Observable final class)     │  │
│  └──────────────────────┘  └────────────────────────────────┘  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                 DomainLayerProtocols                      │   │
│  │            (Repository/Service Protocols)                 │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                        DataLayer                                │
│  ┌──────────────────────┐  ┌────────────────────────────────┐  │
│  │    Repositories       │  │        API Clients             │  │
│  │  (Data Access)        │  │      (Networking)              │  │
│  └──────────────────────┘  └────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                       CommonLayer                               │
│  ┌──────────────────────┐  ┌────────────────────────────────┐  │
│  │       Errors          │  │          Models                │  │
│  │    (AppErrors)        │  │     (Shared Types)             │  │
│  └──────────────────────┘  └────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Layer Responsibilities

| Layer | Purpose | Contains |
|-------|---------|----------|
| **App Target** | Thin shell, only the `@main` entry point | `iOSAppTemplateApp.swift` — imports PresentationLayer and renders `MainView()` |
| **PresentationLayer** | Main orchestrating layer — UI, DI, navigation | Views, ViewModels, DI containers, navigation, UI components |
| **DomainLayer** | Business logic, state management, and rules | Use cases, StateManagers (`@Observable`), domain protocols |
| **DataLayer** | Data access and external communication | Repositories, API clients, database access |
| **CommonLayer** | Foundation utilities shared across all layers | Error types, shared models, extensions |

### Why DI lives in PresentationLayer

The PresentationLayer is the **highest-level library** that has visibility into all other layers. Since it imports `DataLayer`, `DomainLayer`, and `CommonLayer`, it is the natural place to wire up the dependency injection containers. The App target remains a minimal shell — it only imports `PresentationLayer` and launches the root view, with zero knowledge of how dependencies are assembled.

### StateManagers vs. Use Cases

The DomainLayer contains two complementary types of objects:

- **Use Cases** — Stateless objects that encapsulate a single business operation (e.g., fetch, create, delete). They take inputs, call repositories, apply business rules, and return results.
- **StateManagers** — `@Observable final class` objects that **hold and manage the live state** of a specific domain concern (e.g., all users, the current search results, user preferences). Because they are `@Observable`, any SwiftUI view or ViewModel that references a StateManager's properties will **automatically redraw** when the data changes. This ensures all screens stay in sync with the latest data without manual refresh logic.

---

## Implementing a New Feature

### Step 1: Define the Data Model (CommonLayer)

If your feature requires shared data types, add them to CommonLayer.

**Location:** `LocalLibraries/CommonLayer/Sources/CommonLayer/Models/`

```swift
// Example: User.swift
import Foundation

public struct User: Codable, Sendable, Hashable, Identifiable {
    public let id: String
    public let name: String
    public let email: String

    public init(id: String, name: String, email: String) {
        self.id = id
        self.name = name
        self.email = email
    }
}
```

### Step 2: Define Repository Protocol (DomainLayerProtocols)

Define the contract for data access in the protocols target.

**Location:** `LocalLibraries/DomainLayer/Sources/DomainLayerProtocols/Protocols/`

```swift
// Example: UserRepositoryProtocol.swift
import CommonLayer

public protocol UserRepositoryProtocol: Sendable {
    func fetchUser(id: String) async throws -> User
    func fetchAllUsers() async throws -> [User]
    func searchUsers(query: String) async throws -> [User]
    func saveUser(_ user: User) async throws
    func deleteUser(id: String) async throws
}
```

### Step 3: Implement Repository (DataLayer)

Implement the actual data access logic.

**Location:** `LocalLibraries/DataLayer/Sources/DataLayer/Repositories/`

```swift
// Example: UserRepository.swift
import CommonLayer
import DomainLayerProtocols

public final class UserRepository: UserRepositoryProtocol, Sendable {
    private let apiClient: APIClientProtocol

    public init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }

    public func fetchUser(id: String) async throws -> User {
        try await apiClient.request(endpoint: .user(id: id))
    }

    public func fetchAllUsers() async throws -> [User] {
        try await apiClient.request(endpoint: .users)
    }

    public func searchUsers(query: String) async throws -> [User] {
        try await apiClient.request(endpoint: .searchUsers(query: query))
    }

    public func saveUser(_ user: User) async throws {
        try await apiClient.post(endpoint: .users, body: user)
    }

    public func deleteUser(id: String) async throws {
        try await apiClient.delete(endpoint: .user(id: id))
    }
}
```

### Step 4: Create Use Case (DomainLayer)

Use cases encapsulate a **single stateless business operation**. They call repositories, apply business rules, and return results.

**Location:** `LocalLibraries/DomainLayer/Sources/DomainLayer/UseCases/`

```swift
// Example: FetchUsersUseCase.swift
import CommonLayer
import DomainLayerProtocols

public final class FetchUsersUseCase: Sendable {
    private let repository: UserRepositoryProtocol

    public init(repository: UserRepositoryProtocol) {
        self.repository = repository
    }

    public func execute() async throws -> [User] {
        let users = try await repository.fetchAllUsers()
        return users.sorted { $0.name < $1.name }
    }
}
```

### Step 5: Create StateManager (DomainLayer)

StateManagers are `@Observable final class` objects that **own and manage the live state** for a domain concern. Because they are `@Observable`, any SwiftUI view or ViewModel referencing their properties will automatically redraw when data changes. This keeps every screen in sync without manual refresh logic.

**Location:** `LocalLibraries/DomainLayer/Sources/DomainLayer/StateManagers/`

```swift
// Example: UserStateManager.swift
import CommonLayer
import DomainLayerProtocols
import Foundation

@Observable
public final class UserStateManager {

    // MARK: - Published State

    /// All loaded users — any view reading this property redraws when it changes.
    public private(set) var users: [User] = []

    /// Current search results — separate from the full list so both can coexist.
    public private(set) var searchResults: [User] = []

    /// The active search query. Setting this triggers a search.
    public var searchQuery: String = "" {
        didSet {
            guard searchQuery != oldValue else { return }
            Task { await performSearch() }
        }
    }

    /// Loading flags
    public private(set) var isLoading = false
    public private(set) var isSearching = false

    /// Error state
    public private(set) var errorMessage: String?

    // MARK: - Dependencies

    @ObservationIgnored
    private let repository: UserRepositoryProtocol

    // MARK: - Init

    public init(repository: UserRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Actions

    /// Loads all users from the repository and updates the state.
    /// Every view that reads `users` will automatically redraw.
    public func loadAllUsers() async {
        isLoading = true
        errorMessage = nil

        do {
            users = try await repository.fetchAllUsers()
                .sorted { $0.name < $1.name }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /// Searches users based on the current `searchQuery`.
    /// Every view that reads `searchResults` will automatically redraw.
    public func performSearch() async {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !query.isEmpty else {
            searchResults = []
            return
        }

        isSearching = true

        do {
            searchResults = try await repository.searchUsers(query: query)
        } catch {
            errorMessage = error.localizedDescription
            searchResults = []
        }

        isSearching = false
    }

    /// Removes a user from the local state after successful deletion.
    public func deleteUser(id: String) async {
        do {
            try await repository.deleteUser(id: id)
            users.removeAll { $0.id == id }
            searchResults.removeAll { $0.id == id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
```

**Key points about StateManagers:**

- They are **`@Observable final class`** — SwiftUI tracks individual property access and redraws only the views that read changed properties.
- They **hold the source of truth** for a domain concern. Multiple ViewModels and views can share the same StateManager instance, keeping data in sync across screens.
- They use **`@ObservationIgnored`** on dependencies (repositories, use cases) so that injected objects do not trigger spurious view updates.
- They are registered as **singletons** in the DI container so every screen gets the same instance.
- **Search** is implemented directly in the StateManager: setting `searchQuery` triggers `performSearch()`, and any view reading `searchResults` or `isSearching` redraws automatically.

### Step 6: Create ViewModel (PresentationLayer)

ViewModels are thin coordinators that connect a specific **view** to domain-layer StateManagers and use cases. They expose only what a particular screen needs.

**Location:** `LocalLibraries/PresentationLayer/Sources/PresentationLayer/Pages/[FeatureName]/`

```swift
// Example: UsersViewModel.swift
import DomainLayer
import FactoryKit

@Observable
final class UsersViewModel {

    // MARK: - State Manager (shared domain state)

    let userState: UserStateManager

    // MARK: - Init

    init(userState: UserStateManager) {
        self.userState = userState
    }

    // MARK: - Setup

    func setUp() {
        Task {
            await userState.loadAllUsers()
        }
    }

    // MARK: - Actions

    func refresh() async {
        await userState.loadAllUsers()
    }

    func delete(userId: String) async {
        await userState.deleteUser(id: userId)
    }
}
```

Because `UserStateManager` is `@Observable`, the ViewModel does not need to duplicate state. The view can read `viewModel.userState.users`, `viewModel.userState.isLoading`, etc., and SwiftUI will track those properties and redraw automatically.

### Step 7: Create View (PresentationLayer)

Create the SwiftUI view. The view reads state from the StateManager through the ViewModel.

**Location:** `LocalLibraries/PresentationLayer/Sources/PresentationLayer/Pages/[FeatureName]/`

```swift
// Example: UsersView.swift
import CommonLayer
import SwiftUI

struct UsersView: View {

    @State private var viewModel: UsersViewModel

    init(viewModel: UsersViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.userState.isLoading {
                ProgressView()
            } else if let error = viewModel.userState.errorMessage {
                errorView(message: error)
            } else {
                usersList
            }
        }
        .navigationTitle("Users")
        .searchable(text: $viewModel.userState.searchQuery)
        .task {
            viewModel.setUp()
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var usersList: some View {
        let displayedUsers = viewModel.userState.searchQuery.isEmpty
            ? viewModel.userState.users
            : viewModel.userState.searchResults

        if viewModel.userState.isSearching {
            ProgressView("Searching...")
        } else if displayedUsers.isEmpty && !viewModel.userState.searchQuery.isEmpty {
            ContentUnavailableView.search(text: viewModel.userState.searchQuery)
        } else {
            List(displayedUsers) { user in
                UserRowView(user: user)
                    .swipeActions {
                        Button(role: .destructive) {
                            Task { await viewModel.delete(userId: user.id) }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
    }

    private func errorView(message: String) -> some View {
        ContentUnavailableView(
            "Error",
            systemImage: "exclamationmark.triangle",
            description: Text(message)
        )
    }
}
```

Notice how the `.searchable` modifier is bound directly to `$viewModel.userState.searchQuery`. When the user types, the StateManager's `didSet` observer fires `performSearch()`, which updates `searchResults`, and SwiftUI redraws the list — all automatically.

### Step 8: Register Dependencies in DI Containers (PresentationLayer)

DI containers live in the **PresentationLayer**, not the App target. Register your new components as extensions on the existing containers.

**Location:** `LocalLibraries/PresentationLayer/Sources/PresentationLayer/DI/`

```swift
// RepositoriesContainer+User.swift
import DataLayer
import DomainLayerProtocols
import FactoryKit

extension RepositoriesContainer {
    var userRepository: Factory<UserRepositoryProtocol> {
        self { UserRepository(apiClient: self.apiClient()) }
            .singleton
    }
}
```

```swift
// ServicesContainer+User.swift
import DomainLayer
import FactoryKit

extension ServicesContainer {
    var fetchUsersUseCase: Factory<FetchUsersUseCase> {
        self {
            FetchUsersUseCase(
                repository: RepositoriesContainer.shared.userRepository()
            )
        }
        .singleton
    }

    var userStateManager: Factory<UserStateManager> {
        self {
            UserStateManager(
                repository: RepositoriesContainer.shared.userRepository()
            )
        }
        .singleton  // Singleton ensures all screens share the same state
    }
}
```

**Why singleton for StateManagers?** Because the StateManager holds the live source of truth. Every ViewModel and view that uses `UserStateManager` must get the **same instance** so that a change on one screen (e.g., deleting a user) is immediately reflected on all other screens.

### Step 9: Add Navigation Route (PresentationLayer)

Update the router if the feature needs navigation.

**Location:** `LocalLibraries/PresentationLayer/Sources/PresentationLayer/Routing/AppRouter.swift`

```swift
// Add to RouterDestination enum
public enum RouterDestination: Hashable {
    case empty
    case users
    case userDetail(userId: String)
}

// Add view builder in routingProvided modifier
extension View {
    @ViewBuilder
    func routingProvided(router: AppRouter) -> some View {
        self
            .navigationDestination(for: RouterDestination.self) { destination in
                switch destination {
                case .empty:
                    EmptyView()
                case .users:
                    UsersView(
                        viewModel: UsersViewModel(
                            userState: ServicesContainer.shared.userStateManager()
                        )
                    )
                case .userDetail(let userId):
                    UserDetailView(userId: userId)
                }
            }
    }
}
```

### Step 10: Write Tests

Write tests for each layer.

**DataLayer Tests:** `LocalLibraries/DataLayer/Tests/DataLayerTests/`

```swift
import Testing
@testable import DataLayer

struct UserRepositoryTests {

    @Test
    func fetchUsers_returnsUsers() async throws {
        let mockAPIClient = MockAPIClient()
        let repository = UserRepository(apiClient: mockAPIClient)

        let users = try await repository.fetchAllUsers()

        #expect(users.count > 0)
    }
}
```

**DomainLayer Tests — Use Case:** `LocalLibraries/DomainLayer/Tests/DomainLayerTests/`

```swift
import Testing
@testable import DomainLayer

struct FetchUsersUseCaseTests {

    @Test
    func execute_returnsSortedUsers() async throws {
        let mockRepository = MockUserRepository()
        let useCase = FetchUsersUseCase(repository: mockRepository)

        let users = try await useCase.execute()

        #expect(users == users.sorted { $0.name < $1.name })
    }
}
```

**DomainLayer Tests — StateManager:** `LocalLibraries/DomainLayer/Tests/DomainLayerTests/`

```swift
import Testing
@testable import DomainLayer

@MainActor
struct UserStateManagerTests {

    @Test
    func loadAllUsers_updatesState() async {
        let mockRepository = MockUserRepository()
        let stateManager = UserStateManager(repository: mockRepository)

        await stateManager.loadAllUsers()

        #expect(!stateManager.users.isEmpty)
        #expect(stateManager.isLoading == false)
        #expect(stateManager.errorMessage == nil)
    }

    @Test
    func performSearch_updatesSearchResults() async {
        let mockRepository = MockUserRepository()
        let stateManager = UserStateManager(repository: mockRepository)

        stateManager.searchQuery = "John"
        // Allow the Task in didSet to execute
        try? await Task.sleep(for: .milliseconds(100))

        #expect(!stateManager.searchResults.isEmpty)
        #expect(stateManager.isSearching == false)
    }

    @Test
    func deleteUser_removesFromBothLists() async {
        let mockRepository = MockUserRepository()
        let stateManager = UserStateManager(repository: mockRepository)
        await stateManager.loadAllUsers()
        let userId = stateManager.users.first!.id

        await stateManager.deleteUser(id: userId)

        #expect(!stateManager.users.contains { $0.id == userId })
    }
}
```

**PresentationLayer Tests:** `LocalLibraries/PresentationLayer/Tests/PresentationLayerTests/`

```swift
import Testing
@testable import PresentationLayer

@MainActor
struct UsersViewModelTests {

    @Test
    func setUp_loadsUsers() async {
        let mockRepository = MockUserRepository()
        let stateManager = UserStateManager(repository: mockRepository)
        let viewModel = UsersViewModel(userState: stateManager)

        viewModel.setUp()
        // Allow the Task to execute
        try? await Task.sleep(for: .milliseconds(100))

        #expect(!viewModel.userState.users.isEmpty)
    }
}
```

---

## How Search Works with StateManagers

The StateManager pattern makes search straightforward and automatically reactive. Here is the flow:

```
User types in .searchable bar
         │
         ▼
searchQuery property is set on UserStateManager
         │
         ▼
didSet observer fires → calls performSearch()
         │
         ▼
Repository.searchUsers(query:) is called
         │
         ▼
searchResults property is updated
         │
         ▼
SwiftUI detects change → redraws all views reading searchResults
```

**No manual wiring needed.** Because `UserStateManager` is `@Observable`:
- Any view reading `searchResults` redraws when results arrive.
- Any view reading `isSearching` shows/hides a loading indicator automatically.
- If another screen also reads `searchResults`, it stays in sync too.

For **local/client-side filtering** instead of a server search, the StateManager can filter the existing `users` array:

```swift
// Alternative: client-side search in the StateManager
public var filteredUsers: [User] {
    guard !searchQuery.isEmpty else { return users }
    return users.filter {
        $0.name.localizedCaseInsensitiveContains(searchQuery) ||
        $0.email.localizedCaseInsensitiveContains(searchQuery)
    }
}
```

This computed property is also tracked by `@Observable` — SwiftUI redraws whenever `searchQuery` or `users` changes.

---

## File Naming Conventions

| Type | Naming Pattern | Example |
|------|----------------|---------|
| Model | `[Name].swift` | `User.swift` |
| Protocol | `[Name]Protocol.swift` | `UserRepositoryProtocol.swift` |
| Repository | `[Name]Repository.swift` | `UserRepository.swift` |
| Use Case | `[Action][Entity]UseCase.swift` | `FetchUsersUseCase.swift` |
| StateManager | `[Entity]StateManager.swift` | `UserStateManager.swift` |
| ViewModel | `[Feature]ViewModel.swift` | `UsersViewModel.swift` |
| View | `[Feature]View.swift` | `UsersView.swift` |
| DI Extension | `[Container]+[Feature].swift` | `ServicesContainer+User.swift` |
| Tests | `[TestedType]Tests.swift` | `UserStateManagerTests.swift` |

---

## Feature Folder Structure

For a complete feature (e.g., "Users"), you would create/modify files in:

```
LocalLibraries/
├── CommonLayer/
│   └── Sources/CommonLayer/
│       └── Models/
│           └── User.swift                         # Data model
│
├── DomainLayer/
│   ├── Sources/DomainLayerProtocols/
│   │   └── Protocols/
│   │       └── UserRepositoryProtocol.swift       # Repository contract
│   ├── Sources/DomainLayer/
│   │   ├── UseCases/
│   │   │   └── FetchUsersUseCase.swift            # Stateless business operation
│   │   └── StateManagers/
│   │       └── UserStateManager.swift             # Live state management
│   └── Tests/DomainLayerTests/
│       ├── FetchUsersUseCaseTests.swift
│       └── UserStateManagerTests.swift
│
├── DataLayer/
│   └── Sources/DataLayer/
│       └── Repositories/
│           └── UserRepository.swift               # Data access
│
└── PresentationLayer/
    └── Sources/PresentationLayer/
        ├── DI/
        │   ├── RepositoriesContainer+User.swift   # Register repository
        │   └── ServicesContainer+User.swift        # Register use case + state manager
        └── Pages/
            └── Users/
                ├── UsersView.swift                # SwiftUI view
                └── UsersViewModel.swift           # View coordinator

iOSAppTemplate/
└── iOSAppTemplateApp.swift                        # Thin shell — no changes needed
```

Note: The App target does **not** need any changes when adding a new feature. All wiring happens in PresentationLayer.

---

## Best Practices

### General

- Keep layers independent — lower layers should never import upper layers
- Use protocols for all cross-layer dependencies
- Mark all public types as `Sendable` for Swift 6 concurrency
- Use `@MainActor` for all UI-related code

### StateManagers

- Register as **singletons** so all screens share the same live state
- Keep state properties `private(set)` — only the StateManager mutates its own state
- Use `@ObservationIgnored` on injected dependencies to avoid spurious redraws
- Implement search directly in the StateManager so results are shared across screens
- Expose computed properties for derived/filtered data — `@Observable` tracks these automatically
- Keep them focused on **one domain concern** (e.g., users, products, settings)

### ViewModels

- ViewModels are **thin coordinators** — they connect a specific view to StateManagers and use cases
- Do not duplicate state that already lives in a StateManager
- Provide a `setUp()` method for initial loading
- Delegate data mutations to the StateManager

### Views

- Call `viewModel.setUp()` in `.task` or `.onAppear`
- Bind `.searchable` directly to the StateManager's `searchQuery` through the ViewModel
- Keep views thin — business logic belongs in StateManagers and use cases
- Use composition for complex UIs
- Extract reusable components to `Shared/` folder

### DI Containers

- All DI containers live in **PresentationLayer/DI/** — not in the App target
- Use **extensions** on existing containers to register new dependencies per feature
- StateManagers must be registered as `.singleton` to ensure shared state
- Use cases can be `.singleton` or `.unique` depending on whether they hold state

### Testing

- Use Apple's Testing framework (`@Test`, `#expect`)
- Write async tests for all async code
- Create mock implementations for protocols
- Test StateManagers thoroughly — they hold the core state logic
- Test each layer independently

### Error Handling

- Define domain-specific errors in `CommonLayer/Errors/AppErrors.swift`
- Transform network/database errors to domain errors in repositories
- Present user-friendly error messages via StateManager's `errorMessage` property

---

## Quick Reference Checklist

When implementing a new feature:

- [ ] Define data models in CommonLayer (if needed)
- [ ] Define repository protocol in DomainLayerProtocols
- [ ] Implement repository in DataLayer
- [ ] Create use case in DomainLayer (if needed for stateless operations)
- [ ] Create StateManager in DomainLayer (for live state management)
- [ ] Create ViewModel in PresentationLayer
- [ ] Create View in PresentationLayer
- [ ] Register dependencies in DI containers (PresentationLayer/DI/)
- [ ] Add navigation route (if needed)
- [ ] Write unit tests for each layer (especially StateManager)
- [ ] Run SwiftLint and SwiftFormat
- [ ] Run all tests via `fastlane unit_test`
