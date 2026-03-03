import XCTest
import ObjectiveC
import SafeInject

/// Automatically discovers and validates all `@Injectable` types.
///
/// Uses the Objective-C runtime to find every class conforming to ``Injectable``
/// at runtime, without any manual registration.
///
/// ## Usage
///
/// ```swift
/// import XCTest
/// import SafeInjectTesting
/// @testable import MyApp
///
/// final class DependencyTests: XCTestCase {
///     func testAllDependenciesResolve() {
///         AppDependencies.register() // setup your DI container
///         DependencyValidator.validateAll()
///     }
/// }
/// ```
public enum DependencyValidator {

    /// All `@Injectable` types discovered at runtime.
    ///
    /// Uses `objc_copyClassList` to scan every loaded class
    /// and filters for ``Injectable`` conformance.
    public static func discoverAll() -> [any Injectable.Type] {
        var count: UInt32 = 0
        guard let classes = objc_copyClassList(&count) else { return [] }
        defer { free(UnsafeMutableRawPointer(classes)) }

        return (0..<Int(count)).compactMap { index in
            classes[index] as? any Injectable.Type
        }
    }

    /// Instantiates every discovered `@Injectable` type.
    ///
    /// Each instantiation triggers all `@Injected` property wrapper resolutions.
    /// If a dependency is missing from the DI container, the framework's
    /// resolution failure (typically `fatalError`) will cause the test to fail
    /// with a clear stack trace pointing to the unregistered dependency.
    ///
    /// - Parameters:
    ///   - file: Source file for failure reporting.
    ///   - line: Source line for failure reporting.
    public static func validateAll(
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let types = discoverAll()

        guard !types.isEmpty else {
            XCTFail(
                "No @Injectable types found. "
                + "Make sure to import the module containing your @Injectable types.",
                file: file,
                line: line
            )
            return
        }

        for type in types {
            _ = type._makeInstance()
        }
    }
}
