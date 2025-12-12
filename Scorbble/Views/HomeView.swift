//
//  HomeView.swift
//  Scorbble
//
//  Created by Kieran James on 07.12.25.
//

import SwiftUI

struct HomeView: View {
    // Navigation state
    @State private var showGameSetup = false
    @State private var showWordChecker = false
    @State private var showLeaderboard = false
    
    // Launch animation state
    @State private var tileOpacities: [Double] = Array(repeating: 0, count: 8)
    @State private var tileScales: [Double] = Array(repeating: 0.5, count: 8)
    @State private var subtitleOpacity: Double = 0
    @State private var buttonsOpacity: Double = 0
    @State private var buttonsOffset: CGFloat = 30
    @State private var trophyOpacity: Double = 0
    @State private var hasAnimated = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color(hex: "1a1a2e"), Color(hex: "16213e")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // Trophy button in top right
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            HapticManager.lightTap()
                            showLeaderboard = true
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: "fbbf24").opacity(0.15))
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: "trophy.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(Color(hex: "fbbf24"))
                            }
                        }
                        .opacity(trophyOpacity)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    
                    Spacer()
                }
                
                VStack(spacing: 32) {
                    Spacer()
                    
                    // App Logo & Title
                    VStack(spacing: 16) {
                        // Scrabble tile style logo with animation
                        HStack(spacing: 4) {
                            ForEach(Array("SCORBBLE".enumerated()), id: \.offset) { index, letter in
                                TileView(letter: String(letter), points: tilePoints(for: letter))
                                    .opacity(tileOpacities[index])
                                    .scaleEffect(tileScales[index])
                            }
                        }
                        
                        Text("Scrabble Score Keeper")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.6))
                            .opacity(subtitleOpacity)
                    }
                    
                    Spacer()
                    
                    // Main Menu Buttons with animation (just 2 now)
                    VStack(spacing: 16) {
                        MenuButton(
                            title: "New Game",
                            subtitle: "Start tracking scores",
                            icon: "play.fill",
                            color: Color(hex: "4ade80")
                        ) {
                            showGameSetup = true
                        }
                        
                        MenuButton(
                            title: "Word Checker",
                            subtitle: "Verify & score words",
                            icon: "text.book.closed.fill",
                            color: Color(hex: "60a5fa")
                        ) {
                            showWordChecker = true
                        }
                    }
                    .padding(.horizontal, 24)
                    .opacity(buttonsOpacity)
                    .offset(y: buttonsOffset)
                    
                    Spacer()
                    
                    // Tip section
                    VStack(spacing: 8) {
                        Text("💡 Tip")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.4))
                        
                        Text("Tap tiles for letter bonuses • Hold for blank tiles")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.3))
                            .multilineTextAlignment(.center)
                    }
                    .opacity(buttonsOpacity)
                    .padding(.bottom, 20)
                    
                    Spacer()
                }
            }
            .onAppear {
                if !hasAnimated {
                    startLaunchAnimation()
                    hasAnimated = true
                }
            }
            // Navigation destinations
            .navigationDestination(isPresented: $showGameSetup) {
                GameSetupView()
            }
            .navigationDestination(isPresented: $showWordChecker) {
                WordCheckerView()
            }
            // Leaderboard sheet
            .sheet(isPresented: $showLeaderboard) {
                LeaderboardSheet()
            }
        }
    }
    
    // Returns Scrabble point value for each letter (simplified)
    func tilePoints(for letter: Character) -> Int {
        switch letter {
        case "S", "R", "L", "E": return 1
        case "C", "B": return 3
        case "O": return 1
        default: return 1
        }
    }
    
    // MARK: - Launch Animation
    
    func startLaunchAnimation() {
        // Phase 1: Animate tiles popping in (staggered)
        for index in 0..<8 {
            let delay = Double(index) * 0.08
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(delay)) {
                tileOpacities[index] = 1.0
                tileScales[index] = 1.0
            }
        }
        
        // Phase 2: Fade in subtitle and trophy
        withAnimation(.easeOut(duration: 0.4).delay(0.8)) {
            subtitleOpacity = 1.0
            trophyOpacity = 1.0
        }
        
        // Phase 3: Slide up and fade in buttons
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(1.1)) {
            buttonsOpacity = 1.0
            buttonsOffset = 0
        }
    }
}

// MARK: - Leaderboard Sheet

struct LeaderboardSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "1a1a2e").ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Tab picker
                    Picker("View", selection: $selectedTab) {
                        Text("Leaderboard").tag(0)
                        Text("Past Games").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    
                    if selectedTab == 0 {
                        LeaderboardView()
                    } else {
                        PastGamesListView()
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "60a5fa"))
                }
            }
            .toolbarBackground(Color(hex: "1a1a2e"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

// MARK: - Leaderboard View

struct LeaderboardView: View {
    @ObservedObject private var gameStorage = GameStorage.shared
    
    var body: some View {
        ScrollView {
            if gameStorage.leaderboard.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "trophy")
                        .font(.system(size: 48))
                        .foregroundColor(.white.opacity(0.2))
                    
                    Text("No games played yet")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text("Complete a game to see the leaderboard")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.3))
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 60)
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(gameStorage.leaderboard.enumerated()), id: \.offset) { index, entry in
                        LeaderboardRow(
                            rank: index + 1,
                            name: entry.name,
                            wins: entry.wins
                        )
                    }
                }
                .padding(20)
            }
        }
    }
}

struct LeaderboardRow: View {
    let rank: Int
    let name: String
    let wins: Int
    
    var rankColor: Color {
        switch rank {
        case 1: return Color(hex: "fbbf24") // Gold
        case 2: return Color(hex: "9ca3af") // Silver
        case 3: return Color(hex: "cd7f32") // Bronze
        default: return Color.white.opacity(0.5)
        }
    }
    
    var rankIcon: String {
        switch rank {
        case 1: return "trophy.fill"
        case 2: return "medal.fill"
        case 3: return "medal.fill"
        default: return ""
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Rank
            ZStack {
                Circle()
                    .fill(rankColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                if rank <= 3 {
                    Image(systemName: rankIcon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(rankColor)
                } else {
                    Text("\(rank)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(rankColor)
                }
            }
            
            // Name
            Text(name)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Spacer()
            
            // Wins
            HStack(spacing: 4) {
                Text("\(wins)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "4ade80"))
                
                Text(wins == 1 ? "win" : "wins")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - Past Games List View

struct PastGamesListView: View {
    @ObservedObject private var gameStorage = GameStorage.shared
    
    var body: some View {
        ScrollView {
            if gameStorage.savedGames.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "clock")
                        .font(.system(size: 48))
                        .foregroundColor(.white.opacity(0.2))
                    
                    Text("No games yet")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text("Completed games will appear here")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.3))
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 60)
            } else {
                VStack(spacing: 12) {
                    ForEach(gameStorage.savedGames.reversed()) { game in
                        PastGameRow(game: game)
                    }
                }
                .padding(20)
            }
        }
    }
}

struct PastGameRow: View {
    let game: SavedGame
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Date and winner
            HStack {
                Text(game.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
                
                Spacer()
                
                if game.winnerName == "Tie" {
                    Text("🤝 Tie Game")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "fbbf24"))
                } else {
                    Text("🏆 \(game.winnerName)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "4ade80"))
                }
            }
            
            // Players and scores
            HStack(spacing: 12) {
                ForEach(game.players, id: \.name) { player in
                    VStack(spacing: 4) {
                        Text(player.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text("\(player.score)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(player.name == game.winnerName ? Color(hex: "4ade80") : .white.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - Scrabble Tile Component

struct TileView: View {
    let letter: String
    let points: Int
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "f5e6d3"), Color(hex: "e8d5b7")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 36, height: 36)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
            
            Text(letter)
                .font(.system(size: 20, weight: .bold, design: .serif))
                .foregroundColor(Color(hex: "2d2d2d"))
                .frame(width: 36, height: 36)
            
            Text("\(points)")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(Color(hex: "2d2d2d"))
                .padding(4)
        }
    }
}

// MARK: - Menu Button Component

struct MenuButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon circle
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(color)
                }
                
                // Text content
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Button Animation Style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Hex Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: // RGB
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview

#Preview {
    HomeView()
}

