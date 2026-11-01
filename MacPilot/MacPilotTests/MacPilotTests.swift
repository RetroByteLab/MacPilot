//
//  MacPilotTests.swift
//  MacPilotTests
//
//  MacPilot project - RetroByteLab.
//

import XCTest
@testable import MacPilot

final class MacPilotTests: XCTestCase {

    // Only inputs rejected synchronously before routing are safe through shared.
    // PilotActivity/LocalApplicationAI are private; shared.activity is fileprivate.
    // @testable cannot inject their mock launchers. Do not submit a launch here,
    // copy production implementations, or count these guards as execution tests.
    @MainActor
    private func idleSession() throws -> MacPilotCommandSession {
        let session = MacPilotCommandSession.shared
        try XCTSkipIf(session.isBusy || !session.proposedActions.isEmpty,
                      "The shared session is occupied; do not alter an existing command.")
        return session
    }

    @MainActor
    func testWhitespaceIsANoOpBeforeRouting() throws {
        let session = try idleSession()
        let status = session.status
        let error = session.errorMessage
        let cancelled = session.cancellationRequested

        session.submit(" \t\n ")

        XCTAssertEqual(session.status, status)
        XCTAssertEqual(session.errorMessage, error)
        XCTAssertEqual(session.cancellationRequested, cancelled)
        assertInactive(session)
    }

    @MainActor
    func testOversizedLaunchRequestRejectsBeforeRouting() throws {
        let session = try idleSession()
        // Looks like a launch request, but exceeds the public 500-character cap.
        // This never enters the task that discovers apps or invokes a planner.
        session.submit("Open Safari " + String(repeating: "x", count: 501))

        XCTAssertEqual(session.errorMessage, "Please keep the request under 500 characters.")
        XCTAssertEqual(session.status, session.errorMessage)
        assertInactive(session)
    }

    @MainActor
    func testIdleCancellationDoesNotStartOrChangeACommand() throws {
        let session = try idleSession()
        let status = session.status
        let error = session.errorMessage
        let cancelled = session.cancellationRequested

        session.cancel()

        XCTAssertEqual(session.status, status)
        XCTAssertEqual(session.errorMessage, error)
        XCTAssertEqual(session.cancellationRequested, cancelled)
        assertInactive(session)
    }

    @MainActor
    private func assertInactive(_ session: MacPilotCommandSession,
                                file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertFalse(session.isBusy, file: file, line: line)
        XCTAssertFalse(session.isProcessing, file: file, line: line)
        XCTAssertFalse(session.requiresApproval, file: file, line: line)
        XCTAssertFalse(session.canCancel, file: file, line: line)
        XCTAssertTrue(session.proposedActions.isEmpty, file: file, line: line)
    }

}
