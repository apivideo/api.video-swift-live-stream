@testable import ApiVideoLiveStream
import XCTest

class ApiVideoLiveStreamTests: XCTestCase {
    private let connectionExpectation = XCTestExpectation(description: "connectionExpectation")
    private let disconnectionExpectation = XCTestExpectation(description: "disconnectionExpectation")

    func testSingleLiveStream() throws {
        let liveStream = try ApiVideoLiveStream()
        liveStream.delegate = self
        try liveStream.startStreaming(streamKey: Parameters.streamKey, url: Parameters.rtmpUrl)
        wait(for: [self.connectionExpectation], timeout: 10.0)
        liveStream.stopStreaming()
        wait(for: [self.disconnectionExpectation], timeout: 10.0)
    }
}

// MARK: ApiVideoLiveStreamDelegate

extension ApiVideoLiveStreamTests: ApiVideoLiveStreamDelegate {
    func connectionSuccess() {
        self.connectionExpectation.fulfill()
    }

    func connectionFailed(_: String) {}

    func disconnection() {
        self.disconnectionExpectation.fulfill()
    }

    func audioError(_: Error) {}

    func videoError(_: Error) {}
}
