//
//  ActiveType.swift
//  ActiveLabel
//
//  Created by Johannes Schickling on 9/4/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation

enum ActiveElement {
    case mention(String)
    case hashtag(String)
    case url(String)
    case custom(String)
    case none
}

public enum ActiveType {
    case mention
    case hashtag
    case url
    case custom
    case none
}

typealias ActiveFilterPredicate = ((String) -> Bool)

struct ActiveBuilder {
    static func createCustomElements(fromText text: String, range: NSRange, targetTexts: [String]) -> [(range: NSRange, element: ActiveElement)] {
        var elements: [(range: NSRange, element: ActiveElement)] = []
        
        targetTexts.forEach { (targetText) in
            let founds = RegexParser.getCustoms(fromText: text, targetText: targetText, range: range)
            
            elements.append(
                contentsOf: founds.map{ found in
                    return (found.range, ActiveElement.custom(targetText))
                }
            )
        }
        
        return elements
    }
    
    static func createCustomElementsOnFirstFoundTarget(fromText text: String, range: NSRange, targetTexts: [String]) -> [(range: NSRange, element: ActiveElement)] {
        
        var elements: [(range: NSRange, element: ActiveElement)] = []
        
        targetTexts.forEach { (targetText) in
            let founds = RegexParser.getCustoms(fromText: text, targetText: targetText, range: range)
            
            if let found = founds.first {
                elements.append((found.range, ActiveElement.custom(targetText)))
            }
        }
        
        return elements
    }
    
    static func createCustomElementsOnFirstFoundTargetFromBack(fromText text: String, range: NSRange, targetTexts: [String]) -> [(range: NSRange, element: ActiveElement)] {
        
        var elements: [(range: NSRange, element: ActiveElement)] = []
        
        targetTexts.forEach { (targetText) in
            let founds = RegexParser.getCustoms(fromText: text, targetText: targetText, range: range)
            
            if let found = founds.last {
                elements.append((found.range, ActiveElement.custom(targetText)))
            }
        }
        
        return elements       
    }
    
    static func createMentionElements(fromText text: String, range: NSRange, filterPredicate: ActiveFilterPredicate?) -> [(range: NSRange, element: ActiveElement)] {
        let mentions = RegexParser.getMentions(fromText: text, range: range)
        let nsstring = text as NSString
        var elements: [(range: NSRange, element: ActiveElement)] = []
        
        for mention in mentions where mention.range.length > 2 {
            let range = NSRange(location: mention.range.location + 1, length: mention.range.length - 1)
            var word = nsstring.substring(with: range)
            if word.hasPrefix("@") {
                word.remove(at: word.startIndex)
            }

            if filterPredicate?(word) ?? true {
                let element = ActiveElement.mention(word)
                elements.append((mention.range, element))
            }
        }
        return elements
    }
    
    static func createHashtagElements(fromText text: String, range: NSRange, filterPredicate: ActiveFilterPredicate?) -> [(range: NSRange, element: ActiveElement)] {
        let hashtags = RegexParser.getHashtags(fromText: text, range: range)
        let nsstring = text as NSString
        var elements: [(range: NSRange, element: ActiveElement)] = []
        
        for hashtag in hashtags where hashtag.range.length > 2 {
            let range = NSRange(location: hashtag.range.location + 1, length: hashtag.range.length - 1)
            var word = nsstring.substring(with: range)
            if word.hasPrefix("#") {
                word.remove(at: word.startIndex)
            }

            if filterPredicate?(word) ?? true {
                let element = ActiveElement.hashtag(word)
                elements.append((hashtag.range, element))
            }
        }
        return elements
    }
    
    static func createURLElements(fromText text: String, range: NSRange) -> [(range: NSRange, element: ActiveElement)] {
        let urls = RegexParser.getURLs(fromText: text, range: range)
        let nsstring = text as NSString
        var elements: [(range: NSRange, element: ActiveElement)] = []
        
        for url in urls where url.range.length > 2 {
            let word = nsstring.substring(with: url.range)
                .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            let element = ActiveElement.url(word)
            elements.append((url.range, element))
        }
        return elements
    }
}
