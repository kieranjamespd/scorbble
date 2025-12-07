//
//  ScrabbleHelpers.swift
//  Scorbble
//
//  Created by Kieran James on 07.12.25.
//

import Foundation

/// Helper functions for Scrabble scoring and word validation

// MARK: - Letter Point Values

/// Returns the Scrabble point value for a letter
func scrabblePoints(for letter: Character) -> Int {
    switch letter.uppercased().first ?? " " {
    // 1 point
    case "A", "E", "I", "O", "U", "L", "N", "S", "T", "R":
        return 1
    // 2 points
    case "D", "G":
        return 2
    // 3 points
    case "B", "C", "M", "P":
        return 3
    // 4 points
    case "F", "H", "V", "W", "Y":
        return 4
    // 5 points
    case "K":
        return 5
    // 8 points
    case "J", "X":
        return 8
    // 10 points
    case "Q", "Z":
        return 10
    default:
        return 0
    }
}

// MARK: - Score Calculation

/// Represents a letter tile with its bonus multiplier
struct LetterTile: Identifiable {
    let id = UUID()
    let letter: Character
    var multiplier: Int = 1  // 1 = normal, 2 = double letter, 3 = triple letter
    
    var basePoints: Int {
        scrabblePoints(for: letter)
    }
    
    var points: Int {
        basePoints * multiplier
    }
}

/// Calculate total score for a word with letter and word multipliers
func calculateWordScore(tiles: [LetterTile], wordMultiplier: Int) -> Int {
    let letterTotal = tiles.reduce(0) { $0 + $1.points }
    return letterTotal * wordMultiplier
}

// MARK: - Word Validation

/// A simple word validator
/// In a real app, this would use a dictionary API or local word database
/// For now, we'll use a basic list of common Scrabble words
class WordValidator {
    
    // A small sample of valid Scrabble words for demo purposes
    // In production, this would be a much larger dictionary
    static let sampleWords: Set<String> = [
        // Common short words
        "a", "an", "at", "be", "do", "go", "he", "hi", "if", "in", "is", "it",
        "me", "my", "no", "of", "on", "or", "so", "to", "up", "us", "we",
        // Common 3-letter words
        "the", "and", "for", "are", "but", "not", "you", "all", "can", "her",
        "was", "one", "our", "out", "day", "get", "has", "him", "his", "how",
        "its", "let", "may", "new", "now", "old", "see", "two", "way", "who",
        "boy", "did", "own", "say", "she", "too", "use", "cat", "dog", "run",
        "box", "fox", "hat", "mat", "rat", "sat", "bat", "pet", "set", "wet",
        // Common 4+ letter words
        "that", "with", "have", "this", "will", "your", "from", "they", "been",
        "call", "come", "made", "find", "more", "word", "work", "year", "over",
        "such", "take", "into", "just", "know", "back", "only", "look", "also",
        "game", "play", "life", "time", "love", "home", "hand", "good", "great",
        "help", "make", "want", "give", "most", "very", "after", "think", "about",
        // Fun Scrabble words with high-value letters
        "jazz", "quiz", "jinx", "lynx", "maze", "zone", "zero", "zest",
        "queen", "quick", "quiet", "quartz", "pixel", "proxy", "pizza",
        "kayak", "kiosk", "knock", "knack", "joker", "jumbo", "juice",
        "extra", "exact", "excel", "exotic", "expect", "expert",
        "world", "words", "write", "wrong", "wrist",
        "value", "valid", "visit", "voice", "video",
        // More common words
        "hello", "world", "phone", "water", "house", "money", "party",
        "music", "movie", "night", "light", "right", "white", "black",
        "green", "table", "chair", "happy", "funny", "crazy", "smart"
    ]
    
    /// Check if a word is valid
    /// For the demo, accepts words from our sample list OR any word 2+ letters
    /// (In production, would check against full Scrabble dictionary)
    static func isValid(_ word: String) -> Bool {
        let cleaned = word.lowercased().trimmingCharacters(in: .whitespaces)
        
        // Must be at least 2 letters
        guard cleaned.count >= 2 else { return false }
        
        // Must only contain letters
        guard cleaned.allSatisfy({ $0.isLetter }) else { return false }
        
        // For demo: accept if in our sample list, otherwise show as "unverified"
        // This way users can still play with any word
        return true
    }
    
    /// Check if word is in our known dictionary
    static func isKnownWord(_ word: String) -> Bool {
        let cleaned = word.lowercased().trimmingCharacters(in: .whitespaces)
        return sampleWords.contains(cleaned)
    }
    
    /// Returns validation status
    static func validationStatus(_ word: String) -> WordValidationStatus {
        let cleaned = word.lowercased().trimmingCharacters(in: .whitespaces)
        
        guard cleaned.count >= 2 else { return .tooShort }
        guard cleaned.allSatisfy({ $0.isLetter }) else { return .invalid }
        
        if sampleWords.contains(cleaned) {
            return .valid
        } else {
            return .unverified  // Word might be valid, just not in our small demo list
        }
    }
}

enum WordValidationStatus {
    case valid       // Confirmed valid word
    case unverified  // Could be valid, not in our demo dictionary
    case invalid     // Contains non-letters
    case tooShort    // Less than 2 letters
    
    var message: String {
        switch self {
        case .valid: return "Valid word ✓"
        case .unverified: return "Word accepted"
        case .invalid: return "Invalid characters"
        case .tooShort: return "Enter a word"
        }
    }
    
    var isAcceptable: Bool {
        self == .valid || self == .unverified
    }
}

