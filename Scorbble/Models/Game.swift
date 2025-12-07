//
//  Game.swift
//  Scorbble
//
//  Created by Kieran James on 07.12.25.
//

import Foundation

/// A Scrabble game session
/// - id: Unique identifier for this game
/// - players: The players in this game (2-4)
/// - currentPlayerIndex: Index of the player whose turn it is
/// - isFinished: Whether the game has ended
/// - date: When the game was created
struct Game: Identifiable {
    let id = UUID()
    var players: [Player]
    var currentPlayerIndex: Int = 0
    var isFinished: Bool = false
    let date: Date
    
    /// The player whose turn it currently is
    var currentPlayer: Player {
        players[currentPlayerIndex]
    }
    
    /// Move to the next player's turn
    mutating func nextTurn() {
        currentPlayerIndex = (currentPlayerIndex + 1) % players.count
    }
    
    /// Add points to a specific player
    mutating func addScore(to playerIndex: Int, points: Int) {
        players[playerIndex].score += points
    }
    
    /// Find the player with the highest score
    var leader: Player? {
        players.max(by: { $0.score < $1.score })
    }
    
    /// End the game
    mutating func endGame() {
        isFinished = true
    }
}

// MARK: - Mock Data for Previews

extension Game {
    /// A sample game in progress for testing and previews
    static let mockGame = Game(
        players: Player.mockPlayers,
        currentPlayerIndex: 1,
        isFinished: false,
        date: Date()
    )
    
    /// A sample finished game
    static let mockFinishedGame = Game(
        players: Player.mockPlayers,
        currentPlayerIndex: 0,
        isFinished: true,
        date: Date().addingTimeInterval(-86400) // Yesterday
    )
}

