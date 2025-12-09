//
//  PlayerProfile.swift
//  Scorbble
//
//  Created by Kieran James on 09.12.25.
//

import SwiftUI

/// A saved player profile for quick selection
struct PlayerProfile: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var preferredColorName: String
    var gamesPlayed: Int
    var totalWins: Int
    var highestScore: Int
    var lastPlayed: Date?
    
    init(
        id: UUID = UUID(),
        name: String,
        preferredColorName: String = "blue",
        gamesPlayed: Int = 0,
        totalWins: Int = 0,
        highestScore: Int = 0,
        lastPlayed: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.preferredColorName = preferredColorName
        self.gamesPlayed = gamesPlayed
        self.totalWins = totalWins
        self.highestScore = highestScore
        self.lastPlayed = lastPlayed
    }
    
    /// Get SwiftUI Color from color name
    var preferredColor: Color {
        switch preferredColorName {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "red": return .red
        case "pink": return .pink
        default: return .blue
        }
    }
    
    /// Win rate as percentage
    var winRate: Int {
        guard gamesPlayed > 0 else { return 0 }
        return Int((Double(totalWins) / Double(gamesPlayed)) * 100)
    }
}

