import Foundation

func filename(_ file: String) -> String {
    return file.components(separatedBy: "/").last ?? file
}

public class Logboard {
    static public let dateFormatter: DateFormatter = {
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-dd-MM HH:mm:ss.SSS"
        return dateFormatter
    }()

    public enum Level: Int, CustomStringConvertible {
        case trace = 0
        case debug = 1
        case info  = 2
        case warn  = 3
        case error = 4

        public init?(string: String) {
            switch string {
            case "Trace":
                self = .trace
            case "Debug":
                self = .debug
            case "Info":
                self = .info
            case "Warn":
                self = .warn
            case "Error":
                self = .error
            default:
                return nil
            }
        }

        public var description: String {
            switch self {
            case .trace:
                return "Trace"
            case .debug:
                return "Debug"
            case .info:
                return "Info"
            case .warn:
                return "Warn"
            case .error:
                return "Error"
            }
        }
    }

    private static var instances: [String: Logboard] = [:]

    public static func with(_ identifier: String) -> Logboard {
        if instances[identifier] == nil {
            instances[identifier] = Logboard(identifier)
        }
        return instances[identifier]!
    }

    public let identifier: String
    public var level: Logboard.Level = .info
    public var appender: LogboardAppender = ConsoleAppender()

    public init(_ identifier: String) {
        self.identifier = identifier
    }

    public func isEnabledFor(level: Logboard.Level) -> Bool {
        return self.level.rawValue <= level.rawValue
    }

    public func trace(_ message: Any..., file: StaticString = #file, function: StaticString = #function, line: Int = #line) {
        guard isEnabledFor(level: .trace) else { return }
        appender.append(self, level: .trace, message: message, file: file, function: function, line: line)
    }

    public func trace(format: String, arguments: CVarArg, file: StaticString = #file, function: StaticString = #function, line: Int = #line) {
        guard isEnabledFor(level: .trace) else { return }
        appender.append(self, level: .trace, format: format, arguments: arguments, file: file, function: function, line: line)
    }

    public func debug(_ message: Any..., file: StaticString = #file, function: StaticString = #function, line: Int = #line) {
        guard isEnabledFor(level: .debug) else { return }
        appender.append(self, level: .debug, message: message, file: file, function: function, line: line)
    }

    public func debug(format: String, arguments: CVarArg, file: StaticString = #file, function: StaticString = #function, line: Int = #line) {
        guard isEnabledFor(level: .debug) else { return }
        appender.append(self, level: .debug, format: format, arguments: arguments, file: file, function: function, line: line)
    }

    public func info(_ message: Any..., file: StaticString = #file, function: StaticString = #function, line: Int = #line) {
        guard isEnabledFor(level: .info) else { return }
        appender.append(self, level: .info, message: message, file: file, function: function, line: line)
    }

    public func info(format: String, arguments: CVarArg, file: StaticString = #file, function: StaticString = #function, line: Int = #line) {
        guard isEnabledFor(level: .info) else { return }
        appender.append(self, level: .info, format: format, arguments: arguments, file: file, function: function, line: line)
    }

    public func warn(_ message: Any..., file: StaticString = #file, function: StaticString = #function, line: Int = #line) {
        guard isEnabledFor(level: .warn) else { return }
        appender.append(self, level: .warn, message: message, file: file, function: function, line: line)
    }

    public func warn(format: String, arguments: CVarArg, file: StaticString = #file, function: StaticString = #function, line: Int = #line) {
        guard isEnabledFor(level: .warn) else { return }
        appender.append(self, level: .warn, format: format, arguments: arguments, file: file, function: function, line: line)
    }

    public func error(_ message: Any..., file: StaticString = #file, function: StaticString = #function, line: Int = #line) {
        guard isEnabledFor(level: .error) else { return }
        appender.append(self, level: .error, message: message, file: file, function: function, line: line)
    }

    public func error(format: String, arguments: CVarArg, file: StaticString = #file, function: StaticString = #function, line: Int = #line) {
        guard isEnabledFor(level: .error) else { return }
        appender.append(self, level: .error, format: format, arguments: arguments, file: file, function: function, line: line)
    }
}
