//
//  ProfileStorage.swift
//  Scorbble
//
//  Created by Kieran James on 09.12.25.
//

import Foundation
import Combine

/// Handles saving and loading player profiles
class ProfileStorage: ObservableObject {
    
    // Shared instance
    static let shared = ProfileStorage()
    
    // Published property so views update when profiles change
    @Published var profiles: [PlayerProfile] = []
    
    // UserDefaults key
    private let storageKey = "playerProfiles"
    
    init() {
        loadProfiles()
    }
    
    // MARK: - Public Methods
    
    /// Get or create a profile for a player name
    func getOrCreateProfile(name: String, colorName: String) -> PlayerProfile {
        // Check if profile exists (case-insensitive match)
        if let existing = profiles.first(where: { $0.name.lowercased() == name.lowercased() }) {
            return existing
        }
        
        // Create new profile
        let profile = PlayerProfile(name: name, preferredColorName: colorName)
        profiles.append(profile)
        persistProfiles()
        return profile
    }
    
    /// Find profile by name (case-insensitive)
    func findProfile(name: String) -> PlayerProfile? {
        profiles.first { $0.name.lowercased() == name.lowercased() }
    }
    
    /// Update profile stats after a game
    func updateStats(for playerName: String, score: Int, didWin: Bool) {
        guard let index = profiles.firstIndex(where: { $0.name.lowercased() == playerName.lowercased() }) else {
            return
        }
        
        profiles[index].gamesPlayed += 1
        profiles[index].lastPlayed = Date()
        
        if didWin {
            profiles[index].totalWins += 1
        }
        
        if score > profiles[index].highestScore {
            profiles[index].highestScore = score
        }
        
        persistProfiles()
    }
    
    /// Update preferred color for a profile
    func updatePreferredColor(for playerName: String, colorName: String) {
        guard let index = profiles.firstIndex(where: { $0.name.lowercased() == playerName.lowercased() }) else {
            return
        }
        
        profiles[index].preferredColorName = colorName
        persistProfiles()
    }
    
    /// Get profiles sorted by most recently played
    var recentProfiles: [PlayerProfile] {
        profiles.sorted { profile1, profile2 in
            guard let date1 = profile1.lastPlayed else { return false }
            guard let date2 = profile2.lastPlayed else { return true }
            return date1 > date2
        }
    }
    
    /// Get profiles matching a search query
    func searchProfiles(query: String) -> [PlayerProfile] {
        guard !query.isEmpty else { return recentProfiles }
        
        return profiles.filter { profile in
            profile.name.lowercased().contains(query.lowercased())
        }
    }
    
    /// Delete a profile
    func deleteProfile(_ profile: PlayerProfile) {
        profiles.removeAll { $0.id == profile.id }
        persistProfiles()
    }
    
    /// Clear all profiles
    func clearAllProfiles() {
        profiles = []
        persistProfiles()
    }
    
    // MARK: - Private Methods
    
    /// Load profiles from UserDefaults
    private func loadProfiles() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            profiles = []
            return
        }
        
        do {
            let decoder = JSONDecoder()
            profiles = try decoder.decode([PlayerProfile].self, from: data)
            print("Loaded \(profiles.count) player profiles")
        } catch {
            print("Failed to load profiles: \(error)")
            profiles = []
        }
    }
    
    /// Save profiles to UserDefaults
    private func persistProfiles() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(profiles)
            UserDefaults.standard.set(data, forKey: storageKey)
            print("Saved \(profiles.count) profiles")
        } catch {
            print("Failed to save profiles: \(error)")
        }
    }
}

