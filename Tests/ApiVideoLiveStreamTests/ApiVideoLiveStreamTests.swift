@testable import ApiVideoLiveStream
import XCTest

class ApiVideoLiveStreamTests: XCTestCase {
    private let connectionExpectation = XCTestExpectation(description: "connectionExpectation")
    private let disconnectionExpectation = XCTestExpectation(description: "disconnectionExpectation")

    func testSingleLiveStream() throws {
        let liveStream = try ApiVideoLiveStream()
        liveStream.delegate = self
        try liveStream.startStreaming(streamKey: Parameters.streamKey, url: Parameters.rtmpUrl)
        wait(for: [connectionExpectation], timeout: 10.0)
        liveStream.stopStreaming()
        wait(for: [disconnectionExpectation], timeout: 10.0)
    }
}

extension ApiVideoLiveStreamTests: ApiVideoLiveStreamDelegate {
    func connectionSuccess() {
        connectionExpectation.fulfill()
    }

    func connectionFailed(_ code: String) {

    }

    func disconnection() {
        disconnectionExpectation.fulfill()
    }

    func audioError(_ error: Error) {

    }

    func videoError(_ error: Error) {

    }
}
