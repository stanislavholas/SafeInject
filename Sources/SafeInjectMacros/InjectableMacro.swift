import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

// MARK: - Macro Implementation

public struct InjectableMacro: ExtensionMacro {

    /// Property wrapper names recognized as dependency injection markers.
    /// Covers Resolver, Factory, and other common DI frameworks.
    private static let knownWrappers: Set<String> = [
        "Injected",
        "LazyInjected",
        "WeakLazyInjected",
        "OptionalInjected",
    ]

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard declaration.is(ClassDeclSyntax.self) else {
            context.diagnose(
                Diagnostic(node: node, message: InjectableDiagnostic.classOnly)
            )
            return []
        }

        let injectedTypes = extractInjectedTypes(from: declaration)
        let dependencyList = injectedTypes.joined(separator: ", ")

        let ext: DeclSyntax = """
        extension \(type.trimmed): Injectable {
            static var dependencies: [Any.Type] {
                [\(raw: dependencyList)]
            }
            static func _makeInstance() -> Any {
                \(type.trimmed)()
            }
        }
        """

        guard let extensionDecl = ext.as(ExtensionDeclSyntax.self) else {
            return []
        }

        return [extensionDecl]
    }

    // MARK: - Private Helpers

    private static func extractInjectedTypes(from declaration: some DeclGroupSyntax) -> [String] {
        declaration.memberBlock.members.compactMap { member -> String? in
            guard let varDecl = member.decl.as(VariableDeclSyntax.self) else { return nil }
            guard hasInjectedAttribute(varDecl) else { return nil }
            guard let binding = varDecl.bindings.first,
                  let typeAnnotation = binding.typeAnnotation?.type else { return nil }
            return "\(typeAnnotation.trimmed).self"
        }
    }

    private static func hasInjectedAttribute(_ varDecl: VariableDeclSyntax) -> Bool {
        varDecl.attributes.contains { element in
            guard case .attribute(let attr) = element else { return false }
            let name = attr.attributeName.trimmedDescription
            return knownWrappers.contains(name)
        }
    }
}

// MARK: - Diagnostics

enum InjectableDiagnostic: String, DiagnosticMessage {
    case classOnly

    var message: String {
        switch self {
        case .classOnly:
            return "@Injectable can only be applied to classes"
        }
    }

    var diagnosticID: MessageID {
        MessageID(domain: "SafeInject", id: rawValue)
    }

    var severity: DiagnosticSeverity { .error }
}
