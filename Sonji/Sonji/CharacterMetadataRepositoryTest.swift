//
//  CharacterMEtadataRepositoryTest.swift
//  KEX
//
//  Created by Daniel Schlaug on 6/16/14.
//  Copyright (c) 2014 Daniel Schlaug. All rights reserved.
//

import XCTest
import Foundation

class CharacterMetadataRepositoryTest: XCTestCase, CharacterMetadataRepositoryDelegate {
    
    var repo:CharacterMetadataRepository!
    
    var metadataRetrievalSuccessExpectedForCharacter: Dictionary<String, XCTestExpectation> = [:]
    var metadataRetrievalFailureExpectedForCharacter: Dictionary<String, XCTestExpectation> = [:]
    
    var optionalSuccessExpectation: XCTestExpectation?
    var optionalFailExpectation: XCTestExpectation?
    var returnedMetadata: CharacterMetadata?
    
    

    override func setUp() {
        super.setUp()
        if !repo {
            repo = CharacterMetadataRepository(delegate:self, delegateQueue:NSOperationQueue())
        }
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testGoodCharacterRetrieval() {
        repo.loadCharacterMetadataFor("選")
        optionalSuccessExpectation = self.expectationWithDescription("Expecting character metadata for 選")
        self.waitForExpectationsWithTimeout(3, handler: nil)
        if !returnedMetadata {
            XCTFail("Didn't return metadata.")
        }
        if let metadata = returnedMetadata {
            XCTAssertEqual(metadata.translations.filter {$0 == "elect"}.count, 1, "選 did not translate to elect")
            XCTAssertEqual(metadata.kunReadings.filter {$0 == "えら.ぶ"}.count, 1, "選 did not have reading えら.ぶ")
            XCTAssertEqual(metadata.strokes.count, 15, "選 had the wrong number of strokes")
        }
    }
    
    func testBadCharacterRetrieval() {
        repo.loadCharacterMetadataFor("/")
        optionalFailExpectation = self.expectationWithDescription("Not expecting character metadata for /")
        self.waitForExpectationsWithTimeout(3, handler: nil)
    }

    
    //MARK - Character Metadata Repository Delegate
    func _characterMetadataRepository(repository: CharacterMetadataRepository, didFinishLoadingMetadata metadata: CharacterMetadata, forCharacter: Character){
        
        returnedMetadata = metadata
        if let expectation = optionalSuccessExpectation {
            expectation.fulfill()
        }
        
    }
    
    func _characterMetadataRepository(repository: CharacterMetadataRepository, didFailLoadingMetadataForCharacter character: Character, withError error: NSError!) {
        returnedMetadata = nil
        if let expectation = optionalFailExpectation {
            expectation.fulfill()
        }
    }
    
}
