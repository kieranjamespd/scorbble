//
//  GameSetupView.swift
//  Scorbble
//
//  Created by Kieran James on 07.12.25.
//

import SwiftUI

struct GameSetupView: View {
    @Environment(\.dismiss) var dismiss
    
    // Players being set up for the game
    @State private var players: [PlayerSetup] = []
    @State private var newPlayerName: String = ""
    @State private var selectedColorIndex: Int = 0
    
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
            ActiveGameView(players: gamePlayers)
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
    
    var addPlayerSection: some View {
        VStack(spacing: 16) {
            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1)
            
            // Color picker
            HStack(spacing: 8) {
                Text("Color:")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.5))
                
                ForEach(Array(availableColors.enumerated()), id: \.element) { index, colorName in
                    Circle()
                        .fill(colorFromName(colorName))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: selectedColorIndex == index ? 3 : 0)
                        )
                        .onTapGesture {
                            selectedColorIndex = index
                        }
                }
                
                Spacer()
            }
            
            // Name input and add button
            HStack(spacing: 12) {
                // Text field
                TextField("", text: $newPlayerName, prompt: Text("Enter player name").foregroundColor(.white.opacity(0.3)))
                    .font(.body)
                    .foregroundColor(.white)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                
                // Add button
                Button(action: addPlayer) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 52, height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(hex: "4ade80"))
                        )
                }
                .disabled(newPlayerName.trimmingCharacters(in: .whitespaces).isEmpty)
                .opacity(newPlayerName.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
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
        
        // Reset input
        newPlayerName = ""
        selectedColorIndex = 0
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

// MARK: - Preview

#Preview {
    NavigationStack {
        GameSetupView()
    }
}

