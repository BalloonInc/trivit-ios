//
//  TrivitRepositoryTests.swift
//  trivitTests
//
//  Unit tests for TrivitRepository
//

import XCTest
import SwiftData
@testable import trivit

final class TrivitRepositoryTests: XCTestCase {
    
    // MARK: - Mock Repository Tests
    
    func testMockRepositoryFetchAllReturnsEmptyInitially() async throws {
        let repository = MockTrivitRepository()
        
        let trivits = try await repository.fetchAll()
        
        XCTAssertTrue(trivits.isEmpty)
    }
    
    func testMockRepositoryInsert() async throws {
        let repository = MockTrivitRepository()
        let trivit = Trivit(title: "Test Counter", count: 5)
        
        try await repository.insert(trivit)
        
        XCTAssertTrue(repository.insertCalled)
        let trivits = try await repository.fetchAll()
        XCTAssertEqual(trivits.count, 1)
        XCTAssertEqual(trivits.first?.title, "Test Counter")
    }
    
    func testMockRepositoryDelete() async throws {
        let repository = MockTrivitRepository()
        let trivit = Trivit(title: "Test Counter", count: 5)
        try await repository.insert(trivit)
        
        try await repository.delete(trivit)
        
        XCTAssertTrue(repository.deleteCalled)
        let trivits = try await repository.fetchAll()
        XCTAssertTrue(trivits.isEmpty)
    }
    
    func testMockRepositorySave() async throws {
        let repository = MockTrivitRepository()
        let trivit = Trivit(title: "Test Counter", count: 5)
        
        try await repository.save(trivit)
        
        XCTAssertTrue(repository.saveCalled)
    }
    
    func testMockRepositoryInsertMultiple() async throws {
        let repository = MockTrivitRepository()
        
        try await repository.insert(Trivit(title: "Counter 1", count: 1))
        try await repository.insert(Trivit(title: "Counter 2", count: 2))
        try await repository.insert(Trivit(title: "Counter 3", count: 3))
        
        let trivits = try await repository.fetchAll()
        XCTAssertEqual(trivits.count, 3)
    }
    
    func testMockRepositoryDeleteSpecificItem() async throws {
        let repository = MockTrivitRepository()
        let trivit1 = Trivit(title: "Counter 1", count: 1)
        let trivit2 = Trivit(title: "Counter 2", count: 2)
        
        try await repository.insert(trivit1)
        try await repository.insert(trivit2)
        try await repository.delete(trivit1)
        
        let trivits = try await repository.fetchAll()
        XCTAssertEqual(trivits.count, 1)
        XCTAssertEqual(trivits.first?.title, "Counter 2")
    }
}
