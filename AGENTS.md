# AGENTS.md

## Project Overview

CacheKit is a lightweight, thread-safe disk caching library for Apple platforms (iOS, macOS, tvOS, visionOS). It provides a simple and efficient way to cache `Codable` data, commonly used for storing network response data.

**Key Features:**
- Thread-safe using Swift's Actor model
- Support for both in-memory and disk caching
- Automatic cache expiration
- Generic type support for any `Codable` type

## Tech Stack

- **Language:** Swift 5.9+
- **Package Manager:** Swift Package Manager (SPM)
- **Platforms:** macOS 11+, iOS 13+, tvOS 13+, visionOS 1+
- **Documentation:** DocC

## Project Structure

```
CacheKit11/
├── Package.swift              # SPM manifest
├── Sources/
│   └── CacheKit/
│       ├── Cache.swift           # Cache protocol definition
│       ├── CacheEntry.swift      # Cache entry model
│       ├── CacheImplementation.swift  # InMemoryCache & DiskCache
│       ├── KeysTracker.swift     # NSCacheDelegate for tracking keys
│       └── CacheKit.docc/        # DocC documentation
├── Tests/
│   └── CacheTests/
│       └── CacheTests.swift      # Unit tests
├── .docs/                        # Generated documentation
└── .github/workflows/            # CI/CD workflows
```

## Setup Commands

```bash
# Clone and navigate to project
cd CacheKit11

# Build the project
swift build

# Build for release
swift build -c release
```

## Testing Instructions

```bash
# Run all tests
swift test

# Run tests with verbose output
swift test --verbose

# Run specific test
swift test --filter CacheKitTests
```

- Ensure all tests pass before committing changes
- Add or update tests for any new functionality
- Test on multiple platforms when possible

## Build Documentation

```bash
# Generate DocC documentation
./build-docc.sh

# Or manually
swift package generate-documentation
```

## Code Style Guidelines

- Use Swift's native naming conventions (camelCase for variables/functions, PascalCase for types)
- All public APIs must have documentation comments using `///` format
- Use Swift's Actor model for thread safety
- Prefer protocol-oriented design
- Use generics where appropriate
- Keep functions small and focused
- Use `Codable` for serialization

## Architecture

The caching system follows a protocol-oriented design:

1. **`Cache` Protocol** - Base protocol defining caching operations (Actor-based for thread safety)
2. **`NSCacheType` Protocol** - Extension with NSCache-based implementation
3. **`InMemoryCache`** - In-memory only cache implementation
4. **`DiskCache`** - Persistent disk cache with in-memory caching layer
5. **`CacheEntry`** - Wrapper for cached values with expiration timestamp
6. **`KeysTracker`** - NSCacheDelegate to track cache keys

## Common Tasks

### Adding a New Feature
1. Define the protocol/interface first
2. Implement the feature with proper Actor isolation
3. Add documentation comments
4. Write unit tests
5. Update DocC documentation if needed

### Modifying Cache Behavior
- Cache implementations are in `CacheImplementation.swift`
- Respect the Actor model for thread safety
- Ensure expiration logic is maintained

## PR Instructions

- Title format: `[CacheKit] <Brief description>`
- Ensure all tests pass: `swift test`
- Build successfully: `swift build`
- Update documentation for API changes
- Follow existing code style

## Security Considerations

- Cache files are stored in the app's sandboxed directory
- Sensitive data should be encrypted before caching
- Consider cache expiration for security-sensitive data
- The library does not handle encryption - implement at the application level if needed

## Dependencies

This project has **no external dependencies**. It only uses Apple's Foundation framework.
