//
//  ProfileEditorView.swift
//  Scorbble
//
//  Created by Kieran James on 09.12.25.
//

import SwiftUI

struct ProfileEditorView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var profileStorage = ProfileStorage.shared
    
    let profile: PlayerProfile
    
    @State private var editedName: String = ""
    @State private var selectedColorName: String = ""
    @State private var selectedEmoji: String = ""
    @State private var showDeleteConfirmation = false
    @State private var nameError: String? = nil
    
    // Helper to get Color from color name
    func colorFromName(_ name: String) -> Color {
        switch name {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "red": return .red
        case "pink": return .pink
        default: return .blue
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color(hex: "1a1a2e"), Color(hex: "16213e")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile header with live preview
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(colorFromName(selectedColorName))
                                    .frame(width: 80, height: 80)
                                
                                Text(selectedEmoji)
                                    .font(.system(size: 40))
                            }
                            
                            // Stats
                            HStack(spacing: 24) {
                                StatBox(value: "\(profile.gamesPlayed)", label: "Games")
                                StatBox(value: "\(profile.totalWins)", label: "Wins")
                                StatBox(value: "\(profile.highestScore)", label: "Best")
                            }
                        }
                        .padding(.top, 20)
                        
                        // Edit name section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Player Name")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white.opacity(0.5))
                                .textCase(.uppercase)
                                .tracking(1.5)
                            
                            TextField("", text: $editedName, prompt: Text("Enter name").foregroundColor(.white.opacity(0.3)))
                                .font(.body)
                                .foregroundColor(.white)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.08))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(nameError != nil ? Color(hex: "f87171") : Color.white.opacity(0.1), lineWidth: 1)
                                )
                                .onChange(of: editedName) {
                                    validateName()
                                }
                            
                            if let error = nameError {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(Color(hex: "f87171"))
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Color picker section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Color")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white.opacity(0.5))
                                .textCase(.uppercase)
                                .tracking(1.5)
                            
                            HStack(spacing: 12) {
                                ForEach(Player.availableColors, id: \.self) { colorName in
                                    Circle()
                                        .fill(colorFromName(colorName))
                                        .frame(width: 44, height: 44)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: selectedColorName == colorName ? 3 : 0)
                                        )
                                        .scaleEffect(selectedColorName == colorName ? 1.1 : 1.0)
                                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedColorName)
                                        .onTapGesture {
                                            selectedColorName = colorName
                                            HapticManager.selectionChanged()
                                        }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Emoji picker section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Avatar")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white.opacity(0.5))
                                .textCase(.uppercase)
                                .tracking(1.5)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(Player.availableEmojis, id: \.self) { emoji in
                                        Text(emoji)
                                            .font(.system(size: 28))
                                            .frame(width: 48, height: 48)
                                            .background(
                                                Circle()
                                                    .fill(selectedEmoji == emoji ? Color.white.opacity(0.2) : Color.clear)
                                            )
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.white, lineWidth: selectedEmoji == emoji ? 2 : 0)
                                            )
                                            .scaleEffect(selectedEmoji == emoji ? 1.15 : 1.0)
                                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedEmoji)
                                            .onTapGesture {
                                                selectedEmoji = emoji
                                                HapticManager.selectionChanged()
                                            }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        Spacer(minLength: 40)
                        
                        // Delete profile button
                        Button(action: { showDeleteConfirmation = true }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete Profile")
                            }
                            .font(.subheadline)
                            .foregroundColor(Color(hex: "f87171"))
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(canSave ? Color(hex: "4ade80") : .gray)
                    .disabled(!canSave)
                }
            }
            .toolbarBackground(Color(hex: "1a1a2e"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .onAppear {
            editedName = profile.name
            selectedColorName = profile.preferredColorName
            selectedEmoji = profile.preferredEmoji
        }
        .alert("Delete Profile?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteProfile()
            }
        } message: {
            Text("This will permanently delete \(profile.name)'s profile and stats. Game history will be preserved.")
        }
    }
    
    // MARK: - Computed Properties
    
    var hasChanges: Bool {
        let trimmedName = editedName.trimmingCharacters(in: .whitespaces)
        return trimmedName != profile.name ||
               selectedColorName != profile.preferredColorName ||
               selectedEmoji != profile.preferredEmoji
    }
    
    var canSave: Bool {
        let trimmed = editedName.trimmingCharacters(in: .whitespaces)
        return !trimmed.isEmpty && nameError == nil && hasChanges
    }
    
    // MARK: - Actions
    
    func validateName() {
        let trimmed = editedName.trimmingCharacters(in: .whitespaces)
        
        if trimmed.isEmpty {
            nameError = nil // Don't show error for empty (just disable save)
            return
        }
        
        // Check if name already exists (but not the current profile)
        if let existing = profileStorage.findProfile(name: trimmed),
           existing.id != profile.id {
            nameError = "A player named '\(existing.name)' already exists"
            return
        }
        
        nameError = nil
    }
    
    func saveChanges() {
        let trimmed = editedName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, nameError == nil else { return }
        
        // Update profile name if changed
        if trimmed != profile.name {
            profileStorage.renameProfile(id: profile.id, newName: trimmed)
        }
        
        // Update color if changed
        if selectedColorName != profile.preferredColorName {
            profileStorage.updatePreferredColor(for: trimmed, colorName: selectedColorName)
        }
        
        // Update emoji if changed
        if selectedEmoji != profile.preferredEmoji {
            profileStorage.updatePreferredEmoji(for: trimmed, emoji: selectedEmoji)
        }
        
        dismiss()
    }
    
    func deleteProfile() {
        profileStorage.deleteProfile(profile)
        dismiss()
    }
}

// MARK: - Stat Box Component

struct StatBox: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(minWidth: 60)
    }
}

#Preview {
    ProfileEditorView(profile: PlayerProfile(name: "Emma", preferredColorName: "purple", gamesPlayed: 5, totalWins: 2, highestScore: 287))
}

