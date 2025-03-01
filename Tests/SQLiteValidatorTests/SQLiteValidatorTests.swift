import MacroTesting
import SwiftSyntaxMacros
import Testing
import XCTest

#if canImport(SQLiteValidatorMacros)
    import SQLiteValidatorMacros
#else
    #error("Run the tests in the host machine")
#endif

let testMacros: [String: Macro.Type] = [
    "sqlQuery": SQLQueryMacro.self,
    "sqlQueryUnsafe": SQLQueryMacro.self,
]

@Suite(
    .macros(
        record: .missing,
        macros: testMacros
    )
)
struct ValidationTests {
    @Test
    func queryApprove() {
        assertMacro {
            """
            #sqlQuery("INSERT INTO my_table (my_column) VALUES ('my_value')")
            """
        } expansion: {
            """
            "INSERT INTO my_table (my_column) VALUES ('my_value')"
            """
        }
    }

    @Test
    func dividedSubqueryApprove() {
        assertMacro {
            #"""
            let subquery = #sqlQuery("SELECT albumid FROM albums WHERE title = 'Let There Be Rock'")

            #sqlQuery("SELECT trackid, name, albumid FROM tracks WHERE albumid = (\(subquery))")
            """#
        } expansion: {
            #"""
            let subquery = "SELECT albumid FROM albums WHERE title = 'Let There Be Rock'"

            "SELECT trackid, name, albumid FROM tracks WHERE albumid = (\(subquery))"
            """#
        }
    }

    @Test
    func queryTypoReject() {
        assertMacro {
            """
            #sqlQuery("SEELECT * FROM my_table")
            """
        } diagnostics: {
            """
            #sqlQuery("SEELECT * FROM my_table")
            ╰─ 🛑 Keyword 'seelect' not found
            """
        }
    }

    @Test
    func queryIncompleteReject() {
        assertMacro {
            """
            #sqlQuery("SEELECT * FROM my_table")
            """
        } diagnostics: {
            """
            #sqlQuery("SEELECT * FROM my_table")
            ╰─ 🛑 Keyword 'seelect' not found
            """
        }
    }

    @Test
    func queryTableNotSpecifiedReject() {
        assertMacro {
            """
            #sqlQuery("SEELECT * FROM my_table")
            """
        } diagnostics: {
            """
            #sqlQuery("SEELECT * FROM my_table")
            ╰─ 🛑 Keyword 'seelect' not found
            """
        }
    }

    @Test
    func unsafeQueryWarning() {
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

    @Test
    func unsafeQuerySuppressedWarning() {
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
