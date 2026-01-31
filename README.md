# [App Name]

[![iOS](https://img.shields.io/badge/iOS-18.0+-blue.svg)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-6.2-orange.svg)](https://swift.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

> Brief description of what the app does and its main value proposition.

---

## Table of Contents

- [Features](#features)
- [Screenshots](#screenshots)
- [Requirements](#requirements)
- [Installation](#installation)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Configuration](#configuration)
- [Testing](#testing)
- [Code Quality](#code-quality)
- [CI/CD](#cicd)
- [Contributing](#contributing)
- [License](#license)

---

## Features

- Feature 1: Brief description
- Feature 2: Brief description
- Feature 3: Brief description

---

## Screenshots

| Home | Feature A | Feature B |
|:----:|:---------:|:---------:|
| ![Home](docs/screenshots/home.png) | ![Feature A](docs/screenshots/feature-a.png) | ![Feature B](docs/screenshots/feature-b.png) |

---

## Requirements

| Requirement | Version |
|-------------|---------|
| iOS | 18.0+ |
| Xcode | 16.0+ |
| Swift | 6.2+ |
| macOS | Sonoma 14.0+ (for development) |

---

## Installation

### Prerequisites

1. **Xcode**: Download from the [Mac App Store](https://apps.apple.com/app/xcode/id497799835)
2. **Ruby** (for Fastlane): `brew install ruby`
3. **Bundler**: `gem install bundler`

### Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/[organization]/[repo-name].git
   cd [repo-name]
   ```

2. Install Ruby dependencies:
   ```bash
   bundle install
   ```

3. Open the project:
   ```bash
   open [ProjectName].xcodeproj
   ```

4. Build and run (Cmd + R)

### Starting from Template

If starting from the iOS App Template:

```bash
./scripts/init_project.sh
```

Follow the prompts to set your project name and bundle identifier.

---

## Architecture

This project follows **Clean Architecture** with **MVVM** pattern, organized into four modular Swift packages.

```
┌─────────────────────────────────────────────────────────────┐
│                      App Target                              │
│                  (DI Containers, Entry Point)                │
└──────────────────────────┬──────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────┐
│                   PresentationLayer                          │
│              (Views, ViewModels, Navigation)                 │
└──────────────────────────┬──────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────┐
│                     DomainLayer                              │
│               (Use Cases, Business Logic)                    │
└──────────────────────────┬──────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────┐
│                      DataLayer                               │
│             (Repositories, API Clients)                      │
└──────────────────────────┬──────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────┐
│                     CommonLayer                              │
│              (Shared Models, Utilities)                      │
└─────────────────────────────────────────────────────────────┘
```

### Key Patterns

| Pattern | Usage |
|---------|-------|
| **MVVM** | UI architecture with `@Observable` ViewModels |
| **Repository** | Data access abstraction |
| **Use Case** | Business logic encapsulation |
| **Dependency Injection** | Factory containers for loose coupling |
| **Protocol-Oriented** | Testability through protocol abstractions |

For detailed implementation guidelines, see [FEATURE_IMPLEMENTATION_GUIDE.md](FEATURE_IMPLEMENTATION_GUIDE.md).

---

## Project Structure

```
[ProjectName]/
├── [ProjectName]/                    # Main app target
│   ├── App/
│   │   ├── DI/                       # Dependency injection containers
│   │   │   ├── RepositoriesContainer.swift
│   │   │   ├── ServicesContainer.swift
│   │   │   └── ToolingContainer.swift
│   │   └── Resources/                # App assets
│   └── [ProjectName]App.swift        # App entry point
│
├── [ProjectName]Tests/               # Main app tests
│
├── LocalLibraries/                   # Swift packages
│   ├── CommonLayer/                  # Shared utilities
│   │   ├── Sources/
│   │   │   └── CommonLayer/
│   │   │       ├── Errors/           # Error types
│   │   │       └── Models/           # Shared models
│   │   └── Tests/
│   │
│   ├── DataLayer/                    # Data access
│   │   ├── Sources/
│   │   │   └── DataLayer/
│   │   │       ├── Repositories/     # Repository implementations
│   │   │       └── Network/          # API clients
│   │   └── Tests/
│   │
│   ├── DomainLayer/                  # Business logic
│   │   ├── Sources/
│   │   │   ├── DomainLayer/
│   │   │   │   └── UseCases/         # Use case implementations
│   │   │   └── DomainLayerProtocols/
│   │   │       └── Protocols/        # Repository protocols
│   │   └── Tests/
│   │
│   └── PresentationLayer/            # UI layer
│       ├── Sources/
│       │   └── PresentationLayer/
│       │       ├── Pages/            # Feature screens
│       │       ├── Routing/          # Navigation
│       │       ├── Shared/           # Reusable components
│       │       └── Resources/        # UI assets
│       └── Tests/
│
├── TestPlan/                         # Xcode test plans
├── scripts/                          # Build scripts
├── fastlane/                         # CI/CD configuration
│
├── .swiftlint.yml                    # Linting rules
├── .swiftformat                      # Formatting rules
├── .periphery.yml                    # Dead code detection
├── Gemfile                           # Ruby dependencies
└── README.md
```

---

## Configuration

### Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `API_BASE_URL` | Backend API base URL | Yes |
| `API_KEY` | API authentication key | Yes |

### Build Configurations

| Configuration | Purpose |
|--------------|---------|
| Debug | Development with debug symbols |
| Release | Production optimized build |

### Feature Flags

Configure feature flags in `[location]`:

```swift
// Example feature flag configuration
```

---

## Testing

### Running Tests

**All tests:**
```bash
fastlane unit_test
```

**Specific package:**
```bash
xcodebuild test -scheme CommonLayer -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

### Test Structure

| Layer | Test Location | Focus |
|-------|---------------|-------|
| Common | `CommonLayer/Tests/` | Models, utilities |
| Data | `DataLayer/Tests/` | Repositories, API |
| Domain | `DomainLayer/Tests/` | Use cases, logic |
| Presentation | `PresentationLayer/Tests/` | ViewModels |
| App | `[ProjectName]Tests/` | Integration |

### Test Coverage

Generate coverage report:
```bash
fastlane unit_test
# Coverage report in fastlane/tmp/
```

---

## Code Quality

### Linting

Run SwiftLint:
```bash
./scripts/run_swiftlint.sh
```

### Formatting

Run SwiftFormat:
```bash
./scripts/run_swiftformat.sh
```

### Dead Code Detection

Run Periphery:
```bash
periphery scan
```

### Pre-commit Checks

Before committing:
1. Run SwiftFormat
2. Run SwiftLint
3. Run all tests
4. Check for dead code

---

## CI/CD

### Fastlane Lanes

| Lane | Description |
|------|-------------|
| `unit_test` | Run all unit tests |
| `build` | Build the app |
| `beta` | Deploy to TestFlight |
| `release` | Deploy to App Store |

### GitHub Actions

Workflows configured in `.github/workflows/`:

- **PR Checks**: Lint, format, test on pull requests
- **Nightly**: Full test suite
- **Release**: App Store deployment

---

## API Documentation

### Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/resource` | Fetch resources |
| POST | `/api/v1/resource` | Create resource |
| PUT | `/api/v1/resource/{id}` | Update resource |
| DELETE | `/api/v1/resource/{id}` | Delete resource |

### Authentication

```
Authorization: Bearer <token>
```

---

## Dependencies

### Swift Packages

| Package | Version | Purpose |
|---------|---------|---------|
| [Factory](https://github.com/hmlongco/Factory) | develop | Dependency injection |
| [Logr](https://github.com/netsplit/logr) | 1.0.2+ | Logging |

### Development Tools

| Tool | Purpose |
|------|---------|
| SwiftLint | Code linting |
| SwiftFormat | Code formatting |
| Periphery | Dead code detection |
| Fastlane | CI/CD automation |

---

## Contributing

### Getting Started

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes
4. Run tests and linting
5. Commit: `git commit -m 'Add amazing feature'`
6. Push: `git push origin feature/amazing-feature`
7. Open a Pull Request

### Code Standards

- Follow [FEATURE_IMPLEMENTATION_GUIDE.md](FEATURE_IMPLEMENTATION_GUIDE.md)
- Ensure all tests pass
- Maintain code coverage
- Follow SwiftLint rules
- Write meaningful commit messages

### Pull Request Process

1. Update documentation if needed
2. Add tests for new functionality
3. Ensure CI passes
4. Request review from maintainers

---

## Troubleshooting

### Common Issues

**Build fails with missing package:**
```bash
File > Packages > Reset Package Caches
```

**Tests fail on CI:**
- Check simulator availability
- Verify Xcode version matches

**SwiftLint errors:**
```bash
./scripts/run_swiftformat.sh
./scripts/run_swiftlint.sh --fix
```

---

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for release history.

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Acknowledgments

- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html) by Robert C. Martin
- [Factory](https://github.com/hmlongco/Factory) by Michael Long
- iOS App Template contributors

---

## Contact

**Project Maintainer:** [Name] - [email@example.com]

**Project Link:** [https://github.com/[organization]/[repo-name]](https://github.com/[organization]/[repo-name])

---

<p align="center">
  Made with care for iOS development
</p>
