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
    
    // Calculate the base score (no bonuses)
    var baseScore: Int {
        wordInput.uppercased().reduce(0) { total, letter in
            total + scrabblePoints(for: letter)
        }
    }
    
    var validation: WordValidationStatus {
        // Update the validator's dictionary before checking
        WordValidator.shared.currentDictionary = selectedDictionary
        return WordValidator.validationStatus(wordInput)
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
            
            VStack(spacing: 24) {
                // Header
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
                
                // Dictionary Picker
                VStack(spacing: 8) {
                    Text("Dictionary")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.4))
                        .tracking(1)
                    
                    HStack(spacing: 0) {
                        ForEach(ScrabbleDictionary.allCases, id: \.self) { dictionary in
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedDictionary = dictionary
                                }
                            }) {
                                VStack(spacing: 4) {
                                    Text(dictionary == .us ? "🇺🇸" : "🇬🇧")
                                        .font(.title2)
                                    Text(dictionary == .us ? "US" : "UK")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
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
                    .padding(.horizontal, 60)
                    
                    Text(selectedDictionary.description)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.3))
                }
                
                // Word input
                TextField("", text: $wordInput, prompt: Text("Enter a word...").foregroundColor(.white.opacity(0.3)))
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .autocapitalization(.allCharacters)
                    .disableAutocorrection(true)
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.08))
                    )
                    .padding(.horizontal, 24)
                
                // Results
                if !wordInput.isEmpty {
                    VStack(spacing: 24) {
                        // Validation status
                        HStack(spacing: 12) {
                            Image(systemName: validation.isAcceptable ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(validation.isAcceptable ? Color(hex: "4ade80") : Color(hex: "f87171"))
                            
                            Text(validation.message)
                                .font(.headline)
                                .foregroundColor(validation.isAcceptable ? Color(hex: "4ade80") : Color(hex: "f87171"))
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 24)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(validation.isAcceptable ? Color(hex: "4ade80").opacity(0.15) : Color(hex: "f87171").opacity(0.15))
                        )
                        
                        // Base score
                        if validation.isAcceptable {
                            VStack(spacing: 8) {
                                Text("Base Score")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.5))
                                
                                Text("\(baseScore)")
                                    .font(.system(size: 48, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("points (no bonuses)")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.4))
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Dictionary info
                VStack(spacing: 4) {
                    Text("Using sample dictionary (~5,000 words)")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.3))
                    Text("Full dictionary coming soon!")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.2))
                }
                .padding(.bottom, 20)
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
    }
}

#Preview {
    NavigationStack {
        WordCheckerView()
    }
}
