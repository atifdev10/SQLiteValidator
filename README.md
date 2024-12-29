# SQLiteValidator

A swift macro for validating an SQLite query.

```swift
// 🛑 Keyword 'orrer' not found
let query = #sqlQuery("""
    WITH employee_ranking AS (
        SELECT
            employee_id,
            last_name,
            first_name,
            salary,
            NTILE(4) OVER (ORDER BY salary) as ntile
        FROM
            employee
    )
    SELECT
        employee_id,
        last_name,
        first_name,
        salary
    FROM employee_ranking
    WHERE ntile = 4
    ORRER BY salary
""")
```

## How to use
&nbsp;  
This macro is easy to use. Call the macro and enter the query as a string. If the query has a syntax problem, it will give an error.
If it doesn't have any, it will return the query you provided as a string without modifying it.

```swift
let query1 = #sqlQuery("UPDATE m_table SET column_1 = new_value_1, column_2 = new_value_2")

let query2 = #sqlQuery("ISNERT INTO my_table (column) VALUES (10)")   // 🛑 Keyword 'isnert' not found
let query3 = #sqlQuery("ALTER TABLE my_table RENAME TO")              // 🛑 Table not specified
let query4 = #sqlQuery("SELECT DISTINCT column_list FROM table_list") // 🛑 Query incomplete
```
&nbsp;  
If the query is unsafe, it will warn you. You will need to mark it unsafe to mute the warning.  

```swift
let query5 = #sqlQuery("DROP TABLE IF EXISTS my_table") // ⚠️ Dropping the table may be dangerous

let query6 = #sqlQueryUnsafe("DROP TABLE IF EXISTS my_table")
```
&nbsp;  
The macro supports dividing subqueries into seperate values. You can also separate clauses but it can't provide validaton for it.

```swift
let subquery = #sqlQuery("SELECT column_2 FROM table_2")

let query7 = #sqlQuery("SELECT column_1 FROM table_1 WHERE column_1 = (\(subquery))")

let clause = "WHERE column_1 = '10'"

let query8 = #sqlQuery("SELECT column_1 FROM table_1 \(clause)")
```

## License

This library is released under the Apache License 2.0. See [LICENSE](LICENSE.txt) for details.
