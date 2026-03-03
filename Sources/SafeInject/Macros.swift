/// Marks a class for automatic dependency validation.
///
/// The macro scans for properties annotated with common DI property wrappers
/// (`@Injected`, `@LazyInjected`, `@WeakLazyInjected`, `@OptionalInjected`)
/// and generates ``Injectable`` protocol conformance with a list of dependency types
/// and a factory method for instantiation-based testing.
///
/// ## Usage
///
/// ```swift
/// @Injectable
/// class HomeViewModel: ObservableObject {
///     @Injected var userService: UserServiceProtocol
///     @Injected var analytics: AnalyticsProtocol
/// }
/// ```
///
/// ## What gets generated
///
/// ```swift
/// extension HomeViewModel: Injectable {
///     static var dependencies: [Any.Type] {
///         [UserServiceProtocol.self, AnalyticsProtocol.self]
///     }
///     static func _makeInstance() -> Any {
///         HomeViewModel()
///     }
/// }
/// ```
@attached(extension, conformances: Injectable, names: named(dependencies), named(_makeInstance))
public macro Injectable() = #externalMacro(module: "SafeInjectMacros", type: "InjectableMacro")
