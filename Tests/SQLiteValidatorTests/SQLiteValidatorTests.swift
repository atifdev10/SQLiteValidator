import SwiftSyntaxMacros
import SwiftUICore
import MacroToolkit
import MacroTesting
import Testing

#if canImport(SQLiteValidatorMacros)
import SQLiteValidatorMacros
#else
#error("Run the tests in the host machine")
#endif

let testMacros: [String: Macro.Type] = [
    "sqlQuery": SQLQueryMacro.self,
    "sqlQueryUnsafe": SQLQueryMacro.self,
]
 
@Suite
struct ValidationTests {
    @Test(
        .tags(.success),
        arguments: [
            "SELECT * FROM my_table",
            "CREATE TABLE IF NOT EXISTS my_table (my_column int)",
            "ALTER TABLE my_table ADD COLUMN my_column",
            "INSERT INTO my_table (my_column) VALUES ('my_value')",
            "SELECT trackid, name, albumid FROM tracks WHERE albumid = (SELECT albumid FROM albums WHERE title = 'Let There Be Rock')",
        ]
    )
    func approveBasic(query: String) {
        assertMacro(testMacros) {
            """
            #sqlQuery("\(query)")
            """
        } expansion: {
            """
            "ALTER TABLE my_table ADD COLUMN my_column"
            """
        }
    }
    
    @Test(.tags(.success))
    func aproveDividedSubquery() {
        assertMacro(testMacros) {
            #"""
            let subquery = #sqlQuery("SELECT albumid FROM albums WHERE title = 'Let There Be Rock'")
            
            #sqlQuery("SELECT trackid, name, albumid FROM tracks WHERE albumid = (\(subquery: subquery))")
            """#
        } diagnostics: {
            #"""
            let subquery = #sqlQuery("SELECT albumid FROM albums WHERE title = 'Let There Be Rock'")

            #sqlQuery("SELECT trackid, name, albumid FROM tracks WHERE albumid = (\(subquery: subquery))")
            ╰─ 🛑 Keyword ')' not found
            """#
        }
    }
    
    @Test(.tags(.failure))
    func rejectBasic() {
        assertMacro(testMacros) {
            """
            #sqlQuery("SEELECT * FROM my_table")
            """
        } diagnostics: {
            """
            #sqlQuery("SEELECT * FROM my_table")
            ┬───────────────────────────────────
            ╰─ 🛑 Keyword 'seelect' not found
            """
        }
    }
    
    @Test
    func warning() {
        assertMacro(testMacros) {
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
    func warningSuppressed() {
        assertMacro(testMacros) {
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


@Suite
struct InterpolationTests {
    @Test(.tags(.failure))
    func interpolationLabelMissing() {
        assertMacro(testMacros) {
            #"""
            let subquery = #sqlQuery("SELECT albumid FROM albums WHERE title = 'Let There Be Rock'")
            
            #sqlQuery("SELECT trackid, name, albumid FROM tracks WHERE albumid = (\(subquery))")
            """#
        } diagnostics: {
            #"""
            let subquery = #sqlQuery("SELECT albumid FROM albums WHERE title = 'Let There Be Rock'")

            #sqlQuery("SELECT trackid, name, albumid FROM tracks WHERE albumid = (\(subquery))")
            │                                                                     ╰─ 🛑 Interpolation must be labeled
            │                                                                        ✏️ Add 'table:'
            │                                                                        ✏️ Add 'column:'
            │                                                                        ✏️ Add 'subquery:'
            ╰─ 🛑 Keyword ')' not found
            """#
        }
    }
    
    @Test(
        .disabled("Not supported yet"),
        .tags(.failure)
    )
    func interpolationLabelWrong() {
        assertMacro(testMacros) {
            #"""
            let subquery = #sqlQuery("SELECT albumid FROM albums WHERE title = 'Let There Be Rock'")
            
            #sqlQuery("SELECT trackid, name, albumid FROM tracks WHERE albumid = (\(table: subquery))")
            """#
        }
    }
    
    @Test(.tags(.success))
    func interpolationLabelCorrect() {
        assertMacro(testMacros) {
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

extension Tag {
    @Tag static var success: Tag
    @Tag static var failure: Tag
}
