//
//  WordCheckerView.swift
//  Scorbble
//
//  Created by Kieran James on 07.12.25.
//

import SwiftUI

struct WordCheckerView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var wordInput: String = ""
    @State private var selectedDictionary: ScrabbleDictionary = .uk
    @State private var letterTiles: [LetterTile] = []
    @State private var wordMultiplier: Int = 1
    @State private var hasBingo: Bool = false
    @State private var showTileHelp = false
    @State private var showRules = false
    
    @FocusState private var isInputFocused: Bool
    
    var validation: WordValidationStatus {
        WordValidator.shared.currentDictionary = selectedDictionary
        return WordValidator.validationStatus(wordInput)
    }
    
    var calculatedScore: Int {
        calculateWordScore(tiles: letterTiles, wordMultiplier: wordMultiplier, includesBingo: hasBingo)
    }
    
    // Dynamic tile sizing based on word length
    var tileSize: CGFloat {
        let count = letterTiles.count
        if count <= 6 { return 44 }
        else if count <= 8 { return 38 }
        else if count <= 10 { return 32 }
        else { return 28 }
    }
    
    var tileSpacing: CGFloat {
        let count = letterTiles.count
        if count <= 6 { return 6 }
        else if count <= 8 { return 4 }
        else { return 3 }
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
            
            ScrollView {
                VStack(spacing: isInputFocused ? 16 : 24) {
                    // Header
                    if !isInputFocused {
                        VStack(spacing: 8) {
                            Text("Word Checker")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Check if a word is valid in Scrabble")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .padding(.top, 40)
                    } else {
                        // Compact header
                        HStack {
                            Text("Word Checker")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.top, 8)
                    }
                    
                    // Dictionary Picker
                    VStack(spacing: 8) {
                        if !isInputFocused {
                            Text("Dictionary")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.4))
                                .tracking(1)
                        }
                        
                        HStack(spacing: 0) {
                            ForEach(ScrabbleDictionary.allCases, id: \.self) { dictionary in
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedDictionary = dictionary
                                    }
                                }) {
                                    VStack(spacing: isInputFocused ? 2 : 4) {
                                        Text(dictionary == .us ? "🇺🇸" : "🇬🇧")
                                            .font(isInputFocused ? .body : .title2)
                                        Text(dictionary == .us ? "US" : "UK")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, isInputFocused ? 8 : 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(selectedDictionary == dictionary ? Color(hex: "60a5fa") : Color.clear)
                                    )
                                    .foregroundColor(selectedDictionary == dictionary ? .white : .white.opacity(0.5))
                                }
                            }
                        }
                        .padding(4)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white.opacity(0.1))
                        )
                        .padding(.horizontal, isInputFocused ? 0 : 60)
                        
                        if !isInputFocused {
                            Text(selectedDictionary.description)
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.3))
                        }
                    }
                    
                    // Word input
                    TextField("", text: $wordInput, prompt: Text("Enter a word...").foregroundColor(.white.opacity(0.3)))
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled(true)
                        .keyboardType(.asciiCapable)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.08))
                        )
                        .focused($isInputFocused)
                        .onChange(of: wordInput) { _, newValue in
                            updateTiles(for: newValue)
                        }
                    
                    // Results
                    if !wordInput.isEmpty {
                        VStack(spacing: 16) {
                            // Validation status
                            HStack(spacing: 12) {
                                Image(systemName: validation.isAcceptable ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(validation.isAcceptable ? Color(hex: "4ade80") : Color(hex: "f87171"))
                                
                                Text(validation.message)
                                    .font(.headline)
                                    .foregroundColor(validation.isAcceptable ? Color(hex: "4ade80") : Color(hex: "f87171"))
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 20)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(validation.isAcceptable ? Color(hex: "4ade80").opacity(0.15) : Color(hex: "f87171").opacity(0.15))
                            )
                            
                            // Tile-based score calculator
                            if validation.isAcceptable {
                                VStack(spacing: 16) {
                                    // Letter tiles
                                    VStack(spacing: 8) {
                                        HStack {
                                            Spacer()
                                            Button(action: { showTileHelp = true }) {
                                                Image(systemName: "info.circle")
                                                    .font(.system(size: 16))
                                                    .foregroundColor(.white.opacity(0.5))
                                            }
                                            .popover(isPresented: $showTileHelp) {
                                                TileHelpView()
                                                    .presentationCompactAdaptation(.popover)
                                            }
                                        }
                                        
                                        // Tiles - use HStack for short words, wrap for long
                                        if letterTiles.count <= 12 {
                                            HStack(spacing: tileSpacing) {
                                                ForEach(Array(letterTiles.enumerated()), id: \.element.id) { index, tile in
                                                    WordCheckerTile(tile: tile, size: tileSize) {
                                                        cycleTileMultiplier(at: index)
                                                    } onLongPress: {
                                                        toggleBlankTile(at: index)
                                                    }
                                                }
                                            }
                                        } else {
                                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 12), spacing: 3) {
                                                ForEach(Array(letterTiles.enumerated()), id: \.element.id) { index, tile in
                                                    WordCheckerTile(tile: tile, size: 28) {
                                                        cycleTileMultiplier(at: index)
                                                    } onLongPress: {
                                                        toggleBlankTile(at: index)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    
                                    // Word multiplier
                                    VStack(spacing: 8) {
                                        Text("Word Bonus")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.4))
                                        
                                        HStack(spacing: 8) {
                                            ForEach([1, 2, 3], id: \.self) { multiplier in
                                                Button(action: { wordMultiplier = multiplier }) {
                                                    Text(multiplier == 1 ? "1×" : multiplier == 2 ? "Double Word" : "Triple Word")
                                                        .font(.subheadline)
                                                        .fontWeight(.semibold)
                                                        .foregroundColor(wordMultiplier == multiplier ? Color(hex: "1a1a2e") : .white.opacity(0.6))
                                                        .padding(.horizontal, 14)
                                                        .padding(.vertical, 10)
                                                        .background(
                                                            RoundedRectangle(cornerRadius: 8)
                                                                .fill(wordMultiplier == multiplier ? Color(hex: "fbbf24") : Color.white.opacity(0.1))
                                                        )
                                                }
                                            }
                                        }
                                        
                                        // Bingo bonus - only show when word is 7+ letters
                                        if letterTiles.count >= 7 {
                                            Button(action: { hasBingo.toggle() }) {
                                                HStack(spacing: 6) {
                                                    Image(systemName: hasBingo ? "checkmark.circle.fill" : "circle")
                                                        .font(.system(size: 16))
                                                    Text("Bingo (+50)")
                                                        .font(.subheadline)
                                                        .fontWeight(.semibold)
                                                }
                                                .foregroundColor(hasBingo ? Color(hex: "1a1a2e") : .white.opacity(0.6))
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 10)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .fill(hasBingo ? Color(hex: "4ade80") : Color.white.opacity(0.1))
                                                )
                                            }
                                            
                                            Text(letterTiles.count == 7 ? "7 tiles = Bingo!" : "Toggle if you used all 7 tiles")
                                                .font(.caption2)
                                                .foregroundColor(.white.opacity(0.3))
                                        }
                                    }
                                    
                                    // Score display
                                    VStack(spacing: 4) {
                                        Text("Score")
                                            .font(.subheadline)
                                            .foregroundColor(.white.opacity(0.5))
                                        
                                        Text("\(calculatedScore)")
                                            .font(.system(size: 56, weight: .bold))
                                            .foregroundColor(Color(hex: "4ade80"))
                                        
                                        Text("points")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.4))
                                    }
                                    .padding(.top, 8)
                                }
                                .padding(20)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.05))
                                )
                            }
                        }
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
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
            ToolbarItem(placement: .navigationBarTrailing) {
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
        .sheet(isPresented: $showRules) {
            ScrabbleRulesView()
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
        
        // Reset word multiplier when word changes significantly
        let newCount = letters.count
        if newCount != previousCount {
            wordMultiplier = 1
        }
        
        // Auto-manage bingo based on word length
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
        let current = letterTiles[index].multiplier
        letterTiles[index].multiplier = current == 3 ? 1 : current + 1
    }
    
    func toggleBlankTile(at index: Int) {
        guard index < letterTiles.count else { return }
        letterTiles[index].isBlank.toggle()
        // Reset multiplier when marking as blank
        if letterTiles[index].isBlank {
            letterTiles[index].multiplier = 1
        }
    }
}

// MARK: - Word Checker Tile

struct WordCheckerTile: View {
    let tile: LetterTile
    var size: CGFloat = 44
    let onTap: () -> Void
    var onLongPress: (() -> Void)? = nil
    
    var fontSize: CGFloat {
        if size >= 44 { return 22 }
        else if size >= 38 { return 18 }
        else if size >= 32 { return 15 }
        else { return 13 }
    }
    
    var pointsSize: CGFloat {
        if size >= 44 { return 9 }
        else if size >= 38 { return 8 }
        else { return 7 }
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Tile background
            RoundedRectangle(cornerRadius: size >= 38 ? 6 : 4)
                .fill(tileBackground)
                .frame(width: size, height: size)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
            
            // Letter (italicized for blank tiles)
            Text(String(tile.letter))
                .font(.system(size: fontSize, weight: .bold, design: .serif))
                .italic(tile.isBlank)
                .foregroundColor(tile.isBlank ? Color(hex: "666666") : Color(hex: "2d2d2d"))
                .frame(width: size, height: size)
            
            // Points
            if size >= 30 {
                Text("\(tile.basePoints)")
                    .font(.system(size: pointsSize, weight: .bold))
                    .foregroundColor(tile.isBlank ? Color(hex: "888888") : Color(hex: "2d2d2d"))
                    .padding(size >= 38 ? 4 : 3)
            }
            
            // Multiplier badge (only show if not blank)
            if !tile.isBlank && tile.multiplier > 1 {
                Text("\(tile.multiplier)×")
                    .font(.system(size: size >= 38 ? 10 : 8, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, size >= 38 ? 4 : 3)
                    .padding(.vertical, size >= 38 ? 2 : 1)
                    .background(
                        Capsule()
                            .fill(tile.multiplier == 2 ? Color(hex: "60a5fa") : Color(hex: "f472b6"))
                    )
                    .offset(x: size >= 38 ? 8 : 6, y: size >= 38 ? -8 : -6)
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

#Preview {
    NavigationStack {
        WordCheckerView()
    }
}
