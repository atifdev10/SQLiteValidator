import SQLite3
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

enum SQLQueryError: Error, CustomStringConvertible {
    case notLiteral

    var description: String {
        switch self {
        case .notLiteral: return "Query must be a string literal"
        }
    }
}

public struct SQLQueryMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {
        let query = node.arguments
            .map(\.expression)
            .first!

        guard let query = query.as(StringLiteralExprSyntax.self) else {
            throw SQLQueryError.notLiteral
        }

        let formattedQuery = query.segments
            .map(convertSegmentsToString)
            .joined()
            .lowercased()

        if let error = diagnoseSQL(formattedQuery) {
            parseErrorMessage(error, node: node, context: context)
        }

        guard node.macroName.text != "sqlQueryUnsafe" && formattedQuery.hasPrefix("drop") else {
            return "\(query)"
        }

        let diagnostic = DiagnosticBuilder(for: node.syntax)
            .message("Dropping the table may be dangerous")
            .suggestReplacement(
                "Mark it unsafe to mute this warning",
                old: node.macroName.syntax,
                new: TokenSyntax(stringLiteral: "sqlQueryUnsafe")
            )
            .severity(.warning)
            .build()

        context.diagnose(diagnostic)

        return "\(query)"
    }

    private static func convertSegmentsToString(_ segment: StringLiteralSegmentListSyntax.Element) -> String {
        if let string = segment.as(StringSegmentSyntax.self) { return string.content.text }
        if segment.as(ExpressionSegmentSyntax.self) != nil { return "some_name" }
        return ""
    }
}

func diagnoseSQL(_ query: String) -> String? {
    var errorPointer: UnsafeMutablePointer<CChar>?
    var db: OpaquePointer?

    sqlite3_open(":memory:", &db)
    sqlite3_exec(db, query, nil, nil, &errorPointer)
    sqlite3_close(db)

    guard let errorPointer else { return nil }

    let errorMessage = String(cString: errorPointer)
    sqlite3_free(errorPointer)

    return errorMessage
}

func parseErrorMessage(
    _ error: String,
    node: some FreestandingMacroExpansionSyntax,
    context: some MacroExpansionContext
) {
    let diagnostic: Diagnostic

    switch error {
    case error where error.hasPrefix("no tables specified"):
        diagnostic = DiagnosticBuilder(for: node.syntax)
            .message("Query incomplete")
            .messageID(domain: "SQLiteValidatorMacros", id: "Query")
            .severity(.error)
            .build()

    case error where error.hasPrefix("incomplete"):
        diagnostic = DiagnosticBuilder(for: node.syntax)
            .message("Table not specified in query")
            .messageID(domain: "SQLiteValidatorMacros", id: "Query")
            .severity(.error)
            .build()

    case var error where error.hasPrefix("near"):
        error.removeFirst(6)
        error = error.components(separatedBy: ":")[0]
        error.removeLast()

        diagnostic = DiagnosticBuilder(for: node.syntax)
            .message("Keyword '\(error)' not found")
            .messageID(domain: "SQLiteValidatorMacros", id: "Query")
            .severity(.error)
            .build()

    default:
        return
    }

    context.diagnose(diagnostic)
}

extension SyntaxProtocol {
    var syntax: Syntax {
        Syntax(self)
    }
}
