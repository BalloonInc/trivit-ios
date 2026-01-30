//
//  SwiftDataIntegrationTests.swift
//  trivitTests
//
//  Integration tests for SwiftData persistence
//

import XCTest
import SwiftData
@testable import trivit

@MainActor
final class SwiftDataIntegrationTests: XCTestCase {
    
    var container: ModelContainer!
    var context: ModelContext!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory container for testing
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: Trivit.self, configurations: config)
        context = container.mainContext
    }
    
    override func tearDown() async throws {
        container = nil
        context = nil
        try await super.tearDown()
    }
    
    // MARK: - Basic CRUD Tests
    
    func testInsertTrivit() throws {
        let trivit = Trivit(title: "Test Counter", count: 5)
        
        context.insert(trivit)
        try context.save()
        
        let descriptor = FetchDescriptor<Trivit>()
        let results = try context.fetch(descriptor)
        
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "Test Counter")
        XCTAssertEqual(results.first?.count, 5)
    }
    
    func testUpdateTrivit() throws {
        let trivit = Trivit(title: "Test Counter", count: 5)
        context.insert(trivit)
        try context.save()
        
        trivit.count = 10
        trivit.title = "Updated Counter"
        try context.save()
        
        let descriptor = FetchDescriptor<Trivit>()
        let results = try context.fetch(descriptor)
        
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "Updated Counter")
        XCTAssertEqual(results.first?.count, 10)
    }
    
    func testDeleteTrivit() throws {
        let trivit = Trivit(title: "Test Counter", count: 5)
        context.insert(trivit)
        try context.save()
        
        context.delete(trivit)
        try context.save()
        
        let descriptor = FetchDescriptor<Trivit>()
        let results = try context.fetch(descriptor)
        
        XCTAssertTrue(results.isEmpty)
    }
    
    func testFetchMultipleTrivits() throws {
        let trivit1 = Trivit(title: "Counter 1", count: 1, createdAt: Date())
        let trivit2 = Trivit(title: "Counter 2", count: 2, createdAt: Date().addingTimeInterval(1))
        let trivit3 = Trivit(title: "Counter 3", count: 3, createdAt: Date().addingTimeInterval(2))
        
        context.insert(trivit1)
        context.insert(trivit2)
        context.insert(trivit3)
        try context.save()
        
        let descriptor = FetchDescriptor<Trivit>(sortBy: [SortDescriptor(\.createdAt)])
        let results = try context.fetch(descriptor)
        
        XCTAssertEqual(results.count, 3)
        XCTAssertEqual(results[0].title, "Counter 1")
        XCTAssertEqual(results[1].title, "Counter 2")
        XCTAssertEqual(results[2].title, "Counter 3")
    }
    
    // MARK: - Model Operations Persistence Tests
    
    func testIncrementPersists() throws {
        let trivit = Trivit(title: "Test Counter", count: 5)
        context.insert(trivit)
        try context.save()
        let originalId = trivit.id
        
        trivit.increment()
        try context.save()
        
        let descriptor = FetchDescriptor<Trivit>(predicate: #Predicate { $0.id == originalId })
        let results = try context.fetch(descriptor)
        
        XCTAssertEqual(results.first?.count, 6)
    }
    
    func testDecrementPersists() throws {
        let trivit = Trivit(title: "Test Counter", count: 5)
        context.insert(trivit)
        try context.save()
        let originalId = trivit.id
        
        trivit.decrement()
        try context.save()
        
        let descriptor = FetchDescriptor<Trivit>(predicate: #Predicate { $0.id == originalId })
        let results = try context.fetch(descriptor)
        
        XCTAssertEqual(results.first?.count, 4)
    }
    
    func testResetPersists() throws {
        let trivit = Trivit(title: "Test Counter", count: 100)
        context.insert(trivit)
        try context.save()
        let originalId = trivit.id
        
        trivit.reset()
        try context.save()
        
        let descriptor = FetchDescriptor<Trivit>(predicate: #Predicate { $0.id == originalId })
        let results = try context.fetch(descriptor)
        
        XCTAssertEqual(results.first?.count, 0)
    }
    
    // MARK: - SwiftDataTrivitRepository Tests
    
    func testRepositoryFetchAll() async throws {
        let trivit1 = Trivit(title: "Counter 1", count: 1)
        let trivit2 = Trivit(title: "Counter 2", count: 2)
        context.insert(trivit1)
        context.insert(trivit2)
        try context.save()
        
        let repository = SwiftDataTrivitRepository(modelContext: context)
        let results = try await repository.fetchAll()
        
        XCTAssertEqual(results.count, 2)
    }
    
    func testRepositoryInsert() async throws {
        let repository = SwiftDataTrivitRepository(modelContext: context)
        let trivit = Trivit(title: "New Counter", count: 0)
        
        try await repository.insert(trivit)
        
        let descriptor = FetchDescriptor<Trivit>()
        let results = try context.fetch(descriptor)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "New Counter")
    }
    
    func testRepositoryDelete() async throws {
        let trivit = Trivit(title: "Counter to Delete", count: 5)
        context.insert(trivit)
        try context.save()
        
        let repository = SwiftDataTrivitRepository(modelContext: context)
        try await repository.delete(trivit)
        
        let descriptor = FetchDescriptor<Trivit>()
        let results = try context.fetch(descriptor)
        XCTAssertTrue(results.isEmpty)
    }
    
    // MARK: - Edge Cases
    
    func testEmptyFetch() throws {
        let descriptor = FetchDescriptor<Trivit>()
        let results = try context.fetch(descriptor)
        
        XCTAssertTrue(results.isEmpty)
    }
    
    func testTrivitWithAllProperties() throws {
        let id = UUID()
        let date = Date()
        let trivit = Trivit(
            id: id,
            title: "Full Counter",
            count: 42,
            colorIndex: 7,
            isCollapsed: false,
            createdAt: date
        )
        
        context.insert(trivit)
        try context.save()
        
        let descriptor = FetchDescriptor<Trivit>()
        let results = try context.fetch(descriptor)
        
        XCTAssertEqual(results.count, 1)
        let fetched = results.first!
        XCTAssertEqual(fetched.id, id)
        XCTAssertEqual(fetched.title, "Full Counter")
        XCTAssertEqual(fetched.count, 42)
        XCTAssertEqual(fetched.colorIndex, 7)
        XCTAssertFalse(fetched.isCollapsed)
        XCTAssertEqual(fetched.createdAt, date)
    }
}
