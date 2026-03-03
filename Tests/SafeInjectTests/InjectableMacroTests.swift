import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

@testable import SafeInjectMacros

final class InjectableMacroTests: XCTestCase {

    let macros: [String: Macro.Type] = [
        "Injectable": InjectableMacro.self,
    ]

    func testExpandsWithInjectedProperties() {
        assertMacroExpansion(
            """
            @Injectable
            class HomeViewModel {
                @Injected var userService: UserServiceProtocol
                @Injected var analytics: AnalyticsProtocol
                @Published var items: [Item] = []
            }
            """,
            expandedSource: """
            class HomeViewModel {
                @Injected var userService: UserServiceProtocol
                @Injected var analytics: AnalyticsProtocol
                @Published var items: [Item] = []
            }

            extension HomeViewModel: Injectable {
                static var dependencies: [Any.Type] {
                    [UserServiceProtocol.self, AnalyticsProtocol.self]
                }
                static func _makeInstance() -> Any {
                    HomeViewModel()
                }
            }
            """,
            macros: macros
        )
    }

    func testExpandsWithNoInjectedProperties() {
        assertMacroExpansion(
            """
            @Injectable
            class SimpleViewModel {
                var name: String = ""
            }
            """,
            expandedSource: """
            class SimpleViewModel {
                var name: String = ""
            }

            extension SimpleViewModel: Injectable {
                static var dependencies: [Any.Type] {
                    []
                }
                static func _makeInstance() -> Any {
                    SimpleViewModel()
                }
            }
            """,
            macros: macros
        )
    }

    func testExpandsWithLazyInjected() {
        assertMacroExpansion(
            """
            @Injectable
            class ProfileViewModel {
                @LazyInjected var heavyService: HeavyServiceProtocol
            }
            """,
            expandedSource: """
            class ProfileViewModel {
                @LazyInjected var heavyService: HeavyServiceProtocol
            }

            extension ProfileViewModel: Injectable {
                static var dependencies: [Any.Type] {
                    [HeavyServiceProtocol.self]
                }
                static func _makeInstance() -> Any {
                    ProfileViewModel()
                }
            }
            """,
            macros: macros
        )
    }

    func testExpandsWithMultipleWrapperTypes() {
        assertMacroExpansion(
            """
            @Injectable
            class SettingsViewModel {
                @Injected var authService: AuthServiceProtocol
                @LazyInjected var imageLoader: ImageLoaderProtocol
                @WeakLazyInjected var coordinator: CoordinatorProtocol
                @OptionalInjected var featureFlags: FeatureFlagsProtocol
                @Published var isLoading = false
            }
            """,
            expandedSource: """
            class SettingsViewModel {
                @Injected var authService: AuthServiceProtocol
                @LazyInjected var imageLoader: ImageLoaderProtocol
                @WeakLazyInjected var coordinator: CoordinatorProtocol
                @OptionalInjected var featureFlags: FeatureFlagsProtocol
                @Published var isLoading = false
            }

            extension SettingsViewModel: Injectable {
                static var dependencies: [Any.Type] {
                    [AuthServiceProtocol.self, ImageLoaderProtocol.self, CoordinatorProtocol.self, FeatureFlagsProtocol.self]
                }
                static func _makeInstance() -> Any {
                    SettingsViewModel()
                }
            }
            """,
            macros: macros
        )
    }

    func testFailsOnStruct() {
        assertMacroExpansion(
            """
            @Injectable
            struct NotAClass {
                @Injected var service: ServiceProtocol
            }
            """,
            expandedSource: """
            struct NotAClass {
                @Injected var service: ServiceProtocol
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@Injectable can only be applied to classes",
                    line: 1,
                    column: 1
                ),
            ],
            macros: macros
        )
    }
}
