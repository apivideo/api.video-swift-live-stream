import Foundation

public class ConsoleAppender: LogboardAppender {
    public init() {
    }

    public func append(_ logboard: Logboard, level: Logboard.Level, message: [Any], file: StaticString, function: StaticString, line: Int) {
        print(Logboard.dateFormatter.string(from: Date()), "[\(level)]", "[\(logboard.identifier)]", "[\(filename(file.description)):\(line)]", function, ">", message.map({ String(describing: $0) }).joined(separator: ""))
    }
    public func append(_ logboard: Logboard, level: Logboard.Level, format: String, arguments: CVarArg, file: StaticString, function: StaticString, line: Int) {
        print(Logboard.dateFormatter.string(from: Date()), "[\(level)]", "[\(logboard.identifier)]", "[\(filename(file.description)):\(line)]", function, ">", String(format: format, arguments))
    }
}
