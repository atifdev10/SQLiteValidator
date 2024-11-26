import SwiftSyntaxMacros
import SwiftSyntax
import MacroToolkit
import SQLite3

func diagnoseSQL(_ query: String, node: some FreestandingMacroExpansionSyntax, context: some MacroExpansionContext) {
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
    
    parseErrorMessage(errorMessage, node: node, context: context)
}

func parseErrorMessage(_ error: String, node: some FreestandingMacroExpansionSyntax, context: some MacroExpansionContext) {
    switch error {
        case let error where error.hasPrefix("no tables specified"):
            let diagnostic = DiagnosticBuilder(for: Syntax(node))
                .message("Query incomplete")
                .messageID(domain: "SQLiteValidatorMacros", id: "Query")
                .severity(.error)
                .build()
            
            context.diagnose(diagnostic)
        case let error where error.hasPrefix("incomplete"):
            let diagnostic = DiagnosticBuilder(for: Syntax(node))
                .message("Table not specified in query")
                .messageID(domain: "SQLiteValidatorMacros", id: "Query")
                .severity(.error)
                .build()
            
            context.diagnose(diagnostic)        
        case var error where error.hasPrefix("near"):
            error.removeFirst(6)
            error = error.components(separatedBy: ":")[0]
            error.removeLast()
            
            let diagnostic = DiagnosticBuilder(for: Syntax(node))
                .message("Keyword '\(error)' not found")
                .messageID(domain: "SQLiteValidatorMacros", id: "Query")
                .severity(.error)
                .build()
            
            context.diagnose(diagnostic)
        default: return
    }
}
