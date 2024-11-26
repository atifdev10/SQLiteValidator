import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct SQLiteValidatorPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        SQLQueryMacro.self,
    ]
}
