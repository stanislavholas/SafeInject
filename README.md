# SafeInject

[![Swift 5.9+](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20watchOS-blue.svg)](https://developer.apple.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![CI](https://github.com/stanislavholas/SafeInject/actions/workflows/ci.yml/badge.svg)](https://github.com/stanislavholas/SafeInject/actions/workflows/ci.yml)

Compile-time and runtime validation for Swift dependency injection. Catch missing registrations **before** they crash in production.

SafeInject uses Swift Macros to automatically discover all injected dependencies and validate them in a single test, without any manual registration.

## The Problem

When using property wrapper-based DI (Resolver, Factory, etc.), the compiler has no way to verify that every `@Injected` dependency is actually registered. A missing registration silently compiles and then crashes at runtime:

```swift
class HomeViewModel: ObservableObject {
    @Injected var authService: AuthServiceProtocol // registered
    @Injected var analytics: AnalyticsProtocol     // forgot to register, crashes at runtime
}
```

## The Solution

Mark your view models with `@Injectable`. Write one test. Done.

```swift
@Injectable
class HomeViewModel: ObservableObject {
    @Injected var authService: AuthServiceProtocol
    @Injected var analytics: AnalyticsProtocol
}
```

```swift
func testAllDependenciesResolve() {
    AppDependencies.register()
    DependencyValidator.validateAll()
}
```

If `AnalyticsProtocol` isn't registered, the test fails immediately instead of crashing in production.

## Installation

### Swift Package Manager

Add SafeInject to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/stanislavholas/SafeInject.git", from: "1.0.0"),
]
```

Then add the products to your targets:

```swift
// App target
.target(
    name: "MyApp",
    dependencies: [
        .product(name: "SafeInject", package: "SafeInject"),
    ]
),

// Test target
.testTarget(
    name: "MyAppTests",
    dependencies: [
        .product(name: "SafeInjectTesting", package: "SafeInject"),
    ]
),
```

Or in Xcode: **File > Add Package Dependencies** and paste the repository URL.

## Usage

### 1. Annotate your view models

```swift
import SafeInject

@Injectable
class HomeViewModel: ObservableObject {
    @Injected var userService: UserServiceProtocol
    @Injected var analytics: AnalyticsProtocol
    @Published var items: [Item] = []
}

@Injectable
class ProfileViewModel: ObservableObject {
    @LazyInjected var imageLoader: ImageLoaderProtocol
    @Injected var authService: AuthServiceProtocol
}
```

The `@Injectable` macro:
- Scans for `@Injected`, `@LazyInjected`, `@WeakLazyInjected`, and `@OptionalInjected` properties
- Generates a list of dependency types
- Generates a factory method for instantiation-based testing
- Adds `Injectable` protocol conformance

### 2. Write one test

```swift
import XCTest
import SafeInjectTesting
@testable import MyApp

final class DependencyTests: XCTestCase {
    func testAllDependenciesResolve() {
        // Set up your DI container exactly like in your app
        AppDependencies.register()

        // Automatically finds every @Injectable class and instantiates it.
        // If any @Injected dependency is missing, the test fails.
        DependencyValidator.validateAll()
    }
}
```

That's it. Every `@Injectable` class in your module is automatically discovered at runtime and validated.

### 3. Run on CI

Add the test to your CI pipeline. Every new view model annotated with `@Injectable` is automatically included without any extra maintenance.

## How It Works

1. **`@Injectable` macro** generates an `Injectable` protocol conformance with:
   - `dependencies`: an array of all injected types (useful for debugging)
   - `_makeInstance()`: a factory that calls the class initializer, triggering all `@Injected` resolutions

2. **`DependencyValidator.discoverAll()`** uses the Objective-C runtime (`objc_copyClassList`) to find every loaded class conforming to `Injectable`. Fully automatic, no registration step.

3. **`DependencyValidator.validateAll()`** instantiates each discovered type. If the DI container can't resolve a dependency, the test fails with a clear stack trace pointing to the missing registration.

## API Reference

### `@Injectable`

```swift
@Injectable
class MyViewModel { ... }
```

Attach to any class that uses DI property wrappers. Generates `Injectable` conformance automatically.

> **Note:** Only works on classes (not structs). The compiler will emit an error if applied to a struct.

### `DependencyValidator`

| Method | Description |
|---|---|
| `validateAll()` | Discovers and instantiates all `@Injectable` types. Fails the test if any dependency is missing. |
| `discoverAll()` | Returns all `@Injectable` types found at runtime. Useful for custom validation logic. |

## Supported Property Wrappers

| Wrapper | Framework |
|---|---|
| `@Injected` | Resolver, Factory |
| `@LazyInjected` | Resolver, Factory |
| `@WeakLazyInjected` | Resolver |
| `@OptionalInjected` | Resolver |

## Requirements

- Swift 5.9+
- iOS 16+ / macOS 13+ / tvOS 16+ / watchOS 9+

## Author

Stanislav Holas

## License

MIT. See [LICENSE](LICENSE) for details.
