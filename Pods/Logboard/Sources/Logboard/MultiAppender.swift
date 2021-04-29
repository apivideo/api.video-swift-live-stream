import Foundation

public class MultiAppender: LogboardAppender {
    public var appenders: [LogboardAppender] = []

    public init() {
    }

    public func append(_ logboard: Logboard, level: Logboard.Level, message: [Any], file: StaticString, function: StaticString, line: Int) {
        for appender in appenders {
            appender.append(logboard, level: level, message: message, file: file, function: function, line: line)
        }
    }

    public func append(_ logboard: Logboard, level: Logboard.Level, format: String, arguments: CVarArg, file: StaticString, function: StaticString, line: Int) {
        for appender in appenders {
            appender.append(logboard, level: level, format: format, arguments: arguments, file: file, function: function, line: line)
        }
    }
}
