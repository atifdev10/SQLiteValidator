import SwiftSyntax
import SwiftDiagnostics
import MacroToolkit
import SQLite3

func diagnoseSQL(query: String) throws {
    var errorPointer: UnsafeMutablePointer<CChar>?
    var db: OpaquePointer?
    
    defer {
        sqlite3_free(errorPointer)
        sqlite3_close_v2(db)
    }
    
    sqlite3_open_v2(":memory:", &db, SQLITE_OPEN_READWRITE, nil)
    sqlite3_exec(db, query, nil, nil, &errorPointer)
    
    guard let errorPointer else { return }
    
    let errorMessage = String(cString: errorPointer)
    guard isSynaxError(errorMessage) else { return }
    
    throw parseErrorMessage(errorMessage)
}



func formatQuery(_ literal: StringLiteralExprSyntax, node: SyntaxProtocol) throws -> String {
    try literal.segments
        .map(format(node: node))
        .joined()
}

private func format(node: SyntaxProtocol) -> (_ segment: StringLiteralSegmentListSyntax.Element) throws -> String {
    return { segment in
        if let string = segment.as(StringSegmentSyntax.self) {
            return string.content.text
        } else if let expression = segment.as(ExpressionSegmentSyntax.self) {
            let firstExpr = expression.expressions.first!
            
            switch firstExpr.label?.text {
            case "table", "column": return firstExpr.expression.as(DeclReferenceExprSyntax.self)!.baseName.text
            case "subquery": return ""
            case nil: 
                let tableSyntax = LabeledExprSyntax(label: "table", expression: firstExpr.expression)
                let columnSyntax = LabeledExprSyntax(label: "column", expression: firstExpr.expression)
                let subquerySyntax = LabeledExprSyntax(label: "subquery", expression: firstExpr.expression)
                
                throw DiagnosticBuilder(for: node._syntaxNode)
                    .message("Interpolation must be labeled")
                    .messageID(domain: "SQLQueryMacro", id: "Interpolation")
                    .suggestReplacement("Add 'table:'", old: firstExpr._syntaxNode, new: tableSyntax)
                    .suggestReplacement("Add 'column:'", old: firstExpr._syntaxNode, new: columnSyntax)
                    .suggestReplacement("Add 'subquery:'", old: firstExpr._syntaxNode, new: subquerySyntax)
                    .severity(.error)
                    .build()
            default: 
                let tableSyntax = LabeledExprSyntax(label: "table", expression: firstExpr.expression)
                let columnSyntax = LabeledExprSyntax(label: "column", expression: firstExpr.expression)
                let subquerySyntax = LabeledExprSyntax(label: "subquery", expression: firstExpr.expression)
                
                throw DiagnosticBuilder(for: node._syntaxNode)
                    .message("Interpolations must be labeled 'table', 'column' or 'subquery'")
                    .messageID(domain: "SQLQueryMacro", id: "Interpolation")
                    .suggestReplacement("Replace '\(firstExpr.label!.text):' with 'table:'", old: firstExpr._syntaxNode, new: tableSyntax)
                    .suggestReplacement("Replace '\(firstExpr.label!.text):' with 'column:'", old: firstExpr._syntaxNode, new: columnSyntax)
                    .suggestReplacement("Replace '\(firstExpr.label!.text):' with 'subquery:'", old: firstExpr._syntaxNode, new: subquerySyntax)
                    .severity(.error)
                    .build()
            }
        }
        return ""
    }
}

private func isSynaxError(_ err: String) -> Bool {
    err.hasPrefix("no tables specified") ||
    err.hasPrefix("incomplete") ||
    err.hasPrefix("near")
}

private func parseErrorMessage(_ error: String) -> SQLQueryError {
    switch error {
    case error where error.hasPrefix("no tables specified"): return .tableNotSpecified
    case error where error.hasPrefix("incomplete"): return .incompleteQuery
    case error where error.hasPrefix("near"):
        var keyword = error
        
        keyword.removeFirst(6)
        keyword = keyword.components(separatedBy: ":")[0]
        keyword.removeLast()
        
        return .unknownKeyword(keyword)
        
    default: fatalError()
    }
}

extension Diagnostic: Error {}
