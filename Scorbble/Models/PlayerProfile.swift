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
    var preferredEmoji: String
    var gamesPlayed: Int
    var totalWins: Int
    var highestScore: Int
    var lastPlayed: Date?
    
    init(
        id: UUID = UUID(),
        name: String,
        preferredColorName: String = "blue",
        preferredEmoji: String = "😊",
        gamesPlayed: Int = 0,
        totalWins: Int = 0,
        highestScore: Int = 0,
        lastPlayed: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.preferredColorName = preferredColorName
        self.preferredEmoji = preferredEmoji
        self.gamesPlayed = gamesPlayed
        self.totalWins = totalWins
        self.highestScore = highestScore
        self.lastPlayed = lastPlayed
    }
    
    // Custom decoder to handle existing profiles without emoji
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        preferredColorName = try container.decode(String.self, forKey: .preferredColorName)
        preferredEmoji = try container.decodeIfPresent(String.self, forKey: .preferredEmoji) ?? "😊"
        gamesPlayed = try container.decode(Int.self, forKey: .gamesPlayed)
        totalWins = try container.decode(Int.self, forKey: .totalWins)
        highestScore = try container.decode(Int.self, forKey: .highestScore)
        lastPlayed = try container.decodeIfPresent(Date.self, forKey: .lastPlayed)
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

