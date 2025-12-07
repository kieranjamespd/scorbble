//
//  HomeView.swift
//  Scorbble
//
//  Created by Kieran James on 07.12.25.
//

import SwiftUI

struct HomeView: View {
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
                
                VStack(spacing: 32) {
                    Spacer()
                    
                    // App Logo & Title
                    VStack(spacing: 16) {
                        // Scrabble tile style logo
                        HStack(spacing: 4) {
                            ForEach(Array("SCORBBLE".enumerated()), id: \.offset) { index, letter in
                                TileView(letter: String(letter), points: tilePoints(for: letter))
                            }
                        }
                        
                        Text("Scrabble Score Keeper")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    // Main Menu Buttons
                    VStack(spacing: 16) {
                        MenuButton(
                            title: "New Game",
                            subtitle: "Start tracking scores",
                            icon: "play.fill",
                            color: Color(hex: "4ade80")
                        ) {
                            // TODO: Navigate to Game Setup
                        }
                        
                        MenuButton(
                            title: "Word Checker",
                            subtitle: "Verify valid words",
                            icon: "text.book.closed.fill",
                            color: Color(hex: "60a5fa")
                        ) {
                            // TODO: Navigate to Word Checker
                        }
                        
                        MenuButton(
                            title: "Past Games",
                            subtitle: "View game history",
                            icon: "clock.fill",
                            color: Color(hex: "f472b6")
                        ) {
                            // TODO: Navigate to Game History
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                    Spacer()
                }
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

