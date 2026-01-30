//
//  EasterEggsTests.swift
//  trivitTests
//
//  Unit tests for EasterEggs
//

import XCTest
@testable import trivit

final class EasterEggsTests: XCTestCase {
    
    // MARK: - Known Easter Eggs
    
    func testEasterEgg42() {
        let message = EasterEggs.message(for: 42)
        XCTAssertNotNil(message)
        XCTAssertTrue(message!.contains("life") || message!.contains("universe"))
    }
    
    func testEasterEgg69() {
        let message = EasterEggs.message(for: 69)
        XCTAssertNotNil(message)
        XCTAssertEqual(message, "Nice.")
    }
    
    func testEasterEgg100() {
        let message = EasterEggs.message(for: 100)
        XCTAssertNotNil(message)
        XCTAssertTrue(message!.contains("Century"))
    }
    
    func testEasterEgg404() {
        let message = EasterEggs.message(for: 404)
        XCTAssertNotNil(message)
        XCTAssertTrue(message!.lowercased().contains("not found"))
    }
    
    func testEasterEgg420() {
        let message = EasterEggs.message(for: 420)
        XCTAssertNotNil(message)
    }
    
    func testEasterEgg666() {
        let message = EasterEggs.message(for: 666)
        XCTAssertNotNil(message)
        XCTAssertTrue(message!.contains("beast"))
    }
    
    func testEasterEgg777() {
        let message = EasterEggs.message(for: 777)
        XCTAssertNotNil(message)
        XCTAssertTrue(message!.contains("Jackpot"))
    }
    
    func testEasterEgg1000() {
        let message = EasterEggs.message(for: 1000)
        XCTAssertNotNil(message)
    }
    
    func testEasterEgg1337() {
        let message = EasterEggs.message(for: 1337)
        XCTAssertNotNil(message)
        XCTAssertTrue(message!.contains("L33T") || message!.uppercased().contains("LEET"))
    }
    
    func testEasterEgg9000() {
        let message = EasterEggs.message(for: 9000)
        XCTAssertNotNil(message)
        XCTAssertTrue(message!.contains("9000"))
    }
    
    func testEasterEgg9001() {
        let message = EasterEggs.message(for: 9001)
        XCTAssertNotNil(message)
    }
    
    // MARK: - Non-Easter Egg Numbers
    
    func testNoEasterEggForZero() {
        let message = EasterEggs.message(for: 0)
        XCTAssertNil(message)
    }
    
    func testNoEasterEggForOne() {
        let message = EasterEggs.message(for: 1)
        XCTAssertNil(message)
    }
    
    func testNoEasterEggForTen() {
        let message = EasterEggs.message(for: 10)
        XCTAssertNil(message)
    }
    
    func testNoEasterEggForRandomNumber() {
        let message = EasterEggs.message(for: 573)
        XCTAssertNil(message)
    }
    
    func testNoEasterEggForNearEasterEggNumber() {
        // Numbers close to easter eggs should not trigger
        XCTAssertNil(EasterEggs.message(for: 41))
        XCTAssertNil(EasterEggs.message(for: 43))
        XCTAssertNil(EasterEggs.message(for: 68))
        XCTAssertNil(EasterEggs.message(for: 70))
        XCTAssertNil(EasterEggs.message(for: 99))
        XCTAssertNil(EasterEggs.message(for: 101))
    }
}
