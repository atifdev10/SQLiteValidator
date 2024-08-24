import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import MacroToolkit
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(SQLiteValidatorMacros)
import SQLiteValidatorMacros

let testMacros: [String: Macro.Type] = [
    "sqlQuery": SQLQueryMacro.self,
    "sqlQueryUnsafe": SQLQueryMacro.self,
]
#endif

final class SQLiteValidatorTests: XCTestCase {}
