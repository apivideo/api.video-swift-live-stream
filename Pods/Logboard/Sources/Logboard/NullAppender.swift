import Foundation

public class NullAppender: LogboardAppender {
    public init() {
    }

    public func append(_ logboard: Logboard, level: Logboard.Level, message: [Any], file: StaticString, function: StaticString, line: Int) {
    }

    public func append(_ logboard: Logboard, level: Logboard.Level, format: String, arguments: CVarArg, file: StaticString, function: StaticString, line: Int) {
    }
}
