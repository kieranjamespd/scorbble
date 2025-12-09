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
    @State private var showPastGames = false
    
    // Launch animation state
    @State private var tileOpacities: [Double] = Array(repeating: 0, count: 8)
    @State private var tileScales: [Double] = Array(repeating: 0.5, count: 8)
    @State private var subtitleOpacity: Double = 0
    @State private var buttonsOpacity: Double = 0
    @State private var buttonsOffset: CGFloat = 30
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
                    
                    // Main Menu Buttons with animation
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
                            subtitle: "Verify valid words",
                            icon: "text.book.closed.fill",
                            color: Color(hex: "60a5fa")
                        ) {
                            showWordChecker = true
                        }
                        
                        MenuButton(
                            title: "Past Games",
                            subtitle: "View game history",
                            icon: "clock.fill",
                            color: Color(hex: "f472b6")
                        ) {
                            showPastGames = true
                        }
                    }
                    .padding(.horizontal, 24)
                    .opacity(buttonsOpacity)
                    .offset(y: buttonsOffset)
                    
                    Spacer()
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
            .navigationDestination(isPresented: $showPastGames) {
                PastGamesView()
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
        
        // Phase 2: Fade in subtitle
        withAnimation(.easeOut(duration: 0.4).delay(0.8)) {
            subtitleOpacity = 1.0
        }
        
        // Phase 3: Slide up and fade in buttons
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(1.1)) {
            buttonsOpacity = 1.0
            buttonsOffset = 0
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

