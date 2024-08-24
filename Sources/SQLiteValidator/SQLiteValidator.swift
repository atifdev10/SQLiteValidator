// The Swift Programming Language
// https://docs.swift.org/swift-book

@freestanding(expression)
public macro sqlQuery(_ query: String) -> String = #externalMacro(module: "SQLiteValidatorMacros", type: "SQLQueryMacro")
@freestanding(expression)
public macro sqlQueryUnsafe(_ query: String) -> String = #sqlQuery(query)

public extension String.StringInterpolation {
    mutating func appendInterpolation(table: String) {
        appendInterpolation(table)
    }
    mutating func appendInterpolation(column: String) {
        appendInterpolation(column)
    }
    mutating func appendInterpolation(subquery: String) {
        appendInterpolation(subquery)
    }
}
