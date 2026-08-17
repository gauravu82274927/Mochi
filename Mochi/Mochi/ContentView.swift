//
//  ContentView.swift
//  Mochi
//
//  Created by Gaurav on 17/08/26.
//

import SwiftUI
import Combine
import UserNotifications

struct ContentView: View {
    @AppStorage("mochiHealth") private var health = 100
    @AppStorage("sessionStartTime") private var sessionStartTime: Double = 0
    @AppStorage("recoveryStartTime") private var recoveryStartTime: Double = 0
    @AppStorage("dailyUsageSeconds") private var dailyUsageSeconds: Double = 0
    @AppStorage("dailyUsageDate") private var dailyUsageDate = ""
    @State private var currentDate = Date()
    @State private var testingMode = true
    @State private var petScale = 1.0
    
    private var currentHealth: Int {
        if sessionStartTime > 0 {
            let startTime = Date(timeIntervalSince1970: sessionStartTime)
            let elapsed = currentDate.timeIntervalSince(startTime)
            return healthForElapsedTime(elapsed)
        }
        
        if recoveryStartTime > 0 {
            let startTime = Date(timeIntervalSince1970: recoveryStartTime)
            let elapsed = currentDate.timeIntervalSince(startTime)
            return healthForRecovery(elapsed)
        }
        
        return health
    }
    
    private var todayUsage: TimeInterval {
        if sessionStartTime > 0 {
            let startTime = Date(timeIntervalSince1970: sessionStartTime)
            return dailyUsageSeconds + currentDate.timeIntervalSince(startTime)
        }
        
        return dailyUsageSeconds
    }
    
    private var petMood: String {
        if currentHealth >= 80 {
            return "Mochi is feeling great! 😊"
        } else if currentHealth >= 50 {
            return "Mochi is feeling okay 🙂"
        } else if currentHealth >= 20 {
            return "Mochi is getting tired 😟"
        } else {
            return "Mochi needs a break! 😭"
        }
    }
    
    private var petEmoji: String {
        if currentHealth >= 80 {
            return "🐣"
        } else if currentHealth >= 50 {
            return "🐥"
        } else if currentHealth >= 20 {
            return "🥺"
        } else {
            return "😭"
        }
    }
    
    private func changeHealth(by amount: Int) {
        health = min(100, max(0, health + amount))
    }
    
    private func startSession() {
        sessionStartTime = Date().timeIntervalSince1970
        requestNotificationPermission()
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound]
        ) { granted, error in
            
            if let error = error {
                print("Notification permission error: \(error)")
                return
            }
            
            if granted {
                scheduleBreakNotification()
            }
        }
    }

    private func scheduleBreakNotification() {
        let content = UNMutableNotificationContent()
        
        content.title = "🐣 Mochi needs you!"
        content.body = "You've been using your phone for a while. Give Mochi a break? 🥺"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 10,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "mochi.breakReminder",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func cancelBreakNotification() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(
                withIdentifiers: ["mochi.breakReminder"]
            )
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds)
        
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let remainingSeconds = totalSeconds % 60
        
        return String(format: "%02d:%02d:%02d", hours, minutes, remainingSeconds)
    }
    
    private func formatUsage(_ seconds: TimeInterval) -> String {
        let totalMinutes = Int(seconds) / 60
        
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func resetUsageIfNewDay() {
        let today = Calendar.current
            .startOfDay(for: Date())
            .timeIntervalSince1970
        
        if dailyUsageDate != String(today) {
            dailyUsageSeconds = 0
            dailyUsageDate = String(today)
        }
    }
    
    private func healthForElapsedTime(_ seconds: TimeInterval) -> Int {
        if testingMode {
            if seconds < 10 {
                return 100
            } else if seconds < 20 {
                return 90
            } else if seconds < 30 {
                return 80
            } else if seconds < 40 {
                return 65
            } else if seconds < 60 {
                return 50
            } else if seconds < 90 {
                return 25
            } else {
                return 0
            }
            
        } else {
            let twoHours: TimeInterval = 2 * 60 * 60
            let percentage = max(0, 1 - (seconds / twoHours))
            
            return Int(percentage * 100)
        }
    }
    
    private func healthForRecovery(_ seconds: TimeInterval) -> Int {
        let recoveryPoints = Int(seconds / 10) * 5
        
        return min(100, health + recoveryPoints)
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
                .scaleEffect(petScale)
                .animation(
                    .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true),
                    value: petScale
                )
                .onAppear {
                    petScale = 1.05
                }
            
            VStack(spacing: 12) {
                
                HStack {
                    Text("Health")
                        .font(.headline)
                    
                    Spacer()
                    
                    Text("❤️ \(currentHealth)/100")
                        .font(.headline)
                }
                
                ProgressView(value: Double(currentHealth) / 100.0)
                    .tint(.pink)
            }
            VStack(spacing: 10) {
                
                HStack {
                    Text("Today's Usage")
                        .font(.headline)
                    
                    Spacer()
                    
                    Text(formatUsage(todayUsage))
                        .font(.headline)
                }
                
                ProgressView(
                    value: min(todayUsage / (2 * 60 * 60), 1.0)
                )
                .tint(.orange)
                
                Text("Goal: 2 hours")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal)
            
            Text(petMood)
                .font(.headline)
            
            if sessionStartTime > 0 {
                
                VStack(spacing: 10) {
                    
                    Text("📱 Using Phone")
                        .font(.headline)
                    
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        let startTime = Date(timeIntervalSince1970: sessionStartTime)
                        let elapsed = context.date.timeIntervalSince(startTime)
                        let sessionHealth = healthForElapsedTime(elapsed)
                        
                        VStack(spacing: 10) {
                            
                            Text(formatTime(elapsed))
                                .font(.title)
                                .fontWeight(.bold)
                                .monospacedDigit()
                            
                            Text("❤️ \(sessionHealth) / 100")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                    }
                    
                    Button("I'm Putting My Phone Down") {
                        cancelBreakNotification()
                        
                        let startTime = Date(timeIntervalSince1970: sessionStartTime)
                        let sessionDuration = Date().timeIntervalSince(startTime)
                        
                        dailyUsageSeconds += sessionDuration
                        
                        health = currentHealth
                        sessionStartTime = 0
                        recoveryStartTime = Date().timeIntervalSince1970
                    }
                    .buttonStyle(.borderedProminent)
                }
                
            } else if recoveryStartTime > 0 {
                
                VStack(spacing: 10) {
                    
                    Text("🌱 Recovery Mode")
                        .font(.headline)
                    
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        let startTime = Date(timeIntervalSince1970: recoveryStartTime)
                            let elapsed = context.date.timeIntervalSince(startTime)
                            let recoveredHealth = healthForRecovery(elapsed)

                        VStack(spacing: 10) {
                            
                            Text(formatTime(elapsed))
                                .font(.title)
                                .fontWeight(.bold)
                                .monospacedDigit()
                            
                            Text("❤️ \(recoveredHealth) / 100")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            if recoveredHealth >= 100 {
                                Text("Mochi is fully recovered! 🥹✨")
                                    .font(.headline)
                            } else {
                                Text("Mochi is recovering! 🥹")
                                    .font(.headline)
                            }
                        }
                    }
                    
                    Button("I'm Back") {
                        health = currentHealth
                        recoveryStartTime = 0
                    }
                    .buttonStyle(.borderedProminent)
                }
                
            } else {
                
                Button("Start Using Phone") {
                    startSession()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .onReceive(
            Timer.publish(every: 1, on: .main, in: .common).autoconnect()
        ) { date in
            currentDate = date
            
            if recoveryStartTime > 0 {
                let startTime = Date(timeIntervalSince1970: recoveryStartTime)
                let elapsed = date.timeIntervalSince(startTime)
                
                if healthForRecovery(elapsed) >= 100 {
                    health = 100
                    recoveryStartTime = 0
                }
            }
        }
        .padding()
        .onAppear{
            resetUsageIfNewDay()
        }
    }
}

#Preview {
    ContentView()
}
