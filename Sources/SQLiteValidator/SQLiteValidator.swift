// The Swift Programming Language
// https://docs.swift.org/swift-book

/**
 A macro that checks if the provided SQLite3 query is valid.

 ## Validation mechanisms
 If the provided query is wrong, it will generate a corresponding compile time error.
 ```swift
 #sqlQuery("SEELECT * FROM my_table")
 //╰─ 🛑 Keyword "SEELECT" not found
 #sqlQuery("SELECT *")
 //╰─ 🛑 Table not specified
 #sqlQuery("SELECT * FROM my_table WHERE")
 //╰─ 🛑 Query incomplete
 ```
 > Tip: Queries are not case-sensitive.

 ## Safety mechanisms
 If the written query isn't safe, it will warn you. You will need to mark it unsafe to mute this warning.
 ```swift
 #sqlQuery("DROP TABLE my_table")
 //╰─ ⚠️ Dropping the table may be dangerous
 #sqlQueryUnsafe("DROP TABLE my_table")
 //╰─ ✅ No warnings
 ```

 ## Interpolation
 You can use interpolation for data, column and table names, subqueries, and clauses.

 ```swift
 let tableName = "my_table"
 #sqlQuery("SELECT * FROM \(tableName)")

 let columnName = "my_column"
 #sqlQuery("SELECT \(columnName) FROM my_table")

 let clause = "WHERE 1=1"
 #sqlQuery("SELECT * FROM my_table \(clause)")

 let subquery = #sqlQuery("SELECT my_column FROM my_other_table")
 #sqlQuery("SELECT * FROM my_table WHERE my_column = (\(subquery))")
 ```

 > Important: Separating core query functions (e.g., **"select \*"** and **" from table"**) is prohibited. The macro
 does not support it. Splitting a subquery requires parentheses to stay, and splitting a clause requires the keyword
 to separate.
 */
@freestanding(expression)
public macro sqlQuery(_ query: String) -> String = #externalMacro(
    module: "SQLiteValidatorMacros",
    type: "SQLQueryMacro"
)

/// This macro has the same function as the ``sqlQuery(_:)`` macro, but the secondary safety mechanisms are disabled.
@freestanding(expression)
public macro sqlQueryUnsafe(_ query: String) -> String = #sqlQuery(query)
