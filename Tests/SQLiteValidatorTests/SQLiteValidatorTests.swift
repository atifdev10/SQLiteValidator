import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import MacroToolkit
import MacroTesting
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(SQLiteValidatorMacros)
import SQLiteValidatorMacros

let testMacros: [String: Macro.Type] = [
    "sqlQuery": SQLQueryMacro.self,
    "sqlQueryUnsafe": SQLQueryMacro.self,
]
#endif

final class SQLiteValidatorValidationTests: XCTestCase {
    override func invokeTest() {
        withMacroTesting(macros: testMacros) {
            super.invokeTest()
        }
    }
    
    func testMacroApproveBasic() {
        assertMacro {
            """
            #sqlQuery("SELECT * FROM my_table")
            """
        } expansion: {
            """
            "SELECT * FROM my_table"
            """
        }
    }
    
    func testMacroApproveComplicated() {
        assertMacro {
            """
            #sqlQuery("SELECT trackid, name, albumid FROM tracks WHERE albumid = (SELECT albumid FROM albums WHERE title = 'Let There Be Rock')")
            """
        } expansion: {
            """
            "SELECT trackid, name, albumid FROM tracks WHERE albumid = (SELECT albumid FROM albums WHERE title = 'Let There Be Rock')"
            """
        }
    }
    
    func testMacroApproveDividedSubquery() {
        assertMacro {
            #"""
            let subquery = #sqlQuery("SELECT albumid FROM albums WHERE title = 'Let There Be Rock'")
            
            #sqlQuery("SELECT trackid, name, albumid FROM tracks WHERE albumid = (\(subquery: subquery))")
            """#
        } diagnostics: {
            #"""
            let subquery = #sqlQuery("SELECT albumid FROM albums WHERE title = 'Let There Be Rock'")

            #sqlQuery("SELECT trackid, name, albumid FROM tracks WHERE albumid = (\(subquery: subquery))")
            ┬─────────────────────────────────────────────────────────────────────────────────────────────
            ╰─ 🛑 Keyword ')' not found
            """#
        }
    }
    
    func testMacroRejectBasic() {
        assertMacro {
            """
            #sqlQuery("SEELECT * FROM my_table")
            """
        } diagnostics: {
            """
            #sqlQuery("SEELECT * FROM my_table")
            ┬───────────────────────────────────
            ╰─ 🛑 Keyword 'SEELECT' not found
            """
        }
    }
    
    func testMacroWarning() {
        assertMacro {
            """
            #sqlQuery("DROP TABLE my_table")
            """
        } diagnostics: {
            """
            #sqlQuery("DROP TABLE my_table")
            ╰─ ⚠️ Dropping the table may be dangerous
               ✏️ Mark it unsafe to mute this warning
            """
        } fixes: {
            """
            #sqlQueryUnsafe("DROP TABLE my_table")
            """
        } expansion: {
            """
            "DROP TABLE my_table"
            """
        }
    }
    
    func testMacroWarningSuppressed() {
        assertMacro {
            """
            #sqlQueryUnsafe("DROP TABLE my_table")
            """
        } expansion: {
            """
            "DROP TABLE my_table"
            """
        }
    }
}


class SQLiteValidatorInterpolationTests: XCTestCase {
    override func invokeTest() {
        withMacroTesting(macros: testMacros) {
            super.invokeTest()
        }
    }
    
    func testMacroInterpolationLabelMissing() {
        assertMacro {
            #"""
            let subquery = #sqlQuery("SELECT albumid FROM albums WHERE title = 'Let There Be Rock'")
            
            #sqlQuery("SELECT trackid, name, albumid FROM tracks WHERE albumid = (\(subquery))")
            """#
        } diagnostics: {
            #"""
            let subquery = #sqlQuery("SELECT albumid FROM albums WHERE title = 'Let There Be Rock'")

            #sqlQuery("SELECT trackid, name, albumid FROM tracks WHERE albumid = (\(subquery))")
            ╰─ 🛑 Interpolation must be labeled
               ✏️ Add 'table:'
               ✏️ Add 'column:'
               ✏️ Add 'subquery:'
            """#
        } fixes: {
            #"""
            let subquery = #sqlQuery("SELECT albumid FROM albums WHERE title = 'Let There Be Rock'")

            #sqlQuery("SELECT trackid, name, albumid FROM tracks WHERE albumid = (\(table: subquery))")
            """#
        } expansion: {
            #"""
            let subquery = "SELECT albumid FROM albums WHERE title = 'Let There Be Rock'"

            "SELECT trackid, name, albumid FROM tracks WHERE albumid = (\(table: subquery))"
            """#
        }
    }
    
    func testMacroInterpolationLabelWrong() {
        assertMacro {
            #"""
            let subquery = #sqlQuery("SELECT albumid FROM albums WHERE title = 'Let There Be Rock'")
            
            #sqlQuery("SELECT trackid, name, albumid FROM tracks WHERE albumid = (\(table: subquery))")
            """#
        } expansion: {
            #"""
            let subquery = "SELECT albumid FROM albums WHERE title = 'Let There Be Rock'"

            "SELECT trackid, name, albumid FROM tracks WHERE albumid = (\(table: subquery))"
            """#
        }
    }
    
    func testMacroInterpolationLabelCorrect() {
        assertMacro {
            #"""
            let tableName = "my_table"
            
            #sqlQuery("SELECT * FROM \(table: tableName)")
            """#
        } expansion: {
            #"""
            let tableName = "my_table"

            "SELECT * FROM \(table: tableName)"
            """#
        }
    }
}
