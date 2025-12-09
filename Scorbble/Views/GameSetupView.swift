//
//  GameSetupView.swift
//  Scorbble
//
//  Created by Kieran James on 07.12.25.
//

import SwiftUI

struct GameSetupView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var profileStorage = ProfileStorage.shared
    
    // Players being set up for the game
    @State private var players: [PlayerSetup] = []
    @State private var newPlayerName: String = ""
    @State private var selectedColorIndex: Int = 0
    
    // Profile suggestions
    @State private var showSuggestions = false
    @FocusState private var isNameFieldFocused: Bool
    
    // Profile editing
    @State private var profileToEdit: PlayerProfile? = nil
    @State private var showProfileEditor = false
    
    // Navigation to active game
    @State private var showActiveGame = false
    @State private var gamePlayers: [Player] = []
    
    // Track which colors are already taken
    var availableColors: [String] {
        let takenColors = players.map { $0.colorName }
        return Player.availableColors.filter { !takenColors.contains($0) }
    }
    
    var canStartGame: Bool {
        players.count >= 2
    }
    
    var canAddMorePlayers: Bool {
        players.count < 4
    }
    
    var body: some View {
        ZStack {
            // Background gradient (same as HomeView)
            LinearGradient(
                colors: [Color(hex: "1a1a2e"), Color(hex: "16213e")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                header
                
                // Player List
                playerList
                
                // Add Player Section
                if canAddMorePlayers {
                    addPlayerSection
                }
                
                Spacer()
                
                // Start Game Button
                startGameButton
            }
            .padding(24)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Back")
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .navigationDestination(isPresented: $showActiveGame) {
            ActiveGameView(
                onReturnHome: {
                    // When user taps "Back to Home" after game ends,
                    // First dismiss ActiveGameView, then after a brief delay dismiss GameSetupView
                    showActiveGame = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        dismiss()
                    }
                },
                players: gamePlayers
            )
        }
        .sheet(isPresented: $showProfileEditor) {
            if let profile = profileToEdit {
                ProfileEditorView(profile: profile)
            }
        }
    }
    
    // MARK: - Header
    
    var header: some View {
        VStack(spacing: 8) {
            Text("New Game")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Add 2-4 players to start")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(.top, 20)
    }
    
    // MARK: - Player List
    
    var playerList: some View {
        VStack(spacing: 12) {
            ForEach(Array(players.enumerated()), id: \.element.id) { index, player in
                PlayerRow(
                    player: player,
                    playerNumber: index + 1,
                    onDelete: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            players.removeAll { $0.id == player.id }
                        }
                    }
                )
            }
            
            // Empty state
            if players.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.2))
                    
                    Text("No players added yet")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.3))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            }
        }
    }
    
    // MARK: - Add Player Section
    
    /// Get available profiles (not already added to game)
    var availableProfiles: [PlayerProfile] {
        let alreadyAddedNames = players.map { $0.name.lowercased() }
        return profileStorage.recentProfiles
            .filter { !alreadyAddedNames.contains($0.name.lowercased()) }
    }
    
    /// Check if typed name matches an existing profile
    var matchingExistingProfile: PlayerProfile? {
        let trimmed = newPlayerName.trimmingCharacters(in: .whitespaces).lowercased()
        guard !trimmed.isEmpty else { return nil }
        return profileStorage.profiles.first { $0.name.lowercased() == trimmed }
    }
    
    /// Check if typed name is already in the current game
    var isNameAlreadyInGame: Bool {
        let trimmed = newPlayerName.trimmingCharacters(in: .whitespaces).lowercased()
        return players.contains { $0.name.lowercased() == trimmed }
    }
    
    /// Can we add a new player with the typed name?
    var canAddNewPlayer: Bool {
        let trimmed = newPlayerName.trimmingCharacters(in: .whitespaces)
        // Must have a name, not match existing profile, not already in game
        return !trimmed.isEmpty && matchingExistingProfile == nil && !isNameAlreadyInGame
    }
    
    var addPlayerSection: some View {
        VStack(spacing: 20) {
            // Saved profiles chips (if any exist)
            if !availableProfiles.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Add")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.5))
                        .textCase(.uppercase)
                        .tracking(1.5)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(availableProfiles) { profile in
                                ProfileChip(profile: profile) {
                                    selectProfile(profile)
                                }
                                .onLongPressGesture {
                                    profileToEdit = profile
                                    showProfileEditor = true
                                }
                            }
                        }
                        .padding(.vertical, 2) // Prevents clipping of chip shadows
                    }
                    
                    Text("Long press to edit")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.3))
                }
                
                // Divider between sections
                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 1)
                    .padding(.vertical, 4)
            }
            
            // "Add new player" section
            VStack(alignment: .leading, spacing: 16) {
                if !availableProfiles.isEmpty {
                    Text("Add New Player")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.5))
                        .textCase(.uppercase)
                        .tracking(1.5)
                }
                
                // Color picker
                HStack(spacing: 10) {
                    Text("Color")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Spacer()
                    
                    ForEach(Array(availableColors.enumerated()), id: \.element) { index, colorName in
                        Circle()
                            .fill(colorFromName(colorName))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: selectedColorIndex == index ? 3 : 0)
                            )
                            .scaleEffect(selectedColorIndex == index ? 1.1 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedColorIndex)
                            .onTapGesture {
                                selectedColorIndex = index
                            }
                    }
                }
                .padding(.horizontal, 4)
                
                // Name input and add button
                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        // Text field
                        TextField("", text: $newPlayerName, prompt: Text("Enter name").foregroundColor(.white.opacity(0.3)))
                            .font(.body)
                            .foregroundColor(.white)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.08))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(matchingExistingProfile != nil ? Color(hex: "60a5fa").opacity(0.5) : Color.white.opacity(0.1), lineWidth: matchingExistingProfile != nil ? 2 : 1)
                            )
                            .focused($isNameFieldFocused)
                        
                        // Add button - disabled if name exists as profile or already in game
                        Button(action: addPlayer) {
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 54, height: 54)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(canAddNewPlayer ? Color(hex: "4ade80") : Color.gray.opacity(0.3))
                                )
                        }
                        .disabled(!canAddNewPlayer)
                        .opacity(canAddNewPlayer ? 1 : 0.5)
                    }
                    
                    // Hint message for existing profiles
                    if let existingProfile = matchingExistingProfile {
                        if isNameAlreadyInGame {
                            // Already in this game
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.caption)
                                Text("\(existingProfile.name) is already in this game")
                                    .font(.caption)
                            }
                            .foregroundColor(Color(hex: "f87171"))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            // Exists as profile - tap to add
                            Button(action: { 
                                selectProfile(existingProfile)
                                newPlayerName = "" // Clear text field
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "person.fill.checkmark")
                                        .font(.caption)
                                    Text("\(existingProfile.name) exists — tap to add")
                                        .font(.caption)
                                    Spacer()
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.caption)
                                }
                                .foregroundColor(Color(hex: "60a5fa"))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(hex: "60a5fa").opacity(0.1))
                                )
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// Select a profile from chips - adds player directly
    /// Returning players get priority for their preferred color
    func selectProfile(_ profile: PlayerProfile) {
        // Check if we can add more players
        guard players.count < 4 else { return }
        
        let preferredColor = profile.preferredColorName
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            // Check if their preferred color is available
            if availableColors.contains(preferredColor) {
                // Great! They get their preferred color
                let newPlayer = PlayerSetup(name: profile.name, colorName: preferredColor)
                players.append(newPlayer)
            } else {
                // Their color is taken - find who has it and swap
                if let takenIndex = players.firstIndex(where: { $0.colorName == preferredColor }) {
                    // Give the existing player a new available color
                    let newColorForExisting = availableColors.first ?? "blue"
                    players[takenIndex].colorName = newColorForExisting
                    
                    // Now add the profile player with their preferred color
                    let newPlayer = PlayerSetup(name: profile.name, colorName: preferredColor)
                    players.append(newPlayer)
                } else {
                    // Fallback: just use first available color
                    let fallbackColor = availableColors.first ?? Player.availableColors.first ?? "blue"
                    let newPlayer = PlayerSetup(name: profile.name, colorName: fallbackColor)
                    players.append(newPlayer)
                }
            }
        }
    }
    
    // MARK: - Start Game Button
    
    var startGameButton: some View {
        Button(action: startGame) {
            Text("Start Game")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(canStartGame ? Color(hex: "1a1a2e") : .white.opacity(0.3))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(canStartGame ? Color(hex: "4ade80") : Color.white.opacity(0.1))
                )
        }
        .disabled(!canStartGame)
    }
    
    // MARK: - Actions
    
    func addPlayer() {
        let trimmedName = newPlayerName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty, !availableColors.isEmpty else { return }
        
        // Make sure selectedColorIndex is valid
        let colorIndex = min(selectedColorIndex, availableColors.count - 1)
        let colorName = availableColors[colorIndex]
        
        let newPlayer = PlayerSetup(name: trimmedName, colorName: colorName)
        
        withAnimation(.easeInOut(duration: 0.2)) {
            players.append(newPlayer)
        }
        
        // Save or update player profile
        _ = profileStorage.getOrCreateProfile(name: trimmedName, colorName: colorName)
        profileStorage.updatePreferredColor(for: trimmedName, colorName: colorName)
        
        // Reset input and hide suggestions
        newPlayerName = ""
        selectedColorIndex = 0
        isNameFieldFocused = false
        showSuggestions = false
    }
    
    func startGame() {
        // Convert PlayerSetup to Player objects (with score starting at 0)
        gamePlayers = players.map { setup in
            Player(name: setup.name, score: 0, colorName: setup.colorName)
        }
        
        // Navigate to the active game
        showActiveGame = true
    }
    
    // Helper to convert color name to Color
    func colorFromName(_ name: String) -> Color {
        switch name {
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

// MARK: - Player Setup Model (temporary, for this screen only)

struct PlayerSetup: Identifiable {
    let id = UUID()
    var name: String
    var colorName: String
}

// MARK: - Player Row Component

struct PlayerRow: View {
    let player: PlayerSetup
    let playerNumber: Int
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Player color indicator
            Circle()
                .fill(colorFromName(player.colorName))
                .frame(width: 40, height: 40)
                .overlay(
                    Text("\(playerNumber)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                )
            
            // Player name
            Text(player.name)
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
            
            // Delete button
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white.opacity(0.3))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.08))
        )
    }
    
    func colorFromName(_ name: String) -> Color {
        switch name {
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

// MARK: - Profile Chip Component

struct ProfileChip: View {
    let profile: PlayerProfile
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                // Color dot
                Circle()
                    .fill(profile.preferredColor)
                    .frame(width: 24, height: 24)
                
                // Name
                Text(profile.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                // Stats badge (if they've played)
                if profile.gamesPlayed > 0 {
                    Text("\(profile.totalWins)W")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.15))
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(profile.preferredColor.opacity(0.15))
            )
            .overlay(
                Capsule()
                    .stroke(profile.preferredColor.opacity(0.3), lineWidth: 1.5)
            )
        }
        .buttonStyle(ProfileChipButtonStyle())
    }
}

/// Custom button style for chip press animation
struct ProfileChipButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        GameSetupView()
    }
}

