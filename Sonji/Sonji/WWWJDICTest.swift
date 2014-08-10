//
//  testWWWJDIC.swift
//  KEX
//
//  Created by Daniel Schlaug on 6/11/14.
//  Copyright (c) 2014 Daniel Schlaug. All rights reserved.
//

import XCTest

class WWWJDICTest: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testSynchroneousCreation() {

        let optionalEntry : WWWJDICEntry? = WWWJDICEntry.downloadEntryForCharacter("選")
        if !optionalEntry {
            XCTFail("downloadEntryForCharacter returned nil")
        }
        if let entry = optionalEntry {
            XCTAssertEqual(entry.character, "選")
            XCTAssertGreaterThan(entry.translations.count, 0)
            XCTAssertTrue(entry.translations.filter {$0 == "elect"}.count > 0, "Entry did not contain translation elect")
        }

    }
    
    func testAsynchroneousCreation() {
        var expectEntry = self.expectationWithDescription("async kanji download")
        
        WWWJDICEntry.asyncDownloadEntryForCharacter("選", withCallback:{(optionalEntry: WWWJDICEntry?) in
            if !optionalEntry {
                XCTFail("asyncDownloadEntryForCharacter returned nil")
            }
            if let entry = optionalEntry {
                XCTAssertEqual(entry.character, "選")
                XCTAssertGreaterThan(entry.translations.count, 0)
            }
            expectEntry.fulfill()
            })
        
        self.waitForExpectationsWithTimeout(3, handler:nil)
    }
    
    func testMultiWordTranslation() {
        let optionalEntry : WWWJDICEntry? = WWWJDICEntry.downloadEntryForCharacter("田")
        if !optionalEntry {
            XCTFail("downloadEntryForCharacter returned nil")
        }
        if let entry = optionalEntry {
            XCTAssertEqual(entry.character, "田")
            XCTAssertGreaterThan(entry.translations.count, 0)
            XCTAssertTrue(entry.translations.filter {$0 == "rice paddy"}.count > 0, "Entry did not contain translation rice paddy: \(entry.translations)")
        }
    }

//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measureBlock() {
//            // Put the code you want to measure the time of here.
//        }
//    }

}
