//
//  ContentView.swift
//  Mochi
//
//  Created by Gaurav on 17/08/26.
//

import SwiftUI

struct ContentView: View {
    @State private var health = 100
    @State private var sessionStartTime: Date? = nil
    
    private var petMood: String {
        if health >= 80 {
            return "Mochi is feeling great! 😊"
        } else if health >= 50 {
            return "Mochi is feeling okay 🙂"
        } else if health >= 20 {
            return "Mochi is getting tired 😟"
        } else {
            return "Mochi needs a break! 😭"
        }
    }
    
    private var petEmoji: String {
        if health >= 80 {
            return "🐣"
        } else if health >= 50 {
            return "🐥"
        } else if health >= 20 {
            return "🥺"
        } else {
            return "😭"
        }
    }
    
    private func changeHealth(by amount: Int) {
        health = min(100, max(0, health + amount))
    }
    
    private func startSession() {
        sessionStartTime = Date()
    }
    
    var body: some View {
        VStack(spacing: 25) {
            
            Text("Mochi")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Your screen-time pet")
                .foregroundStyle(.secondary)
            
            Text(petEmoji)
                .font(.system(size: 150))
            
            Text("❤️ \(health) / 100")
                .font(.title2)
                .fontWeight(.semibold)
            
            ProgressView(value: Double(health) / 100.0)
                .padding(.horizontal, 40)
            
            Text(petMood)
                .font(.headline)
            
            if sessionStartTime == nil {
                Button("Start Using Phone") {
                    startSession()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
