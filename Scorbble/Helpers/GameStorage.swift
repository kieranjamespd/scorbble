//
//  GameStorage.swift
//  Scorbble
//
//  Created by Kieran James on 07.12.25.
//

import Foundation
import Combine

/// Handles saving and loading game history
class GameStorage: ObservableObject {
    
    // Shared instance
    static let shared = GameStorage()
    
    // Published property so views update when games change
    @Published var savedGames: [SavedGame] = []
    
    // UserDefaults key
    private let storageKey = "savedGames"
    
    init() {
        loadGames()
    }
    
    // MARK: - Public Methods
    
    /// Save a completed game
    func saveGame(_ game: SavedGame) {
        savedGames.insert(game, at: 0) // Add to beginning (most recent first)
        persistGames()
    }
    
    /// Save a game from active players
    func saveGame(players: [Player]) {
        let game = SavedGame(from: players)
        saveGame(game)
        
        // Update player profile stats
        updatePlayerProfileStats(players: players, winnerName: game.winnerName)
    }
    
    /// Update profile stats for all players in a game
    private func updatePlayerProfileStats(players: [Player], winnerName: String) {
        let isTie = winnerName == "Tie"
        
        for player in players {
            // Determine if this player won (not a tie and they're the winner)
            let didWin = !isTie && player.name == winnerName
            
            // Update their profile stats
            ProfileStorage.shared.updateStats(
                for: player.name,
                score: player.score,
                didWin: didWin
            )
        }
    }
    
    /// Delete a game
    func deleteGame(_ game: SavedGame) {
        savedGames.removeAll { $0.id == game.id }
        persistGames()
    }
    
    /// Delete a game at index
    func deleteGame(at index: Int) {
        guard index < savedGames.count else { return }
        savedGames.remove(at: index)
        persistGames()
    }
    
    /// Clear all game history
    func clearAllGames() {
        savedGames = []
        persistGames()
    }
    
    // MARK: - Statistics
    
    /// Total games played
    var totalGamesPlayed: Int {
        savedGames.count
    }
    
    /// Get win counts for each player (excludes ties)
    var leaderboard: [(name: String, wins: Int)] {
        var winCounts: [String: Int] = [:]
        
        for game in savedGames {
            // Don't count ties as wins
            if game.winnerName != "Tie" {
                winCounts[game.winnerName, default: 0] += 1
            }
        }
        
        return winCounts
            .map { (name: $0.key, wins: $0.value) }
            .sorted { $0.wins > $1.wins }
    }
    
    /// Highest score ever
    var highestScore: (name: String, score: Int)? {
        var highest: (name: String, score: Int)? = nil
        
        for game in savedGames {
            for player in game.players {
                if highest == nil || player.score > highest!.score {
                    highest = (name: player.name, score: player.score)
                }
            }
        }
        
        return highest
    }
    
    /// Average game score
    var averageGameScore: Int {
        guard !savedGames.isEmpty else { return 0 }
        let totalPoints = savedGames.reduce(0) { $0 + $1.totalPoints }
        let totalPlayers = savedGames.reduce(0) { $0 + $1.playerCount }
        guard totalPlayers > 0 else { return 0 }
        return totalPoints / totalPlayers
    }
    
    // MARK: - Private Methods
    
    /// Load games from UserDefaults
    private func loadGames() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            savedGames = []
            return
        }
        
        do {
            let decoder = JSONDecoder()
            savedGames = try decoder.decode([SavedGame].self, from: data)
            print("Loaded \(savedGames.count) saved games")
        } catch {
            print("Failed to load saved games: \(error)")
            savedGames = []
        }
    }
    
    /// Save games to UserDefaults
    private func persistGames() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(savedGames)
            UserDefaults.standard.set(data, forKey: storageKey)
            print("Saved \(savedGames.count) games")
        } catch {
            print("Failed to save games: \(error)")
        }
    }
}

