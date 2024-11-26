// The Swift Programming Language
// https://docs.swift.org/swift-book

/**
 A macro that checks if the provided SQLite3 query is valid.

 ## Validation mechanisms
 If the provided query is wrong, it will generate a
 corresponding compile time error.
 ```swift
 #sqlQuery("SEELECT * FROM my_table")
 //╰─ 🛑 Keyword "SEELECT" not found
 #sqlQuery("SELECT *")
 //╰─ 🛑 Table not specified
 #sqlQuery("SELECT * FROM my_table WHERE")
 //╰─ 🛑 Query incomplete
 ```



 ## Safety mechanisms
 If the written query is unsafe, it will warn you. You will
 need to mark it unsafe to mute this warning.
 ```swift
 #sqlQuery("DROP TABLE my_table")
 //╰─ ⚠️ Dropping the table may be dangerous
 ```
 > Tip: Queries are not case-sensitive.

 
 
 ## Interpolation
 We created named interpolations for this purpose.
 ```swift
 let tableName = "my_table"
 #sqlQuery("SELECT * FROM \(table: tableName)")
 ```
 > Important: Using the wrong-named interpolation can cause
 the  macro to misbehave.

 ```swift
 let columnName = "my_column"
 #sqlQuery("SELECT \(column: columnName) FROM my_table")
 ```

 > Important: Breaking core query functions (e.g., "select *" and
 "from table") is prohibited. The macro will misbehave.
 ```swift
 let subquery = "WHERE 1=1"
 #sqlQuery("SELECT * FROM my_table \(subquery: subquery)")
 ```

 > Important: Splitting clauses also require the keyword to
 get split. But subqueries require the parentheses not to get
 split.
 ```swift
 let subquery = #sqlQuery("SELECT my_column FROM my_other_table")
 #sqlQuery("SELECT * FROM my_table WHERE my_column = (\(subquery: subquery))")
 ```
*/
@freestanding(expression)
public macro sqlQuery(_ query: String) -> String = #externalMacro(module: "SQLiteValidatorMacros", type: "SQLQueryMacro")

/// This macro has the same function as the ``sqlQuery(_:)`` but the secondary safety mechanisms are disabled.
@freestanding(expression)
public macro sqlQueryUnsafe(_ query: String) -> String = #sqlQuery(query)

/// Interpolation for SQLite queries.
public extension String.StringInterpolation {
    /// An interpolation for extracted table name from the query.
    mutating func appendInterpolation(table: String) {
        appendInterpolation(table)
    }
    /// An interpolation for extracted column name from the query.
    mutating func appendInterpolation(column: String) {
        appendInterpolation(column)
    }
    /// An interpolation for extracted subquery from the query.
    mutating func appendInterpolation(subquery: String) {
        appendInterpolation(subquery)
    }
}
