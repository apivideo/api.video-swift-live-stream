import Foundation

public enum LiveStreamError: Error {
    case IllegalArgumentError(String)
    case IllegalOperationError(String)
}
