import SwiftSyntax
import SwiftSyntaxMacros
import MacroToolkit

enum SQLQueryError: Error, CustomStringConvertible {
    case notLiteral
    
    var description: String {
        switch self {
            case .notLiteral: return "Query must be string literal"
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
            .map { convertSegmentsToString($0, node: node, context: context) }
            .joined()
            .lowercased()
        
        diagnoseSQL(formattedQuery, node: node, context: context)
        
        guard node.macroName.text != "sqlQueryUnsafe" else {
            return "\(query)"
        }
        
        if formattedQuery.hasPrefix("drop") {
            let diagnostic = DiagnosticBuilder(for: Syntax(query))
                .message("Dropping the table may be dangerous")
                .suggestReplacement("Mark it unsafe to mute this warning", old: node.macroName._syntaxNode, new: TokenSyntax(stringLiteral: "sqlQueryUnsafe"))
                .severity(.warning)
                .build()
            
            context.diagnose(diagnostic)
        }
        
        return "\(query)"
    }
    
    
    static private func convertSegmentsToString(_ segment: StringLiteralSegmentListSyntax.Element, node: some FreestandingMacroExpansionSyntax, context: some MacroExpansionContext) -> String {
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
                
                let diagnostic = DiagnosticBuilder(for: Syntax(segment))
                    .message("Interpolation must be labeled")
                    .messageID(domain: "SQLiteValidatorMacros", id: "Interpolation")
                    .suggestReplacement("Add 'table:'", old: firstExpr._syntaxNode, new: tableSyntax)
                    .suggestReplacement("Add 'column:'", old: firstExpr._syntaxNode, new: columnSyntax)
                    .suggestReplacement("Add 'subquery:'", old: firstExpr._syntaxNode, new: subquerySyntax)
                    .severity(.error)
                    .build()
                context.diagnose(diagnostic)
            default:
                let tableSyntax = LabeledExprSyntax(label: "table", expression: firstExpr.expression)
                let columnSyntax = LabeledExprSyntax(label: "column", expression: firstExpr.expression)
                let subquerySyntax = LabeledExprSyntax(label: "subquery", expression: firstExpr.expression)
                
                let diagnostic = DiagnosticBuilder(for: Syntax(segment))
                    .message("Interpolations must be labeled 'table', 'column' or 'subquery'")
                    .messageID(domain: "SQLiteValidatorMacros", id: "Interpolation")
                    .suggestReplacement("Replace '\(firstExpr.label!.text):' with 'table:'", old: firstExpr._syntaxNode, new: tableSyntax)
                    .suggestReplacement("Replace '\(firstExpr.label!.text):' with 'column:'", old: firstExpr._syntaxNode, new: columnSyntax)
                    .suggestReplacement("Replace '\(firstExpr.label!.text):' with 'subquery:'", old: firstExpr._syntaxNode, new: subquerySyntax)
                    .severity(.error)
                    .build()
                context.diagnose(diagnostic)
            }
        }
        return ""
    }
}
