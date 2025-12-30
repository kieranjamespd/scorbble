//
//  PastGamesView.swift
//  Scorbble
//
//  Created by Kieran James on 07.12.25.
//

import SwiftUI

struct PastGamesView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var storage = GameStorage.shared
    
    @State private var showClearConfirmation = false
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(hex: "1a1a2e"), Color(hex: "16213e")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                header
                
                if storage.savedGames.isEmpty {
                    // Empty state
                    emptyState
                } else {
                    // Stats summary
                    statsSummary
                    
                    // Game list
                    gameList
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
            
            if !storage.savedGames.isEmpty {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showClearConfirmation = true }) {
                        Image(systemName: "trash")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
        }
        .alert("Clear All Games?", isPresented: $showClearConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All", role: .destructive) {
                withAnimation {
                    storage.clearAllGames()
                }
            }
        } message: {
            Text("This will permanently delete all game history.")
        }
    }
    
    // MARK: - Header
    
    var header: some View {
        VStack(spacing: 8) {
            Text("Past Games")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("\(storage.totalGamesPlayed) games played")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(.top, 20)
        .padding(.bottom, 16)
    }
    
    // MARK: - Empty State
    
    var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.2))
            
            Text("No games yet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white.opacity(0.5))
            
            Text("Complete a game to see it here")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.3))
            
            Spacer()
        }
    }
    
    // MARK: - Stats Summary
    
    var statsSummary: some View {
        VStack(spacing: 16) {
            // Leaderboard preview
            if let topPlayer = storage.leaderboard.first {
                HStack {
                    Image(systemName: "crown.fill")
                        .foregroundColor(Color(hex: "fbbf24"))
                    
                    Text("\(topPlayer.name)")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("leads with \(topPlayer.wins) win\(topPlayer.wins == 1 ? "" : "s")")
                        .foregroundColor(.white.opacity(0.6))
                    
                    Spacer()
                }
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "fbbf24").opacity(0.15))
                )
                .padding(.horizontal, 20)
            }
            
            // High score
            if let highScore = storage.highestScore {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(Color(hex: "60a5fa"))
                    
                    Text("High score:")
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("\(highScore.score) pts")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("by \(highScore.name)")
                        .foregroundColor(.white.opacity(0.6))
                    
                    Spacer()
                }
                .font(.caption)
                .padding(.horizontal, 20)
            }
        }
        .padding(.bottom, 16)
    }
    
    // MARK: - Game List
    
    var gameList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(storage.savedGames) { game in
                    GameHistoryCard(game: game)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
}

// MARK: - Game History Card

struct GameHistoryCard: View {
    let game: SavedGame
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Main card content
            Button(action: { withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() } }) {
                HStack(spacing: 16) {
                    // Date
                    VStack(spacing: 2) {
                        Text(game.shortDate)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .frame(width: 50)
                    
                    // Winner info
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: game.isTie ? "equal.circle.fill" : "trophy.fill")
                                .font(.caption)
                                .foregroundColor(game.isTie ? Color(hex: "60a5fa") : Color(hex: "fbbf24"))
                            
                            Text(game.isTie ? "Tie Game" : game.winnerName)
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        
                        Text(game.isTie 
                             ? "\(game.playerCount) players • \(game.winnerScore) pts each"
                             : "\(game.playerCount) players • \(game.winnerScore) winning score")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.4))
                    }
                    
                    Spacer()
                    
                    // Expand indicator
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.3))
                }
                .padding(16)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expanded content - player scores
            if isExpanded {
                VStack(spacing: 8) {
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    ForEach(game.players.sorted(by: { $0.score > $1.score })) { player in
                        HStack(spacing: 10) {
                            Text(player.emoji)
                                .font(.system(size: 20))
                            
                            Text(player.name)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                            
                            Spacer()
                            
                            Text("\(player.score) pts")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(player.name == game.winnerName ? Color(hex: "4ade80") : .white.opacity(0.5))
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, 12)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.08))
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PastGamesView()
    }
}

