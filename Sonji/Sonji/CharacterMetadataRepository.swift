//
//  CharacterRepository.swift
//  
//
//  Created by Daniel Schlaug on 6/15/14.
//
//
import Foundation
//import KanjiVGKit

protocol CharacterMetadataRepositoryDelegate {
    func _characterMetadataRepository(repository: CharacterMetadataRepository, didFinishLoadingMetadata metadata: CharacterMetadata, forCharacter character: Character)
    func _characterMetadataRepository(repository: CharacterMetadataRepository, didFailLoadingMetadataForCharacter character: Character, withError error: NSError!)
}

extension KVGEntry {
    class func filenameOfCharacter(character:Character) -> String {
        let characterString = String(character)
        let scalars = characterString.unicodeScalars
        let scalar = scalars[scalars.startIndex].value
        let intScalar = Int(scalar)
        let characterUnicodeScalarString = NSString(format:"%x", intScalar)
        let nZeroes = 5 - characterUnicodeScalarString.length
        let prefix = "".stringByPaddingToLength(nZeroes, withString: "0", startingAtIndex: 0)
        let KVGFilename = prefix + characterUnicodeScalarString + ".svg";
        return KVGFilename
    }
}

class CharacterMetadataRepository: NSObject {
    
    var _URLSession: NSURLSession
    var _loadingCharacters: Dictionary<Character, (KVGEntry?, WWWJDICEntry?)> = [:]
    
    let delegate: CharacterMetadataRepositoryDelegate
    let delegateQueue: NSOperationQueue
    
    init(delegate: CharacterMetadataRepositoryDelegate, delegateQueue:NSOperationQueue = NSOperationQueue.mainQueue()) {
        self.delegate = delegate
        self.delegateQueue = delegateQueue
        _URLSession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
    }
    
    func loadCharacterMetadataFor(character: Character) {
        
        let alreadyLoadingCharacter = _loadingCharacters[character] ? true : false
        
        if !alreadyLoadingCharacter {
            
            _loadingCharacters[character] = (nil, nil)
            
            let urlEscapedCharacter = String(character).stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
            let KVGFilename = KVGEntry.filenameOfCharacter(character)
            let kanjiVGURL = NSURL.URLWithString("https://raw.github.com/KanjiVG/kanjivg/master/kanji/\(KVGFilename)")
            let wwwjdicURL = NSURL.URLWithString("http://www.csse.monash.edu.au/~jwb/cgi-bin/wwwjdic.cgi?1ZMJ\(urlEscapedCharacter)")

            let kanjiVGDownloadTask = _URLSession.dataTaskWithURL(kanjiVGURL) {
                (data, response, error) in
                
                if error {
                    self._failLoadingMetadataForCharacter(character, withError: error)
                    return
                }
                
                var optionalKVGEntry = KVGEntry.entryFromData(data)
                
                if let kvgEntry = optionalKVGEntry {
                    let (_, optionalWWWJDICEntry) = self._loadingCharacters[character]!
                    self._loadingCharacters[character] = (optionalKVGEntry, optionalWWWJDICEntry)
                    self._maybeFinishedLoadingMetadataForCharacter(character)
                } else {
                    self._failLoadingMetadataForCharacter(character, withError: nil) //TODO Sensible error
                }
                
            }
            let wwwjdicDownloadTask = _URLSession.dataTaskWithURL(wwwjdicURL) {
                (data, response, error) in
                
                if error {
                    self._failLoadingMetadataForCharacter(character, withError: error)
                    return
                }
                
                var optionalWWWJDICEntry = WWWJDICEntry.entryFromRawWWWJDICResponse(NSString(data: data, encoding: NSUTF8StringEncoding))
                
                if let WWWJDICEntry = optionalWWWJDICEntry {
                    let (optionalKVGEntry, _) = self._loadingCharacters[character]!
                    self._loadingCharacters[character] = (optionalKVGEntry, WWWJDICEntry)
                    self._maybeFinishedLoadingMetadataForCharacter(character)
                } else {
                    self._failLoadingMetadataForCharacter(character, withError: nil) //TODO Sensible error
                }
            }
            
            kanjiVGDownloadTask.resume()
            wwwjdicDownloadTask.resume()
        }
    }
    
    func _maybeFinishedLoadingMetadataForCharacter(character: Character) {
        if let (kvg, jdic) = _loadingCharacters[character] {
            if kvg && jdic {
                let metadata = CharacterMetadata(kvg: kvg!, wwwjdic: jdic!)
                self.delegateQueue.addOperationWithBlock {
                    self.delegate._characterMetadataRepository(self, didFinishLoadingMetadata:metadata, forCharacter: character)
                }
            }
        }
    }
    
    func _failLoadingMetadataForCharacter(character: Character, withError error:NSError?) {
        self.delegateQueue.addOperationWithBlock{
            self.delegate._characterMetadataRepository(self, didFailLoadingMetadataForCharacter: character, withError: error)
        }
    }
    
}
