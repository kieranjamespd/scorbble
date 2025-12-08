//
//  SavedGame.swift
//  Scorbble
//
//  Created by Kieran James on 07.12.25.
//

import SwiftUI

/// A completed game that can be saved and loaded
struct SavedGame: Identifiable, Codable {
    let id: UUID
    let date: Date
    let players: [SavedPlayer]
    let winnerName: String
    let winnerScore: Int
    
    init(id: UUID = UUID(), date: Date = Date(), players: [SavedPlayer], winnerName: String, winnerScore: Int) {
        self.id = id
        self.date = date
        self.players = players
        self.winnerName = winnerName
        self.winnerScore = winnerScore
    }
    
    /// Create a SavedGame from active game players
    init(from players: [Player]) {
        self.id = UUID()
        self.date = Date()
        self.players = players.map { SavedPlayer(from: $0) }
        
        // Find the highest score
        let highestScore = players.map { $0.score }.max() ?? 0
        
        // Find all players with that score
        let topPlayers = players.filter { $0.score == highestScore }
        
        if topPlayers.count > 1 {
            // It's a tie!
            self.winnerName = "Tie"
            self.winnerScore = highestScore
        } else if let winner = topPlayers.first {
            self.winnerName = winner.name
            self.winnerScore = winner.score
        } else {
            self.winnerName = "Unknown"
            self.winnerScore = 0
        }
    }
    
    /// Whether the game ended in a tie
    var isTie: Bool {
        winnerName == "Tie"
    }
    
    /// Formatted date string
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    /// Short date (just the day)
    var shortDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    /// Total points scored in the game
    var totalPoints: Int {
        players.reduce(0) { $0 + $1.score }
    }
    
    /// Number of players
    var playerCount: Int {
        players.count
    }
}

/// A player's data that can be saved (simplified version of Player)
struct SavedPlayer: Identifiable, Codable {
    let id: UUID
    let name: String
    let score: Int
    let colorName: String
    
    init(id: UUID = UUID(), name: String, score: Int, colorName: String) {
        self.id = id
        self.name = name
        self.score = score
        self.colorName = colorName
    }
    
    /// Create from an active Player
    init(from player: Player) {
        self.id = player.id
        self.name = player.name
        self.score = player.score
        self.colorName = player.colorName
    }
    
    /// Get SwiftUI Color from color name
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

extension SavedGame {
    static let mockGames: [SavedGame] = [
        SavedGame(
            date: Date(),
            players: [
                SavedPlayer(name: "Emma", score: 287, colorName: "purple"),
                SavedPlayer(name: "Kieran", score: 245, colorName: "blue"),
                SavedPlayer(name: "Sarah", score: 198, colorName: "green")
            ],
            winnerName: "Emma",
            winnerScore: 287
        ),
        SavedGame(
            date: Date().addingTimeInterval(-86400), // Yesterday
            players: [
                SavedPlayer(name: "Kieran", score: 312, colorName: "blue"),
                SavedPlayer(name: "Mike", score: 289, colorName: "orange")
            ],
            winnerName: "Kieran",
            winnerScore: 312
        ),
        SavedGame(
            date: Date().addingTimeInterval(-172800), // 2 days ago
            players: [
                SavedPlayer(name: "Sarah", score: 256, colorName: "green"),
                SavedPlayer(name: "Emma", score: 234, colorName: "purple"),
                SavedPlayer(name: "Kieran", score: 221, colorName: "blue"),
                SavedPlayer(name: "Mike", score: 198, colorName: "orange")
            ],
            winnerName: "Sarah",
            winnerScore: 256
        )
    ]
}

