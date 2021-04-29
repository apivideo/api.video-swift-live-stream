import Foundation

extension Logboard {
    public struct Data {
        public var date: Date
        public var level: Level
        public var identifier: String
        public var file: String
        public var line: Int
        public var function: String
        public var message: String

        public init?(_ data: Foundation.Data) {
            guard let strings: [String.SubSequence] = String(bytes: data, encoding: .utf8)?.split(separator: "\t"), 7 <= strings.count else {
                return nil
            }
            date = Logboard.dateFormatter.date(from: String(strings[0])) ?? Date()
            level = Level(string: String(strings[1])) ?? .trace
            identifier = String(strings[2])
            file = String(strings[3])
            line = Int(String(strings[4])) ?? 0
            function = String(strings[5])
            message = strings[6...].joined(separator: "\t")
        }
    }
}

extension Logboard.Data: CustomStringConvertible {
    public var description: String {
        return "\(Logboard.dateFormatter.string(from: date)) [\(level)] [\(identifier)] [\(filename(file)):\(line)] \(function) > \(message)"
    }
}
