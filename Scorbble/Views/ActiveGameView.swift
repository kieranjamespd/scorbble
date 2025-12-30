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
    
    // Undo support
    @State private var canUndo = false
    @State private var lastTurnPlayerIndex: Int? = nil
    @State private var lastTurnPoints: Int? = nil
    
    // Score entry mode
    @State private var isWordMode = true  // true = Word Entry, false = Quick Entry
    
    // Word entry state
    @State private var wordInput: String = ""
    @State private var letterTiles: [LetterTile] = []
    @State private var wordMultiplier: Int = 1
    @State private var hasBingo: Bool = false  // All 7 tiles used = +50 bonus
    
    // Quick entry state
    @State private var quickScore: String = ""
    
    // Help & Rules
    @State private var showTileHelp = false
    @State private var showRules = false
    
    // Share
    @State private var showShareSheet = false
    @State private var shareImage: UIImage? = nil
    
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
            ToolbarItem(placement: .navigationBarTrailing) {
                if !gameEnded {
                    Button(action: { showRules = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "book")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Rules")
                        }
                        .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
        }
        .sheet(isPresented: $showRules) {
            ScrabbleRulesView()
        }
        .sheet(isPresented: $showShareSheet) {
            if let image = shareImage {
                ShareSheetView(
                    image: image,
                    winner: winner,
                    isTie: isTieGame
                )
            }
        }
        .alert("End Game?", isPresented: $showEndGameAlert) {
            Button("Cancel", role: .cancel) { }
            Button("End Game", role: .destructive) {
                // Save the game to history
                GameStorage.shared.saveGame(players: players)
                
                // Haptic feedback for game end
                HapticManager.heavyImpact()
                
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
                
                HStack(spacing: 4) {
                    Text(player.emoji)
                        .font(.system(size: 14))
                    
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
        HStack(spacing: 8) {
            Text(currentPlayer.emoji)
                .font(.system(size: 20))
            
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
                    
                    // Tile hint - always visible when tiles are shown
                    if !isInputFocused {
                        HStack(spacing: 16) {
                            HStack(spacing: 4) {
                                Image(systemName: "hand.tap")
                                    .font(.caption2)
                                Text("Tap = 2×/3× letter")
                                    .font(.caption2)
                            }
                            .foregroundColor(.white.opacity(0.4))
                            
                            HStack(spacing: 4) {
                                Image(systemName: "hand.tap.fill")
                                    .font(.caption2)
                                Text("Hold = blank tile")
                                    .font(.caption2)
                            }
                            .foregroundColor(.white.opacity(0.4))
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
                            Button(action: {
                                wordMultiplier = multiplier
                                HapticManager.selectionChanged()
                            }) {
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
                    
                    // Bingo bonus - only show when word is 7+ letters
                    if letterTiles.count >= 7 {
                        Button(action: {
                            hasBingo.toggle()
                            HapticManager.selectionChanged()
                        }) {
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
                            Text(letterTiles.count == 7 ? "7 tiles = Bingo!" : "Toggle if you used all 7 tiles")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.3))
                        }
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
        HStack(spacing: 12) {
            // Undo button (only shows when undo is available)
            if canUndo {
                Button(action: undoLastScore) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Undo")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                }
            }
            
            // Add Score button
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
    
    /// Get the highest scoring word played
    var bestWord: (word: String, points: Int, player: String)? {
        turnHistory
            .filter { $0.word != nil }
            .max(by: { $0.points < $1.points })
            .map { ($0.word!, $0.points, $0.playerName) }
    }
    
    /// Get the longest word played
    var longestWord: (word: String, length: Int, player: String)? {
        turnHistory
            .filter { $0.word != nil }
            .max(by: { ($0.word?.count ?? 0) < ($1.word?.count ?? 0) })
            .map { ($0.word!, $0.word!.count, $0.playerName) }
    }
    
    /// Total turns played
    var totalTurns: Int {
        turnHistory.count
    }
    
    var gameOverView: some View {
        ZStack {
            // Confetti overlay for winner (not for ties)
            if let winner = winner {
                ConfettiView(
                    emoji: winner.emoji,
                    playerColor: winner.color
                )
                .ignoresSafeArea()
            }
            
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
                    HStack(spacing: 12) {
                        Text(player.emoji)
                            .font(.system(size: 24))
                        
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
            
            // Share button
            Button(action: {
                generateShareImage()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Share Results")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.15))
                )
            }
            
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
    }
    
    // MARK: - Actions
    
    func updateTiles(for word: String) {
        let letters = word.uppercased().filter { $0.isLetter }
        let previousCount = letterTiles.count
        
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
        
        // Auto-manage bingo based on word length
        let newCount = letters.count
        if newCount == 7 && previousCount != 7 {
            // Exactly 7 letters = auto-enable bingo
            hasBingo = true
        } else if newCount < 7 {
            // Less than 7 = impossible to have bingo
            hasBingo = false
        }
        // For 8+ letters, keep current bingo state (user controls it)
    }
    
    func cycleTileMultiplier(at index: Int) {
        guard index < letterTiles.count else { return }
        
        // Cycle: 1 → 2 → 3 → 1
        let current = letterTiles[index].multiplier
        letterTiles[index].multiplier = current == 3 ? 1 : current + 1
        HapticManager.selectionChanged()
    }
    
    func toggleBlankTile(at index: Int) {
        guard index < letterTiles.count else { return }
        letterTiles[index].isBlank.toggle()
        // Reset multiplier when marking as blank (blank tiles don't benefit from letter multipliers)
        if letterTiles[index].isBlank {
            letterTiles[index].multiplier = 1
        }
        HapticManager.lightTap()
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
        
        // Store undo info before changing state
        lastTurnPlayerIndex = currentPlayerIndex
        lastTurnPoints = points
        canUndo = true
        
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
        
        // Haptic feedback for score added
        HapticManager.success()
        
        // Move to next player
        currentPlayerIndex = (currentPlayerIndex + 1) % players.count
        
        // Reset input
        wordInput = ""
        letterTiles = []
        wordMultiplier = 1
        hasBingo = false
        quickScore = ""
    }
    
    func undoLastScore() {
        guard canUndo,
              let playerIndex = lastTurnPlayerIndex,
              let points = lastTurnPoints else { return }
        
        // Haptic feedback for undo
        HapticManager.lightTap()
        
        // Subtract points from the player
        players[playerIndex].score -= points
        
        // Remove the last turn from history
        if !turnHistory.isEmpty {
            turnHistory.removeLast()
        }
        
        // Go back to the previous player's turn
        currentPlayerIndex = playerIndex
        
        // Clear undo state (can only undo once)
        canUndo = false
        lastTurnPlayerIndex = nil
        lastTurnPoints = nil
    }
    
    func generateShareImage() {
        // Get winner's profile for win rate
        let winnerProfile = winner.flatMap { w in
            ProfileStorage.shared.profiles.first { $0.name.lowercased() == w.name.lowercased() }
        }
        
        let shareCard = GameShareCard(
            winner: winner,
            isTie: isTieGame,
            tiedScore: tiedScore,
            players: players,
            bestWord: bestWord,
            longestWord: longestWord,
            totalTurns: totalTurns,
            winnerWinRate: winnerProfile?.winRate
        )
        
        let renderer = ImageRenderer(content: shareCard)
        renderer.scale = 3.0 // High resolution
        
        if let uiImage = renderer.uiImage {
            shareImage = uiImage
            showShareSheet = true
            HapticManager.mediumImpact()
        }
    }
}

// MARK: - Player Score Card

struct PlayerScoreCard: View {
    let player: Player
    let isCurrentTurn: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            // Emoji avatar
            Text(player.emoji)
                .font(.system(size: 28))
            
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

// MARK: - Tile Help Popover

struct TileHelpView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tile Controls")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    Image(systemName: "hand.tap")
                        .foregroundColor(Color(hex: "60a5fa"))
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Tap a tile")
                            .fontWeight(.medium)
                        Text("Cycle through 1× → 2× → 3× letter bonus")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack(spacing: 10) {
                    Image(systemName: "hand.tap.fill")
                        .foregroundColor(Color(hex: "9ca3af"))
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Hold a tile")
                            .fontWeight(.medium)
                        Text("Mark as blank tile (0 points)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .frame(minWidth: 240)
    }
}

// MARK: - Scrabble Rules Sheet

struct ScrabbleRulesView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedRegion: ScrabbleDictionary = .uk
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "1a1a2e").ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Region picker
                        VStack(spacing: 8) {
                            Text("Rule Set")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                                .textCase(.uppercase)
                                .tracking(1)
                            
                            HStack(spacing: 0) {
                                ForEach(ScrabbleDictionary.allCases, id: \.self) { region in
                                    Button(action: { selectedRegion = region }) {
                                        HStack(spacing: 6) {
                                            Text(region == .us ? "🇺🇸" : "🇬🇧")
                                            Text(region == .us ? "US/Canada" : "UK/International")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(selectedRegion == region ? Color(hex: "60a5fa") : Color.clear)
                                        )
                                        .foregroundColor(selectedRegion == region ? .white : .white.opacity(0.5))
                                    }
                                }
                            }
                            .padding(4)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.1))
                            )
                        }
                        
                        // Core Rules
                        RuleSection(title: "Core Rules", rules: [
                            RuleItem(icon: "star.fill", color: "fbbf24", text: "First word must cover the center star (★) and gets Double Word score"),
                            RuleItem(icon: "arrow.left.and.right", color: "60a5fa", text: "Words must read left-to-right or top-to-bottom"),
                            RuleItem(icon: "link", color: "4ade80", text: "Every new word must connect to existing tiles on the board"),
                            RuleItem(icon: "7.square.fill", color: "f472b6", text: "Use all 7 tiles in one turn = Bingo bonus (+50 points)"),
                            RuleItem(icon: "square.dashed", color: "9ca3af", text: "Blank tiles can represent any letter but score 0 points")
                        ])
                        
                        // Scoring
                        RuleSection(title: "Scoring", rules: [
                            RuleItem(icon: "textformat.abc", color: "60a5fa", text: "Light blue squares = Double Letter (2× that letter)"),
                            RuleItem(icon: "textformat.abc", color: "f472b6", text: "Pink squares = Triple Letter (3× that letter)"),
                            RuleItem(icon: "square.fill", color: "fbbf24", text: "Yellow squares = Double Word (2× total word)"),
                            RuleItem(icon: "square.fill", color: "ef4444", text: "Red squares = Triple Word (3× total word)")
                        ])
                        
                        // Region-specific rules
                        if selectedRegion == .us {
                            RuleSection(title: "US/Canada (TWL)", rules: [
                                RuleItem(icon: "book.closed", color: "60a5fa", text: "Uses TWL (Tournament Word List) dictionary"),
                                RuleItem(icon: "xmark.circle", color: "f87171", text: "Challenged invalid words are removed, player loses turn"),
                                RuleItem(icon: "flag", color: "4ade80", text: "Standard in North American tournaments")
                            ])
                        } else {
                            RuleSection(title: "UK/International (SOWPODS)", rules: [
                                RuleItem(icon: "book.closed", color: "60a5fa", text: "Uses SOWPODS dictionary (larger word list)"),
                                RuleItem(icon: "checkmark.circle", color: "4ade80", text: "Includes British spellings (colour, honour, etc.)"),
                                RuleItem(icon: "globe", color: "f472b6", text: "Standard in UK and international tournaments")
                            ])
                        }
                        
                        // End game
                        RuleSection(title: "Ending the Game", rules: [
                            RuleItem(icon: "tray", color: "9ca3af", text: "Game ends when tile bag is empty and one player uses all tiles"),
                            RuleItem(icon: "minus.circle", color: "f87171", text: "Players subtract value of remaining tiles from score"),
                            RuleItem(icon: "plus.circle", color: "4ade80", text: "Player who went out adds other players' remaining tile values")
                        ])
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Scrabble Rules")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color(hex: "60a5fa"))
                }
            }
            .toolbarBackground(Color(hex: "1a1a2e"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

struct RuleSection: View {
    let title: String
    let rules: [RuleItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 10) {
                ForEach(rules) { rule in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: rule.icon)
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: rule.color))
                            .frame(width: 20)
                        
                        Text(rule.text)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
            )
        }
    }
}

struct RuleItem: Identifiable {
    let id = UUID()
    let icon: String
    let color: String
    let text: String
}

// MARK: - Confetti Celebration

struct ConfettiView: View {
    let emoji: String
    let playerColor: Color
    
    @State private var particles: [ConfettiParticle] = []
    @State private var isAnimating = false
    
    // Mix of player color, general celebration colors
    var confettiColors: [Color] {
        [
            playerColor,
            playerColor.opacity(0.7),
            Color(hex: "fbbf24"), // Gold
            Color(hex: "4ade80"), // Green
            Color(hex: "60a5fa"), // Blue
            Color(hex: "f472b6"), // Pink
            Color(hex: "a78bfa"), // Purple
            .white
        ]
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    ConfettiPiece(particle: particle, emoji: emoji)
                }
            }
            .onAppear {
                createParticles(in: geometry.size)
                
                // Haptic bursts for each wave
                HapticManager.success()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    HapticManager.mediumImpact()
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    HapticManager.lightTap()
                }
                
                // Trigger animation
                withAnimation(.linear(duration: 0.01)) {
                    isAnimating = true
                }
            }
        }
    }
    
    private func createParticles(in size: CGSize) {
        var newParticles: [ConfettiParticle] = []
        
        // Wave 1: Initial burst - 200 particles
        for i in 0..<200 {
            let isEmoji = i < 50 // First 50 are emoji
            let startX = CGFloat.random(in: -50...(size.width + 50))
            let startY = CGFloat.random(in: -250...(-30))
            
            let particle = ConfettiParticle(
                id: i,
                x: startX,
                y: startY,
                rotation: Double.random(in: 0...360),
                scale: CGFloat.random(in: 0.6...1.5),
                color: confettiColors.randomElement() ?? playerColor,
                isEmoji: isEmoji,
                delay: Double.random(in: 0...1.5), // First wave over 1.5 seconds
                duration: Double.random(in: 4.0...7.0), // Long fall time
                endY: size.height + 200,
                horizontalDrift: CGFloat.random(in: -150...150),
                spinSpeed: Double.random(in: 200...1000)
            )
            newParticles.append(particle)
        }
        
        // Wave 2: Second burst - 150 particles starting later
        for i in 200..<350 {
            let isEmoji = i < 240 // 40 more emoji
            let startX = CGFloat.random(in: -50...(size.width + 50))
            let startY = CGFloat.random(in: -200...(-20))
            
            let particle = ConfettiParticle(
                id: i,
                x: startX,
                y: startY,
                rotation: Double.random(in: 0...360),
                scale: CGFloat.random(in: 0.5...1.3),
                color: confettiColors.randomElement() ?? playerColor,
                isEmoji: isEmoji,
                delay: Double.random(in: 1.5...3.0), // Second wave starts at 1.5s
                duration: Double.random(in: 3.5...6.0),
                endY: size.height + 150,
                horizontalDrift: CGFloat.random(in: -120...120),
                spinSpeed: Double.random(in: 180...800)
            )
            newParticles.append(particle)
        }
        
        // Wave 3: Final flourish - 100 particles
        for i in 350..<450 {
            let isEmoji = i < 375 // 25 more emoji
            let startX = CGFloat.random(in: -30...(size.width + 30))
            let startY = CGFloat.random(in: -150...(-10))
            
            let particle = ConfettiParticle(
                id: i,
                x: startX,
                y: startY,
                rotation: Double.random(in: 0...360),
                scale: CGFloat.random(in: 0.4...1.2),
                color: confettiColors.randomElement() ?? playerColor,
                isEmoji: isEmoji,
                delay: Double.random(in: 3.0...4.5), // Third wave starts at 3s
                duration: Double.random(in: 3.0...5.0),
                endY: size.height + 100,
                horizontalDrift: CGFloat.random(in: -100...100),
                spinSpeed: Double.random(in: 150...600)
            )
            newParticles.append(particle)
        }
        
        particles = newParticles
    }
}

struct ConfettiParticle: Identifiable {
    let id: Int
    let x: CGFloat
    let y: CGFloat
    let rotation: Double
    let scale: CGFloat
    let color: Color
    let isEmoji: Bool
    let delay: Double
    let duration: Double
    let endY: CGFloat
    let horizontalDrift: CGFloat
    let spinSpeed: Double
}

struct ConfettiPiece: View {
    let particle: ConfettiParticle
    let emoji: String
    
    @State private var currentY: CGFloat = 0
    @State private var currentX: CGFloat = 0
    @State private var currentRotation: Double = 0
    @State private var opacity: Double = 1
    
    var body: some View {
        Group {
            if particle.isEmoji {
                Text(emoji)
                    .font(.system(size: 24 * particle.scale))
            } else {
                // Random shape - rectangle, circle, or capsule
                confettiShape
                    .frame(width: 10 * particle.scale, height: 14 * particle.scale)
            }
        }
        .rotationEffect(.degrees(currentRotation))
        .position(x: particle.x + currentX, y: particle.y + currentY)
        .opacity(opacity)
        .onAppear {
            // Animate falling
            withAnimation(
                .easeIn(duration: particle.duration)
                .delay(particle.delay)
            ) {
                currentY = particle.endY
                currentX = particle.horizontalDrift
            }
            
            // Animate spinning
            withAnimation(
                .linear(duration: particle.duration)
                .delay(particle.delay)
                .repeatCount(Int(particle.duration * 2), autoreverses: false)
            ) {
                currentRotation = particle.spinSpeed
            }
            
            // Fade out near end
            withAnimation(
                .easeIn(duration: 0.5)
                .delay(particle.delay + particle.duration - 0.5)
            ) {
                opacity = 0
            }
        }
    }
    
    @ViewBuilder
    var confettiShape: some View {
        switch particle.id % 3 {
        case 0:
            Rectangle()
                .fill(particle.color)
        case 1:
            Circle()
                .fill(particle.color)
        default:
            Capsule()
                .fill(particle.color)
        }
    }
}

// MARK: - Game Share Card

struct GameShareCard: View {
    let winner: Player?
    let isTie: Bool
    let tiedScore: Int
    let players: [Player]
    let bestWord: (word: String, points: Int, player: String)?
    let longestWord: (word: String, length: Int, player: String)?
    let totalTurns: Int
    let winnerWinRate: Int?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with gradient - more compact
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color(hex: "1a1a2e"), Color(hex: "16213e")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                VStack(spacing: 10) {
                    // App branding
                    Text("SCORBBLE")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .tracking(3)
                        .foregroundColor(.white.opacity(0.4))
                    
                    if isTie {
                        // Tie result
                        Image(systemName: "hands.clap.fill")
                            .font(.system(size: 36))
                            .foregroundColor(Color(hex: "60a5fa"))
                        
                        Text("It's a Tie!")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("\(tiedScore) points each")
                            .font(.subheadline)
                            .foregroundColor(Color(hex: "60a5fa"))
                    } else if let winner = winner {
                        // Winner emoji + trophy
                        HStack(spacing: 8) {
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 20))
                                .foregroundColor(Color(hex: "fbbf24"))
                            Text(winner.emoji)
                                .font(.system(size: 44))
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 20))
                                .foregroundColor(Color(hex: "fbbf24"))
                        }
                        
                        // Winner name
                        Text(winner.name)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        
                        // Winner stats in a row
                        HStack(spacing: 20) {
                            HStack(spacing: 4) {
                                Text("\(winner.score)")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(Color(hex: "4ade80"))
                                Text("pts")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            
                            if let winRate = winnerWinRate, winRate > 0 {
                                HStack(spacing: 4) {
                                    Text("\(winRate)%")
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundColor(Color(hex: "fbbf24"))
                                    Text("wins")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.5))
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 20)
            }
            .frame(height: 200)
            
            // Stats section - more room
            VStack(spacing: 14) {
                // All player scores
                HStack(spacing: 10) {
                    ForEach(players.sorted(by: { $0.score > $1.score })) { player in
                        VStack(spacing: 4) {
                            Text(player.emoji)
                                .font(.system(size: 22))
                            Text(player.name)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.8))
                                .lineLimit(1)
                            Text("\(player.score)")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(player.id == winner?.id ? Color(hex: "4ade80") : .white.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                Divider()
                    .background(Color.white.opacity(0.1))
                    .padding(.horizontal, 20)
                
                // Best word with Scrabble tiles
                if let best = bestWord {
                    VStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "fbbf24"))
                            Text("BEST WORD")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(1)
                                .foregroundColor(.white.opacity(0.5))
                        }
                        
                        // Scrabble tiles
                        HStack(spacing: 3) {
                            ForEach(Array(best.word.enumerated()), id: \.offset) { _, letter in
                                ShareTileView(letter: letter)
                            }
                        }
                        
                        Text("\(best.points) points by \(best.player)")
                            .font(.caption2)
                            .foregroundColor(Color(hex: "4ade80"))
                    }
                    .padding(.vertical, 4)
                }
                
                Divider()
                    .background(Color.white.opacity(0.1))
                    .padding(.horizontal, 20)
                
                // Game stats row
                HStack(spacing: 0) {
                    // Longest word
                    if let longest = longestWord {
                        VStack(spacing: 4) {
                            Image(systemName: "textformat.size")
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "60a5fa"))
                            Text(longest.word)
                                .font(.system(size: 13, weight: .bold, design: .serif))
                                .foregroundColor(.white)
                            Text("\(longest.length) letters")
                                .font(.caption2)
                                .foregroundColor(Color(hex: "60a5fa"))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    
                    // Total turns
                    VStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "a78bfa"))
                        Text("\(totalTurns)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                        Text("turns")
                            .font(.caption2)
                            .foregroundColor(Color(hex: "a78bfa"))
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Players count
                    VStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "f472b6"))
                        Text("\(players.count)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                        Text("players")
                            .font(.caption2)
                            .foregroundColor(Color(hex: "f472b6"))
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .background(Color(hex: "0f0f1a"))
        }
        .frame(width: 360, height: 480)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

// MARK: - Share Tile View (mini Scrabble tile for share card)

struct ShareTileView: View {
    let letter: Character
    
    var letterPoints: Int {
        let pointValues: [Character: Int] = [
            "A": 1, "B": 3, "C": 3, "D": 2, "E": 1, "F": 4, "G": 2, "H": 4,
            "I": 1, "J": 8, "K": 5, "L": 1, "M": 3, "N": 1, "O": 1, "P": 3,
            "Q": 10, "R": 1, "S": 1, "T": 1, "U": 1, "V": 4, "W": 4, "X": 8,
            "Y": 4, "Z": 10
        ]
        return pointValues[Character(letter.uppercased())] ?? 0
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: 3)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "f5e6d3"), Color(hex: "e8d5b7")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 24, height: 24)
                .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
            
            Text(String(letter).uppercased())
                .font(.system(size: 14, weight: .bold, design: .serif))
                .foregroundColor(Color(hex: "2d2d2d"))
                .frame(width: 24, height: 24)
            
            Text("\(letterPoints)")
                .font(.system(size: 6, weight: .bold))
                .foregroundColor(Color(hex: "2d2d2d"))
                .padding(2)
        }
    }
}

// MARK: - Share Sheet View

struct ShareSheetView: View {
    @Environment(\.dismiss) var dismiss
    let image: UIImage
    let winner: Player?
    let isTie: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "1a1a2e").ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Preview of the share image
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 400)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                    
                    Text("Share your victory!")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.7))
                    
                    // Share buttons
                    VStack(spacing: 12) {
                        // Instagram Stories button
                        Button(action: shareToInstagramStories) {
                            HStack(spacing: 12) {
                                Image(systemName: "camera.filters")
                                    .font(.system(size: 20))
                                Text("Share to Instagram Stories")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "833ab4"), Color(hex: "fd1d1d"), Color(hex: "fcb045")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        
                        // General share button
                        Button(action: shareGeneral) {
                            HStack(spacing: 12) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 20))
                                Text("More Options")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white.opacity(0.8))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        
                        // Save to Photos
                        Button(action: saveToPhotos) {
                            HStack(spacing: 12) {
                                Image(systemName: "square.and.arrow.down")
                                    .font(.system(size: 20))
                                Text("Save to Photos")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white.opacity(0.6))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.vertical, 20)
            }
            .navigationTitle("Share Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color(hex: "60a5fa"))
                }
            }
            .toolbarBackground(Color(hex: "1a1a2e"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
    
    func shareToInstagramStories() {
        guard let urlScheme = URL(string: "instagram-stories://share?source_application=com.scorbble.app") else {
            // Instagram not installed, fall back to general share
            shareGeneral()
            return
        }
        
        if UIApplication.shared.canOpenURL(urlScheme) {
            // Prepare background image data
            guard let imageData = image.pngData() else { return }
            
            let pasteboardItems: [String: Any] = [
                "com.instagram.sharedSticker.backgroundImage": imageData,
                "com.instagram.sharedSticker.backgroundTopColor": "#1a1a2e",
                "com.instagram.sharedSticker.backgroundBottomColor": "#16213e"
            ]
            
            let pasteboardOptions: [UIPasteboard.OptionsKey: Any] = [
                .expirationDate: Date().addingTimeInterval(300)
            ]
            
            UIPasteboard.general.setItems([pasteboardItems], options: pasteboardOptions)
            
            UIApplication.shared.open(urlScheme, options: [:]) { success in
                if success {
                    HapticManager.success()
                }
            }
        } else {
            // Instagram not installed
            shareGeneral()
        }
    }
    
    func shareGeneral() {
        let activityVC = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            // Find the topmost presented view controller
            var topController = rootViewController
            while let presented = topController.presentedViewController {
                topController = presented
            }
            
            // For iPad
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = topController.view
                popover.sourceRect = CGRect(x: topController.view.bounds.midX, y: topController.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            topController.present(activityVC, animated: true)
        }
    }
    
    func saveToPhotos() {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        HapticManager.success()
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ActiveGameView(players: Player.mockPlayers)
    }
}

