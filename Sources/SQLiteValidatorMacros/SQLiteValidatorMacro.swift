import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import MacroToolkit

enum SQLQueryError: Error, CustomStringConvertible {
    case notLiteral
    case incompleteQuery
    case tableNotSpecified
    case unknownKeyword(String)
    
    var description: String {
        switch self {
        case .notLiteral: return "The input must be string literal"
        case .incompleteQuery: return "Query incomplete"
        case .tableNotSpecified: return "Table not specified in query"
        case .unknownKeyword(let keyword):            
            return "Keyword '\(keyword)' not found"
        }
    }
}

public struct SQLQueryMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {
        let argumentList = node.arguments.map(\.expression)
        let query = argumentList.first!
        
        guard let query = query.as(StringLiteralExprSyntax.self) else {
            throw SQLQueryError.notLiteral
        }
        do {
            let formattedQuery = try formatQuery(query, node: node)
            try diagnoseSQL(query: formattedQuery)
        } catch let error as Diagnostic {
            context.diagnose(error)
            return ""
        } catch { throw error }
        
        guard node.macroName.text != "sqlQueryUnsafe" else { return "\(query)" }
        let queryString = try! formatQuery(query, node: node).lowercased()
        
        if queryString.hasPrefix("drop") {
            
            let diagnostic = DiagnosticBuilder(for: node)
                .message("Dropping the table may be dangerous")
                .suggestReplacement("Mark it unsafe to mute this warning", old: node.macroName._syntaxNode, new: TokenSyntax(stringLiteral: "sqlQueryUnsafe"))
                .severity(.warning)
                .build()
            
            context.diagnose(diagnostic)
        }
        
        return "\(query)"
    }
}

@main
struct SQLiteValidatorPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        SQLQueryMacro.self,
    ]
}
