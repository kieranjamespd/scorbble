//
//  Player.swift
//  Scorbble
//
//  Created by Kieran James on 07.12.25.
//

import SwiftUI

/// A player in a Scrabble game
/// - id: Unique identifier for this player
/// - name: The player's display name
/// - score: Their current total score
/// - colorName: A color to visually distinguish them
/// - emoji: An emoji avatar for the player
struct Player: Identifiable {
    let id = UUID()
    var name: String
    var score: Int = 0
    var colorName: String
    var emoji: String = "😊"
    
    /// Returns the SwiftUI Color for this player
    var color: Color {
        switch colorName {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "red": return .red
        case "pink": return .pink
        default: return .gray
        }
    }
}

// MARK: - Mock Data for Previews
// This lets us see realistic data in our UI previews

extension Player {
    /// Sample players for testing and previews
    static let mockPlayers: [Player] = [
        Player(name: "Kieran", score: 127, colorName: "blue", emoji: "😎"),
        Player(name: "Sarah", score: 143, colorName: "green", emoji: "🦊"),
        Player(name: "Mike", score: 98, colorName: "orange", emoji: "🎯"),
        Player(name: "Emma", score: 156, colorName: "purple", emoji: "🦄")
    ]
    
    /// Available colors for players to choose
    static let availableColors = ["blue", "green", "orange", "purple", "red", "pink"]
    
    /// Available emojis for player avatars
    static let availableEmojis = [
        // Faces
        "😊", "😎", "🤓", "😏", "🧐", "🤠", "😈", "👻",
        // Animals
        "🦊", "🐱", "🐶", "🦁", "🐼", "🦄", "🐸", "🦉",
        // Objects & Symbols
        "⭐️", "🎯", "🎲", "🎪", "🚀", "💎", "🔥", "⚡️",
        // Food & Nature
        "🌸", "🌵", "🍀", "🌙", "🌈", "🍕", "🎸", "🎨"
    ]
}

