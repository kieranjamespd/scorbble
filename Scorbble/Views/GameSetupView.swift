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
    @State private var selectedEmojiIndex: Int = 0
    
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
            
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: isNameFieldFocused ? 12 : 24) {
                        // Header - condense when keyboard open
                        if isNameFieldFocused {
                            compactHeader
                        } else {
                            header
                        }
                        
                        // Player List - compact rows when keyboard open
                        playerListView
                        
                        // Add Player Section
                        if canAddMorePlayers {
                            addPlayerSection
                                .id("addPlayer")
                        }
                        
                        Spacer(minLength: isNameFieldFocused ? 0 : 20)
                        
                        // Start Game Button
                        startGameButton
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, isNameFieldFocused ? 8 : 24)
                    .padding(.bottom, 24)
                    .animation(.easeOut(duration: 0.15), value: isNameFieldFocused)
                }
                .onChange(of: isNameFieldFocused) { _, focused in
                    if focused {
                        // Delay scroll so keyboard can appear first - improves responsiveness
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            withAnimation(.easeOut(duration: 0.2)) {
                                proxy.scrollTo("addPlayer", anchor: .top)
                            }
                        }
                    }
                }
            }
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
    
    // Compact header when keyboard is open
    var compactHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("New Game")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Add 2-4 players")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
            Spacer()
        }
    }
    
    // MARK: - Player List
    
    var playerListView: some View {
        VStack(spacing: isNameFieldFocused ? 8 : 12) {
            ForEach(Array(players.enumerated()), id: \.element.id) { index, player in
                PlayerRow(
                    player: player,
                    playerNumber: index + 1,
                    compact: isNameFieldFocused,
                    onDelete: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            players.removeAll { $0.id == player.id }
                        }
                    }
                )
            }
            
            // Empty state - only show when not focused
            if players.isEmpty && !isNameFieldFocused {
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
        VStack(spacing: isNameFieldFocused ? 10 : 20) {
            // Saved profiles chips (if any exist)
            if !availableProfiles.isEmpty {
                VStack(alignment: .leading, spacing: isNameFieldFocused ? 6 : 12) {
                    Text("Quick Add")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.5))
                        .textCase(.uppercase)
                        .tracking(1.5)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: isNameFieldFocused ? 8 : 12) {
                            ForEach(availableProfiles) { profile in
                                ProfileChip(profile: profile, compact: isNameFieldFocused) {
                                    selectProfile(profile)
                                }
                                .contextMenu {
                                    Button {
                                        profileToEdit = profile
                                        showProfileEditor = true
                                    } label: {
                                        Label("Edit Profile", systemImage: "pencil")
                                    }
                                    
                                    Button(role: .destructive) {
                                        profileStorage.deleteProfile(profile)
                                    } label: {
                                        Label("Delete Profile", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    
                    if !isNameFieldFocused {
                        Text("Hold to edit or delete")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.3))
                    }
                }
                
                // Divider between sections
                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 1)
                    .padding(.vertical, isNameFieldFocused ? 2 : 4)
            }
            
            // "Add new player" section
            VStack(alignment: .leading, spacing: isNameFieldFocused ? 10 : 16) {
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
                
                // Emoji picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Avatar")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(Player.availableEmojis.enumerated()), id: \.offset) { index, emoji in
                                Text(emoji)
                                    .font(.system(size: 24))
                                    .frame(width: 40, height: 40)
                                    .background(
                                        Circle()
                                            .fill(selectedEmojiIndex == index ? Color.white.opacity(0.2) : Color.clear)
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: selectedEmojiIndex == index ? 2 : 0)
                                    )
                                    .scaleEffect(selectedEmojiIndex == index ? 1.15 : 1.0)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedEmojiIndex)
                                    .onTapGesture {
                                        selectedEmojiIndex = index
                                        HapticManager.selectionChanged()
                                    }
                            }
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 4)
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
    /// Returning players get priority for their preferred color and emoji
    func selectProfile(_ profile: PlayerProfile) {
        // Check if we can add more players
        guard players.count < 4 else { return }
        
        let preferredColor = profile.preferredColorName
        let preferredEmoji = profile.preferredEmoji
        
        HapticManager.mediumImpact()
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            // Check if their preferred color is available
            if availableColors.contains(preferredColor) {
                // Great! They get their preferred color
                let newPlayer = PlayerSetup(name: profile.name, colorName: preferredColor, emoji: preferredEmoji)
                players.append(newPlayer)
            } else {
                // Their color is taken - find who has it and swap
                if let takenIndex = players.firstIndex(where: { $0.colorName == preferredColor }) {
                    // Give the existing player a new available color
                    let newColorForExisting = availableColors.first ?? "blue"
                    players[takenIndex].colorName = newColorForExisting
                    
                    // Now add the profile player with their preferred color
                    let newPlayer = PlayerSetup(name: profile.name, colorName: preferredColor, emoji: preferredEmoji)
                    players.append(newPlayer)
                } else {
                    // Fallback: just use first available color
                    let fallbackColor = availableColors.first ?? Player.availableColors.first ?? "blue"
                    let newPlayer = PlayerSetup(name: profile.name, colorName: fallbackColor, emoji: preferredEmoji)
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
        
        // Get selected emoji
        let emojiIndex = min(selectedEmojiIndex, Player.availableEmojis.count - 1)
        let emoji = Player.availableEmojis[emojiIndex]
        
        let newPlayer = PlayerSetup(name: trimmedName, colorName: colorName, emoji: emoji)
        
        HapticManager.mediumImpact()
        
        withAnimation(.easeInOut(duration: 0.2)) {
            players.append(newPlayer)
        }
        
        // Save or update player profile
        _ = profileStorage.getOrCreateProfile(name: trimmedName, colorName: colorName, emoji: emoji)
        profileStorage.updatePreferredColor(for: trimmedName, colorName: colorName)
        profileStorage.updatePreferredEmoji(for: trimmedName, emoji: emoji)
        
        // Reset input and hide suggestions
        newPlayerName = ""
        selectedColorIndex = 0
        selectedEmojiIndex = 0
        isNameFieldFocused = false
        showSuggestions = false
    }
    
    func startGame() {
        // Convert PlayerSetup to Player objects (with score starting at 0)
        gamePlayers = players.map { setup in
            Player(name: setup.name, score: 0, colorName: setup.colorName, emoji: setup.emoji)
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
    var emoji: String
}

// MARK: - Player Row Component

struct PlayerRow: View {
    let player: PlayerSetup
    let playerNumber: Int
    var compact: Bool = false
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: compact ? 12 : 16) {
            // Player emoji avatar with color background
            ZStack {
                Circle()
                    .fill(colorFromName(player.colorName))
                    .frame(width: compact ? 32 : 44, height: compact ? 32 : 44)
                
                Text(player.emoji)
                    .font(.system(size: compact ? 16 : 22))
            }
            
            // Player name
            Text(player.name)
                .font(compact ? .subheadline : .headline)
                .foregroundColor(.white)
            
            Spacer()
            
            // Delete button
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: compact ? 20 : 24))
                    .foregroundColor(.white.opacity(0.3))
            }
        }
        .padding(compact ? 10 : 16)
        .background(
            RoundedRectangle(cornerRadius: compact ? 10 : 12)
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
    var compact: Bool = false
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: compact ? 6 : 10) {
                // Emoji avatar with color background
                ZStack {
                    Circle()
                        .fill(profile.preferredColor)
                        .frame(width: compact ? 22 : 28, height: compact ? 22 : 28)
                    
                    Text(profile.preferredEmoji)
                        .font(.system(size: compact ? 12 : 16))
                }
                
                // Name
                Text(profile.name)
                    .font(compact ? .caption : .subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                // Stats badge (if they've played) - hide when compact
                if profile.gamesPlayed > 0 && !compact {
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
            .padding(.horizontal, compact ? 10 : 16)
            .padding(.vertical, compact ? 8 : 12)
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

