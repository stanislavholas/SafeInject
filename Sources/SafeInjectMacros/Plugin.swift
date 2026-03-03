import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct SafeInjectPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        InjectableMacro.self,
    ]
}
