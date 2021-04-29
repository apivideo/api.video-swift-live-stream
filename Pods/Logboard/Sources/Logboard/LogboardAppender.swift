import Foundation

public protocol LogboardAppender {
    func append(_ logboard: Logboard, level: Logboard.Level, message: [Any], file: StaticString, function: StaticString, line: Int)
    func append(_ logboard: Logboard, level: Logboard.Level, format: String, arguments: CVarArg, file: StaticString, function: StaticString, line: Int)
}
