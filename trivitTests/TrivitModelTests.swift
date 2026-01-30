//
//  TrivitModelTests.swift
//  trivitTests
//
//  Unit tests for the Trivit model
//

import XCTest
import SwiftData
@testable import trivit

final class TrivitModelTests: XCTestCase {
    
    // MARK: - Initialization Tests
    
    func testDefaultInitialization() {
        let trivit = Trivit()
        
        XCTAssertEqual(trivit.title, "New Trivit")
        XCTAssertEqual(trivit.count, 0)
        XCTAssertEqual(trivit.colorIndex, 0)
        XCTAssertTrue(trivit.isCollapsed)
        XCTAssertNotNil(trivit.id)
        XCTAssertNotNil(trivit.createdAt)
    }
    
    func testCustomInitialization() {
        let id = UUID()
        let date = Date()
        let trivit = Trivit(
            id: id,
            title: "My Counter",
            count: 10,
            colorIndex: 5,
            isCollapsed: false,
            createdAt: date
        )
        
        XCTAssertEqual(trivit.id, id)
        XCTAssertEqual(trivit.title, "My Counter")
        XCTAssertEqual(trivit.count, 10)
        XCTAssertEqual(trivit.colorIndex, 5)
        XCTAssertFalse(trivit.isCollapsed)
        XCTAssertEqual(trivit.createdAt, date)
    }
    
    // MARK: - Increment Tests
    
    func testIncrement() {
        let trivit = Trivit(count: 0)
        
        trivit.increment()
        
        XCTAssertEqual(trivit.count, 1)
    }
    
    func testIncrementMultipleTimes() {
        let trivit = Trivit(count: 0)
        
        trivit.increment()
        trivit.increment()
        trivit.increment()
        
        XCTAssertEqual(trivit.count, 3)
    }
    
    func testIncrementFromNonZero() {
        let trivit = Trivit(count: 42)
        
        trivit.increment()
        
        XCTAssertEqual(trivit.count, 43)
    }
    
    // MARK: - Decrement Tests
    
    func testDecrement() {
        let trivit = Trivit(count: 5)
        
        trivit.decrement()
        
        XCTAssertEqual(trivit.count, 4)
    }
    
    func testDecrementMultipleTimes() {
        let trivit = Trivit(count: 10)
        
        trivit.decrement()
        trivit.decrement()
        trivit.decrement()
        
        XCTAssertEqual(trivit.count, 7)
    }
    
    func testDecrementAtZeroDoesNotGoNegative() {
        let trivit = Trivit(count: 0)
        
        trivit.decrement()
        
        XCTAssertEqual(trivit.count, 0, "Count should not go below zero")
    }
    
    func testDecrementToZero() {
        let trivit = Trivit(count: 1)
        
        trivit.decrement()
        
        XCTAssertEqual(trivit.count, 0)
    }
    
    // MARK: - Reset Tests
    
    func testReset() {
        let trivit = Trivit(count: 100)
        
        trivit.reset()
        
        XCTAssertEqual(trivit.count, 0)
    }
    
    func testResetAlreadyZero() {
        let trivit = Trivit(count: 0)
        
        trivit.reset()
        
        XCTAssertEqual(trivit.count, 0)
    }
    
    func testResetPreservesOtherProperties() {
        let id = UUID()
        let date = Date()
        let trivit = Trivit(
            id: id,
            title: "Test Counter",
            count: 50,
            colorIndex: 3,
            isCollapsed: false,
            createdAt: date
        )
        
        trivit.reset()
        
        XCTAssertEqual(trivit.count, 0)
        XCTAssertEqual(trivit.id, id)
        XCTAssertEqual(trivit.title, "Test Counter")
        XCTAssertEqual(trivit.colorIndex, 3)
        XCTAssertFalse(trivit.isCollapsed)
        XCTAssertEqual(trivit.createdAt, date)
    }
    
    // MARK: - Equality Tests
    
    func testEqualityWithSameId() {
        let id = UUID()
        let trivit1 = Trivit(id: id, title: "Counter 1", count: 10)
        let trivit2 = Trivit(id: id, title: "Counter 2", count: 20)
        
        XCTAssertEqual(trivit1, trivit2, "Trivits with same ID should be equal")
    }
    
    func testInequalityWithDifferentId() {
        let trivit1 = Trivit(title: "Counter", count: 10)
        let trivit2 = Trivit(title: "Counter", count: 10)
        
        XCTAssertNotEqual(trivit1, trivit2, "Trivits with different IDs should not be equal")
    }
    
    // MARK: - Combined Operations Tests
    
    func testIncrementThenDecrement() {
        let trivit = Trivit(count: 5)
        
        trivit.increment()
        trivit.increment()
        trivit.decrement()
        
        XCTAssertEqual(trivit.count, 6)
    }
    
    func testIncrementThenReset() {
        let trivit = Trivit(count: 0)
        
        trivit.increment()
        trivit.increment()
        trivit.increment()
        trivit.reset()
        
        XCTAssertEqual(trivit.count, 0)
    }
    
    func testManyDecrementsBelowZero() {
        let trivit = Trivit(count: 2)
        
        trivit.decrement()
        trivit.decrement()
        trivit.decrement()
        trivit.decrement()
        trivit.decrement()
        
        XCTAssertEqual(trivit.count, 0, "Multiple decrements should stop at zero")
    }
}
