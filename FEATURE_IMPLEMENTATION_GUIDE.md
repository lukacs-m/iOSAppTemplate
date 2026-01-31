# Feature Implementation Guide

This guide explains how to implement new features in projects based on this iOS App Template. The template follows **Clean Architecture** with **MVVM** pattern, organized into four distinct layers.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        App Target                                │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                    DI Containers                         │    │
│  │  (RepositoriesContainer, ServicesContainer, Tooling)     │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     PresentationLayer                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐   │
│  │    Views     │  │  ViewModels  │  │      AppRouter       │   │
│  │  (SwiftUI)   │  │ (@Observable)│  │    (Navigation)      │   │
│  └──────────────┘  └──────────────┘  └──────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                       DomainLayer                                │
│  ┌──────────────────────┐  ┌────────────────────────────────┐   │
│  │      Use Cases       │  │    DomainLayerProtocols        │   │
│  │   (Business Logic)   │  │  (Repository/Service Protocols)│   │
│  └──────────────────────┘  └────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                        DataLayer                                 │
│  ┌──────────────────────┐  ┌────────────────────────────────┐   │
│  │    Repositories      │  │        API Clients             │   │
│  │  (Data Access)       │  │      (Networking)              │   │
│  └──────────────────────┘  └────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                       CommonLayer                                │
│  ┌──────────────────────┐  ┌────────────────────────────────┐   │
│  │       Errors         │  │          Models                │   │
│  │    (AppErrors)       │  │     (Shared Types)             │   │
│  └──────────────────────┘  └────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

---

## Layer Responsibilities

| Layer | Purpose | Contains |
|-------|---------|----------|
| **CommonLayer** | Foundation utilities shared across all layers | Error types, shared models, extensions |
| **DataLayer** | Data access and external communication | Repositories, API clients, database access |
| **DomainLayer** | Business logic and rules | Use cases, domain entities, protocols |
| **PresentationLayer** | User interface and interaction | Views, ViewModels, navigation, UI components |

---

## Implementing a New Feature

### Step 1: Define the Data Model (CommonLayer)

If your feature requires shared data types, add them to CommonLayer.

**Location:** `LocalLibraries/CommonLayer/Sources/CommonLayer/Models/`

```swift
// Example: User.swift
import Foundation

public struct User: Codable, Sendable, Hashable {
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
import Logr

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

    public func saveUser(_ user: User) async throws {
        try await apiClient.post(endpoint: .users, body: user)
    }

    public func deleteUser(id: String) async throws {
        try await apiClient.delete(endpoint: .user(id: id))
    }
}
```

### Step 4: Create Use Case (DomainLayer)

Encapsulate business logic in a use case.

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
        // Apply business rules (e.g., filtering, sorting)
        return users.sorted { $0.name < $1.name }
    }
}
```

### Step 5: Create ViewModel (PresentationLayer)

Create the ViewModel using `@Observable` macro.

**Location:** `LocalLibraries/PresentationLayer/Sources/PresentationLayer/Pages/[FeatureName]/`

```swift
// Example: UsersViewModel.swift
import CommonLayer
import DomainLayer
import Factory
import Observation

@Observable
@MainActor
public final class UsersViewModel {

    // MARK: - State

    public private(set) var users: [User] = []
    public private(set) var isLoading = false
    public private(set) var errorMessage: String?

    // MARK: - Dependencies

    @ObservationIgnored
    private let fetchUsersUseCase: FetchUsersUseCase

    // MARK: - Init

    public init(fetchUsersUseCase: FetchUsersUseCase) {
        self.fetchUsersUseCase = fetchUsersUseCase
    }

    // MARK: - Setup

    public func setUp() {
        Task {
            await loadUsers()
        }
    }

    // MARK: - Actions

    public func loadUsers() async {
        isLoading = true
        errorMessage = nil

        do {
            users = try await fetchUsersUseCase.execute()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    public func refresh() async {
        await loadUsers()
    }
}
```

### Step 6: Create View (PresentationLayer)

Create the SwiftUI view.

**Location:** `LocalLibraries/PresentationLayer/Sources/PresentationLayer/Pages/[FeatureName]/`

```swift
// Example: UsersView.swift
import CommonLayer
import SwiftUI

public struct UsersView: View {

    @State private var viewModel: UsersViewModel

    public init(viewModel: UsersViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else if let error = viewModel.errorMessage {
                errorView(message: error)
            } else {
                usersList
            }
        }
        .navigationTitle("Users")
        .task {
            viewModel.setUp()
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    // MARK: - Subviews

    private var usersList: some View {
        List(viewModel.users, id: \.id) { user in
            UserRowView(user: user)
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

### Step 7: Register Dependencies (App Target)

Register your new components in the DI containers.

**Location:** `iOSAppTemplate/App/DI/`

```swift
// RepositoriesContainer.swift
import DataLayer
import DomainLayerProtocols
import Factory

extension RepositoriesContainer {
    var userRepository: Factory<UserRepositoryProtocol> {
        self { UserRepository(apiClient: self.apiClient()) }
            .singleton
    }
}

// ServicesContainer.swift
import DomainLayer
import Factory

extension ServicesContainer {
    var fetchUsersUseCase: Factory<FetchUsersUseCase> {
        self {
            FetchUsersUseCase(
                repository: RepositoriesContainer.shared.userRepository()
            )
        }
        .singleton
    }
}
```

### Step 8: Add Navigation Route (PresentationLayer)

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
                    UsersView(viewModel: /* inject from container */)
                case .userDetail(let userId):
                    UserDetailView(userId: userId)
                }
            }
    }
}
```

### Step 9: Write Tests

Write tests for each layer.

**DataLayer Tests:** `LocalLibraries/DataLayer/Tests/DataLayerTests/`

```swift
import Testing
@testable import DataLayer

struct UserRepositoryTests {

    @Test
    func fetchUsers_returnsUsers() async throws {
        // Arrange
        let mockAPIClient = MockAPIClient()
        let repository = UserRepository(apiClient: mockAPIClient)

        // Act
        let users = try await repository.fetchAllUsers()

        // Assert
        #expect(users.count > 0)
    }
}
```

**DomainLayer Tests:** `LocalLibraries/DomainLayer/Tests/DomainLayerTests/`

```swift
import Testing
@testable import DomainLayer

struct FetchUsersUseCaseTests {

    @Test
    func execute_returnsSortedUsers() async throws {
        // Arrange
        let mockRepository = MockUserRepository()
        let useCase = FetchUsersUseCase(repository: mockRepository)

        // Act
        let users = try await useCase.execute()

        // Assert
        #expect(users == users.sorted { $0.name < $1.name })
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
    func loadUsers_updatesState() async {
        // Arrange
        let mockUseCase = MockFetchUsersUseCase()
        let viewModel = UsersViewModel(fetchUsersUseCase: mockUseCase)

        // Act
        await viewModel.loadUsers()

        // Assert
        #expect(viewModel.users.count > 0)
        #expect(viewModel.isLoading == false)
    }
}
```

---

## File Naming Conventions

| Type | Naming Pattern | Example |
|------|----------------|---------|
| Model | `[Name].swift` | `User.swift` |
| Protocol | `[Name]Protocol.swift` | `UserRepositoryProtocol.swift` |
| Repository | `[Name]Repository.swift` | `UserRepository.swift` |
| Use Case | `[Action][Entity]UseCase.swift` | `FetchUsersUseCase.swift` |
| ViewModel | `[Feature]ViewModel.swift` | `UsersViewModel.swift` |
| View | `[Feature]View.swift` | `UsersView.swift` |
| Tests | `[TestedType]Tests.swift` | `UserRepositoryTests.swift` |

---

## Feature Folder Structure

For a complete feature (e.g., "Users"), you would create/modify files in:

```
LocalLibraries/
├── CommonLayer/
│   └── Sources/CommonLayer/
│       └── Models/
│           └── User.swift                    # Data model
│
├── DomainLayer/
│   ├── Sources/DomainLayerProtocols/
│   │   └── Protocols/
│   │       └── UserRepositoryProtocol.swift  # Repository contract
│   └── Sources/DomainLayer/
│       └── UseCases/
│           └── FetchUsersUseCase.swift       # Business logic
│
├── DataLayer/
│   └── Sources/DataLayer/
│       └── Repositories/
│           └── UserRepository.swift          # Data access
│
└── PresentationLayer/
    └── Sources/PresentationLayer/
        └── Pages/
            └── Users/
                ├── UsersView.swift           # SwiftUI view
                └── UsersViewModel.swift      # View state

iOSAppTemplate/
└── App/
    └── DI/
        ├── RepositoriesContainer.swift       # Register repository
        └── ServicesContainer.swift           # Register use case
```

---

## Best Practices

### General

- Keep layers independent - lower layers should never import upper layers
- Use protocols for all cross-layer dependencies
- Mark all public types as `Sendable` for Swift 6 concurrency
- Use `@MainActor` for all UI-related code

### ViewModels

- Always provide a `setUp()` method for initial loading
- Keep state properties `private(set)` to enforce unidirectional data flow
- Use `@ObservationIgnored` for dependencies that shouldn't trigger view updates
- Handle all errors gracefully and expose user-friendly messages

### Views

- Call `viewModel.setUp()` in `.task` or `.onAppear`
- Keep views thin - business logic belongs in ViewModels
- Use composition for complex UIs
- Extract reusable components to `Shared/` folder

### Testing

- Use Apple's Testing framework (`@Test`, `#expect`)
- Write async tests for all async code
- Create mock implementations for protocols
- Test each layer independently

### Error Handling

- Define domain-specific errors in `CommonLayer/Errors/AppErrors.swift`
- Transform network/database errors to domain errors in repositories
- Present user-friendly error messages in ViewModels

---

## Quick Reference Checklist

When implementing a new feature:

- [ ] Define data models in CommonLayer (if needed)
- [ ] Define repository protocol in DomainLayerProtocols
- [ ] Implement repository in DataLayer
- [ ] Create use case in DomainLayer
- [ ] Create ViewModel in PresentationLayer
- [ ] Create View in PresentationLayer
- [ ] Register dependencies in DI containers
- [ ] Add navigation route (if needed)
- [ ] Write unit tests for each layer
- [ ] Run SwiftLint and SwiftFormat
- [ ] Run all tests via `fastlane unit_test`
