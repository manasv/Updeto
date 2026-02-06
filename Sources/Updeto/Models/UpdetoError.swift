import Foundation

/// Errors that can happen while performing an update lookup.
public enum UpdetoError: Error, Sendable, Equatable {
    /// Transport-level URL loading failure.
    case network(URLError)
    /// The server returned a non-success HTTP status code.
    case badServerResponse(statusCode: Int)
    /// The lookup payload could not be decoded.
    case decoding
}
