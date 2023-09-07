//
//  UnitTesting.swift
//  UnitTesting
//
//  Created by Apple on 07/09/2023.
//

import XCTest

let kChunkMinSize = 10

public class Chunk {
    var currentData: Data
    var lastUpdatedDate: Date
    init?(currentData: Data, lastUpdatedDate: Date) {
        guard currentData.count < kChunkMinSize else {
            return nil
        }
        self.currentData = currentData
        self.lastUpdatedDate = lastUpdatedDate
    }
    func append(data: Data) {
        guard data.count < kChunkMinSize else {
            return
        }
        
        currentData.append(data)
        lastUpdatedDate = .init()
    }
}

public class CacheChunk {
    var maxLimit: Int = 12
    private var __cache__: [String: Chunk] = [:]
    private var cacheQueue = DispatchQueue(label: "com.cache.queue", qos: .background)
    
    public func canAddNewChunk() -> Bool {
        let size = __cache__.reduce(0) { partialResult, kv in
            return partialResult + kv.value.currentData.count
        }
        return size < (maxLimit - kChunkMinSize)
    }
    
    public func save(_ value: Data, for key: String) -> Bool {
        if canAddNewChunk() {
            if let existing = get(key: key) {
                existing.append(data: value)
                return true
            }else {
                return cacheQueue.sync(flags: .barrier) {
                    if let chunk = Chunk(currentData: value, lastUpdatedDate: .init()) {
                        __cache__[key] = chunk
                        return true
                    }else {
                        return false
                    }
                }
            }
        }else {
            return false
        }
    }
    public func remove(valueFor key: String) {
        return cacheQueue.sync(flags: .barrier) {
            __cache__.removeValue(forKey: key)
        }
        
    }
    public func get(key: String) -> Chunk? {
        cacheQueue.sync {
            self.__cache__[key]
        }
    }
    // Remove All
    private func removeUnnecessoryCache() {
        return cacheQueue.sync(flags: .barrier) {
            for cache in self.__cache__ {
                if cache.value.lastUpdatedDate.timeIntervalSince1970 < Date().timeIntervalSince1970 {
                    remove(valueFor: cache.key)
                }
            }
        }
    }
}

final class UnitTesting: XCTestCase {
    let cache = CacheChunk()
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testCacheMaxLimitReach() {
        if let data = "123456789".data(using: .utf8) {
            _ = cache.save(data, for: "some_key")
            
            if let data = "123".data(using: .utf8) {
                let isSaved = cache.save(data, for: "some_key")
                XCTAssertFalse(isSaved)
                XCTAssertFalse(cache.canAddNewChunk())
            }
            
        }
    }
    func testCacheMaxLimitNotReach() {
        if let data = "1234".data(using: .utf8) {
            let isSaved = cache.save(data, for: "some_key")
            XCTAssertTrue(isSaved)
            XCTAssertTrue(cache.canAddNewChunk())
        }
    }
    func testMinChunkAppendingSuccessfully() {
        if let data = "1234".data(using: .utf8) {
            let isSaved = cache.save(data, for: "some_key")
            XCTAssertTrue(isSaved)
        }
    }
    func testMinChunkAppendingFailed() {
        if let data = "12345678".data(using: .utf8) {
            let isSaved = cache.save(data, for: "some_key")
            XCTAssertTrue(isSaved)
        }
    }
    
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

}
