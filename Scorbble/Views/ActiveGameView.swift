//
//  ActiveGameView.swift
//  Scorbble
//
//  Created by Kieran James on 07.12.25.
//

import SwiftUI

struct ActiveGameView: View {
    @Environment(\.dismiss) var dismiss
    
    // Callback to return all the way to home
    var onReturnHome: (() -> Void)?
    
    // Game state
    @State var players: [Player]
    @State private var currentPlayerIndex: Int = 0
    @State private var turnHistory: [TurnRecord] = []
    @State private var showEndGameAlert = false
    @State private var gameEnded = false
    
    // Score entry mode
    @State private var isWordMode = true  // true = Word Entry, false = Quick Entry
    
    // Word entry state
    @State private var wordInput: String = ""
    @State private var letterTiles: [LetterTile] = []
    @State private var wordMultiplier: Int = 1
    @State private var hasBingo: Bool = false  // All 7 tiles used = +50 bonus
    
    // Quick entry state
    @State private var quickScore: String = ""
    
    // Keyboard tracking
    @FocusState private var isInputFocused: Bool
    
    var currentPlayer: Player {
        players[currentPlayerIndex]
    }
    
    var calculatedScore: Int {
        calculateWordScore(tiles: letterTiles, wordMultiplier: wordMultiplier, includesBingo: hasBingo)
    }
    
    var wordValidation: WordValidationStatus {
        WordValidator.validationStatus(wordInput)
    }
    
    // Dynamic tile size based on word length
    var tileSizeForWord: (size: TileSize, spacing: CGFloat, wrap: Bool) {
        let count = letterTiles.count
        if count <= 6 {
            return (isInputFocused ? .compact : .regular, 6, false)
        } else if count <= 8 {
            return (.compact, 4, false)
        } else if count <= 10 {
            return (.small, 3, false)
        } else {
            // Wrap to multiple lines for very long words
            return (.small, 4, true)
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(hex: "1a1a2e"), Color(hex: "16213e")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            if gameEnded {
                // Game Over Screen
                gameOverView
            } else {
                // Active Game
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: isInputFocused ? 12 : 20) {
                            // Scoreboard - compact when keyboard open
                            if isInputFocused {
                                compactScoreboard
                            } else {
                                scoreboard
                            }
                            
                            // Current turn indicator - hide when keyboard open
                            if !isInputFocused {
                                currentTurnBanner
                            }
                            
                            // Mode toggle
                            modeToggle
                            
                            // Score entry area
                            if isWordMode {
                                wordEntrySection
                                    .id("wordEntry")
                            } else {
                                quickEntrySection
                            }
                            
                            // Add score button
                            addScoreButton
                            
                            // Turn history - hide when keyboard open
                            if !turnHistory.isEmpty && !isInputFocused {
                                turnHistorySection
                            }
                            
                            // End game button - hide when keyboard open
                            if !isInputFocused {
                                endGameButton
                            }
                        }
                    .padding(20)
                    .animation(.easeOut(duration: 0.15), value: isInputFocused)
                    }
                .onChange(of: isInputFocused) { _, focused in
                    if focused {
                        // Delay scroll slightly so keyboard can appear first
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            withAnimation(.easeOut(duration: 0.2)) {
                                proxy.scrollTo("wordEntry", anchor: .top)
                            }
                        }
                    }
                }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if !gameEnded {
                    Button(action: { showEndGameAlert = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Quit")
                        }
                        .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
        }
        .alert("End Game?", isPresented: $showEndGameAlert) {
            Button("Cancel", role: .cancel) { }
            Button("End Game", role: .destructive) {
                // Save the game to history
                GameStorage.shared.saveGame(players: players)
                
                withAnimation {
                    gameEnded = true
                }
            }
        } message: {
            Text("Are you sure you want to end this game?")
        }
    }
    
    // MARK: - Scoreboard
    
    var scoreboard: some View {
        VStack(spacing: 12) {
            Text("SCOREBOARD")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white.opacity(0.4))
                .tracking(2)
            
            HStack(spacing: 12) {
                ForEach(Array(players.enumerated()), id: \.element.id) { index, player in
                    PlayerScoreCard(
                        player: player,
                        isCurrentTurn: index == currentPlayerIndex
                    )
                }
            }
        }
        .padding(.top, 10)
    }
    
    // MARK: - Compact Scoreboard (when keyboard open)
    
    var compactScoreboard: some View {
        HStack(spacing: 8) {
            ForEach(Array(players.enumerated()), id: \.element.id) { index, player in
                let isCurrentTurn = index == currentPlayerIndex
                
                HStack(spacing: 5) {
                    Circle()
                        .fill(player.color)
                        .frame(width: 8, height: 8)
                    
                    Text(player.name)
                        .font(.caption)
                        .fontWeight(isCurrentTurn ? .bold : .medium)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text("\(player.score)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(isCurrentTurn ? player.color : .white.opacity(0.7))
                }
                .padding(.horizontal, isCurrentTurn ? 10 : 6)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isCurrentTurn ? player.color.opacity(0.25) : Color.clear)
                )
                .overlay(
                    Capsule()
                        .stroke(isCurrentTurn ? player.color : Color.clear, lineWidth: 1.5)
                )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.05))
        )
    }
    
    // MARK: - Current Turn Banner
    
    var currentTurnBanner: some View {
        HStack {
            Circle()
                .fill(currentPlayer.color)
                .frame(width: 12, height: 12)
            
            Text("\(currentPlayer.name)'s Turn")
                .font(.headline)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(currentPlayer.color.opacity(0.2))
        )
    }
    
    // MARK: - Mode Toggle
    
    var modeToggle: some View {
        HStack(spacing: 0) {
            Button(action: { withAnimation { isWordMode = true } }) {
                Text("Word Entry")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isWordMode ? Color(hex: "1a1a2e") : .white.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isWordMode ? Color(hex: "4ade80") : Color.clear)
                    )
            }
            
            Button(action: { withAnimation { isWordMode = false } }) {
                Text("Quick Score")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(!isWordMode ? Color(hex: "1a1a2e") : .white.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(!isWordMode ? Color(hex: "4ade80") : Color.clear)
                    )
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.1))
        )
    }
    
    // MARK: - Word Entry Section
    
    var wordEntrySection: some View {
        VStack(spacing: isInputFocused ? 10 : 16) {
            // Word input field
            TextField("", text: $wordInput, prompt: Text("Type your word...").foregroundColor(.white.opacity(0.3)))
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled(true)
                .keyboardType(.asciiCapable)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.08))
                )
                .focused($isInputFocused)
                .onChange(of: wordInput) { _, newValue in
                    updateTiles(for: newValue)
                }
            
            // Letter tiles
            if !letterTiles.isEmpty {
                VStack(spacing: isInputFocused ? 6 : 12) {
                    if !isInputFocused {
                        Text("Tap = letter bonus • Hold = blank tile")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.4))
                    }
                    
                    // Tiles - single row or grid based on word length
                    if tileSizeForWord.wrap {
                        // Grid layout for very long words (11+)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: tileSizeForWord.spacing), count: 10), spacing: tileSizeForWord.spacing) {
                            ForEach(Array(letterTiles.enumerated()), id: \.element.id) { index, tile in
                                TappableLetterTile(tile: tile, size: tileSizeForWord.size) {
                                    cycleTileMultiplier(at: index)
                                } onLongPress: {
                                    toggleBlankTile(at: index)
                                }
                            }
                        }
                    } else {
                        // Single row for normal words
                        HStack(spacing: tileSizeForWord.spacing) {
                            ForEach(Array(letterTiles.enumerated()), id: \.element.id) { index, tile in
                                TappableLetterTile(tile: tile, size: tileSizeForWord.size) {
                                    cycleTileMultiplier(at: index)
                                } onLongPress: {
                                    toggleBlankTile(at: index)
                                }
                            }
                        }
                    }
                }
            }
            
            // Word multiplier & Bingo
            if !wordInput.isEmpty {
                VStack(spacing: isInputFocused ? 4 : 8) {
                    if !isInputFocused {
                        Text("Word Bonus")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.4))
                    }
                    
                    HStack(spacing: 6) {
                        ForEach([1, 2, 3], id: \.self) { multiplier in
                            Button(action: { wordMultiplier = multiplier }) {
                                Text(multiplier == 1 ? "1×" : multiplier == 2 ? "Double Word" : "Triple Word")
                                    .font(isInputFocused ? .caption : .subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(wordMultiplier == multiplier ? Color(hex: "1a1a2e") : .white.opacity(0.6))
                                    .padding(.horizontal, isInputFocused ? 10 : 14)
                                    .padding(.vertical, isInputFocused ? 8 : 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(wordMultiplier == multiplier ? Color(hex: "fbbf24") : Color.white.opacity(0.1))
                                    )
                            }
                        }
                    }
                    
                    // Bingo bonus (all 7 tiles = +50 points)
                    Button(action: { hasBingo.toggle() }) {
                        HStack(spacing: 6) {
                            Image(systemName: hasBingo ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: isInputFocused ? 14 : 16))
                            Text("Bingo (+50)")
                                .font(isInputFocused ? .caption : .subheadline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(hasBingo ? Color(hex: "1a1a2e") : .white.opacity(0.6))
                        .padding(.horizontal, isInputFocused ? 12 : 16)
                        .padding(.vertical, isInputFocused ? 8 : 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(hasBingo ? Color(hex: "4ade80") : Color.white.opacity(0.1))
                        )
                    }
                    
                    if !isInputFocused {
                        Text("Bingo = used all 7 tiles")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.3))
                    }
                }
            }
            
            // Validation & Score
            if !wordInput.isEmpty {
                HStack {
                    // Validation status
                    HStack(spacing: 6) {
                        Image(systemName: wordValidation.isAcceptable ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .foregroundColor(wordValidation.isAcceptable ? Color(hex: "4ade80") : Color(hex: "f87171"))
                        
                        Text(wordValidation.message)
                            .font(.subheadline)
                            .foregroundColor(wordValidation.isAcceptable ? Color(hex: "4ade80") : Color(hex: "f87171"))
                    }
                    
                    Spacer()
                    
                    // Score
                    HStack(spacing: 4) {
                        Text("Score:")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.5))
                        
                        Text("\(calculatedScore)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: "4ade80"))
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(isInputFocused ? 14 : 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    // MARK: - Quick Entry Section
    
    var quickEntrySection: some View {
        VStack(spacing: 16) {
            Text("Enter score directly")
                .font(.caption)
                .foregroundColor(.white.opacity(0.4))
            
            TextField("", text: $quickScore, prompt: Text("0").foregroundColor(.white.opacity(0.3)))
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .keyboardType(.numberPad)
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.08))
                )
                .focused($isInputFocused)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    // MARK: - Add Score Button
    
    var canAddScore: Bool {
        if isWordMode {
            return wordValidation.isAcceptable && calculatedScore > 0
        } else {
            return Int(quickScore) ?? 0 > 0
        }
    }
    
    var addScoreButton: some View {
        Button(action: addScore) {
            Text("Add Score")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(canAddScore ? Color(hex: "1a1a2e") : .white.opacity(0.3))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(canAddScore ? Color(hex: "4ade80") : Color.white.opacity(0.1))
                )
        }
        .disabled(!canAddScore)
    }
    
    // MARK: - Turn History Section
    
    var turnHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TURN HISTORY")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white.opacity(0.4))
                .tracking(2)
            
            ForEach(turnHistory.reversed().prefix(5)) { turn in
                HStack {
                    Circle()
                        .fill(turn.playerColor)
                        .frame(width: 8, height: 8)
                    
                    Text(turn.playerName)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                    
                    if let word = turn.word {
                        Text("\"\(word)\"")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    Spacer()
                    
                    Text("+\(turn.points)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "4ade80"))
                }
            }
            
            if turnHistory.count > 5 {
                Text("+ \(turnHistory.count - 5) more turns")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.3))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    // MARK: - End Game Button
    
    var endGameButton: some View {
        Button(action: { showEndGameAlert = true }) {
            Text("End Game")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.5))
                .padding(.vertical, 12)
        }
    }
    
    // MARK: - Game Over View
    
    /// Check if the game is a tie
    var isTieGame: Bool {
        let highestScore = players.map { $0.score }.max() ?? 0
        let topPlayers = players.filter { $0.score == highestScore }
        return topPlayers.count > 1
    }
    
    /// Get the winner (if not a tie)
    var winner: Player? {
        guard !isTieGame else { return nil }
        return players.max(by: { $0.score < $1.score })
    }
    
    /// Get the tied score
    var tiedScore: Int {
        players.map { $0.score }.max() ?? 0
    }
    
    var gameOverView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Icon - trophy for winner, handshake for tie
            Image(systemName: isTieGame ? "hands.clap.fill" : "trophy.fill")
                .font(.system(size: 80))
                .foregroundColor(isTieGame ? Color(hex: "60a5fa") : Color(hex: "fbbf24"))
            
            // Result announcement
            if isTieGame {
                // Tie game
                VStack(spacing: 8) {
                    Text("It's a Tie!")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("Draw Game")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("\(tiedScore) points each")
                        .font(.title3)
                        .foregroundColor(Color(hex: "60a5fa"))
                }
            } else if let winner = winner {
                // Winner
                VStack(spacing: 8) {
                    Text("Winner!")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text(winner.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("\(winner.score) points")
                        .font(.title3)
                        .foregroundColor(winner.color)
                }
            }
            
            // Final scores
            VStack(spacing: 12) {
                Text("FINAL SCORES")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(2)
                
                ForEach(players.sorted(by: { $0.score > $1.score })) { player in
                    HStack {
                        Circle()
                            .fill(player.color)
                            .frame(width: 12, height: 12)
                        
                        Text(player.name)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("\(player.score)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.08))
                    )
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 12) {
                // Play Again button
                Button(action: { 
                    // Go back to Game Setup to start a new game
                    dismiss()
                }) {
                    Text("Play Again")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "1a1a2e"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(hex: "4ade80"))
                        )
                }
                
                // Back to Home button
                Button(action: { 
                    // Call the callback to go all the way home
                    if let onReturnHome = onReturnHome {
                        onReturnHome()
                    } else {
                        dismiss()
                    }
                }) {
                    Text("Back to Home")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Actions
    
    func updateTiles(for word: String) {
        let letters = word.uppercased().filter { $0.isLetter }
        
        // Preserve existing multipliers for matching positions
        var newTiles: [LetterTile] = []
        for (index, letter) in letters.enumerated() {
            if index < letterTiles.count && letterTiles[index].letter == letter {
                newTiles.append(letterTiles[index])
            } else {
                newTiles.append(LetterTile(letter: letter))
            }
        }
        letterTiles = newTiles
    }
    
    func cycleTileMultiplier(at index: Int) {
        guard index < letterTiles.count else { return }
        
        // Cycle: 1 → 2 → 3 → 1
        let current = letterTiles[index].multiplier
        letterTiles[index].multiplier = current == 3 ? 1 : current + 1
    }
    
    func toggleBlankTile(at index: Int) {
        guard index < letterTiles.count else { return }
        letterTiles[index].isBlank.toggle()
        // Reset multiplier when marking as blank (blank tiles don't benefit from letter multipliers)
        if letterTiles[index].isBlank {
            letterTiles[index].multiplier = 1
        }
    }
    
    func addScore() {
        let points: Int
        let word: String?
        
        if isWordMode {
            points = calculatedScore
            word = wordInput.uppercased()
        } else {
            points = Int(quickScore) ?? 0
            word = nil
        }
        
        // Record the turn
        let turn = TurnRecord(
            playerName: currentPlayer.name,
            playerColor: currentPlayer.color,
            word: word,
            points: points
        )
        turnHistory.append(turn)
        
        // Add score to player
        players[currentPlayerIndex].score += points
        
        // Move to next player
        currentPlayerIndex = (currentPlayerIndex + 1) % players.count
        
        // Reset input
        wordInput = ""
        letterTiles = []
        wordMultiplier = 1
        hasBingo = false
        quickScore = ""
    }
}

// MARK: - Player Score Card

struct PlayerScoreCard: View {
    let player: Player
    let isCurrentTurn: Bool
    
    var body: some View {
        VStack(spacing: 6) {
            Text(player.name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(1)
            
            Text("\(player.score)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isCurrentTurn ? player.color.opacity(0.3) : Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isCurrentTurn ? player.color : Color.clear, lineWidth: 2)
                )
        )
    }
}

// MARK: - Tappable Letter Tile

enum TileSize {
    case regular, compact, small
    
    var dimension: CGFloat {
        switch self {
        case .regular: return 44
        case .compact: return 36
        case .small: return 30
        }
    }
    
    var fontSize: CGFloat {
        switch self {
        case .regular: return 22
        case .compact: return 18
        case .small: return 15
        }
    }
    
    var pointsSize: CGFloat {
        switch self {
        case .regular: return 9
        case .compact: return 8
        case .small: return 7
        }
    }
    
    var cornerRadius: CGFloat {
        switch self {
        case .regular: return 6
        case .compact: return 5
        case .small: return 4
        }
    }
}

struct TappableLetterTile: View {
    let tile: LetterTile
    var size: TileSize = .regular
    let onTap: () -> Void
    var onLongPress: (() -> Void)? = nil  // For toggling blank tile
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Tile background
            RoundedRectangle(cornerRadius: size.cornerRadius)
                .fill(tileBackground)
                .frame(width: size.dimension, height: size.dimension)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
            
            // Letter (italicized for blank tiles)
            Text(String(tile.letter))
                .font(.system(size: size.fontSize, weight: .bold, design: .serif))
                .italic(tile.isBlank)
                .foregroundColor(tile.isBlank ? Color(hex: "666666") : Color(hex: "2d2d2d"))
                .frame(width: size.dimension, height: size.dimension)
            
            // Points (shows 0 for blank)
            Text("\(tile.basePoints)")
                .font(.system(size: size.pointsSize, weight: .bold))
                .foregroundColor(tile.isBlank ? Color(hex: "888888") : Color(hex: "2d2d2d"))
                .padding(size == .regular ? 4 : 3)
            
            // Multiplier badge (only show if not blank - blank tiles don't benefit from multipliers)
            if !tile.isBlank && tile.multiplier > 1 {
                Text("\(tile.multiplier)×")
                    .font(.system(size: size == .regular ? 10 : 8, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, size == .regular ? 4 : 3)
                    .padding(.vertical, size == .regular ? 2 : 1)
                    .background(
                        Capsule()
                            .fill(tile.multiplier == 2 ? Color(hex: "60a5fa") : Color(hex: "f472b6"))
                    )
                    .offset(x: size == .regular ? 8 : 6, y: size == .regular ? -8 : -6)
            }
        }
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture {
            onLongPress?()
        }
    }
    
    var tileBackground: LinearGradient {
        if tile.isBlank {
            // Blank tile - lighter/cream colored
            return LinearGradient(
                colors: [Color(hex: "e5e5e5"), Color(hex: "d4d4d4")],
                startPoint: .top,
                endPoint: .bottom
            )
        } else if tile.multiplier == 2 {
            return LinearGradient(
                colors: [Color(hex: "bfdbfe"), Color(hex: "93c5fd")],
                startPoint: .top,
                endPoint: .bottom
            )
        } else if tile.multiplier == 3 {
            return LinearGradient(
                colors: [Color(hex: "fbcfe8"), Color(hex: "f9a8d4")],
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
            return LinearGradient(
                colors: [Color(hex: "f5e6d3"), Color(hex: "e8d5b7")],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

// MARK: - Turn Record

struct TurnRecord: Identifiable {
    let id = UUID()
    let playerName: String
    let playerColor: Color
    let word: String?
    let points: Int
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ActiveGameView(players: Player.mockPlayers)
    }
}

