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
    @AppStorage("dailyGoalSeconds") private var dailyGoalSeconds: Double = 2 * 60 * 60
    @AppStorage("streakCount") private var streakCount = 0
    @AppStorage("streakLastDate") private var streakLastDate = ""
    @State private var currentDate = Date()
    @State private var testingMode = true
    @State private var petScale = 1.0
    @State private var petOffset: CGFloat = 0
    
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
    
    private var petAnimationDuration: Double {
        if currentHealth >= 80 {
            return 1.5
        } else if currentHealth >= 50 {
            return 2.0
        } else if currentHealth >= 20 {
            return 2.8
        } else {
            return 4.0
        }
    }
    
    private func startPetAnimation() {
        petScale = 1.0
        petOffset = 0
        
        withAnimation(
            .easeInOut(duration: petAnimationDuration)
            .repeatForever(autoreverses: true)
        ) {
            petScale = 1.05
            petOffset = -8
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
                scheduleBreakNotifications()
            }
        }
    }

    private func scheduleBreakNotifications() {
        
        let center = UNUserNotificationCenter.current()
        
        center.removePendingNotificationRequests(
            withIdentifiers: [
                "mochi.breakReminder.1",
                "mochi.breakReminder.2",
                "mochi.breakReminder.3"
            ]
        )
        
        let firstContent = UNMutableNotificationContent()
        firstContent.title = "🐣 Mochi is getting tired"
        firstContent.body = "I'm okay, but maybe it's time for a little break? 🙂"
        firstContent.sound = .default
        
        let firstTrigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 10,
            repeats: false
        )
        
        let firstRequest = UNNotificationRequest(
            identifier: "mochi.breakReminder.1",
            content: firstContent,
            trigger: firstTrigger
        )
        
        center.add(firstRequest)
        
        
        let secondContent = UNMutableNotificationContent()
        secondContent.title = "🥺 Mochi needs a break"
        secondContent.body = "My health is getting low. Please put your phone down for a while."
        secondContent.sound = .default
        
        let secondTrigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 40,
            repeats: false
        )
        
        let secondRequest = UNNotificationRequest(
            identifier: "mochi.breakReminder.2",
            content: secondContent,
            trigger: secondTrigger
        )
        
        center.add(secondRequest)
        
        let finalContent = UNMutableNotificationContent()
        finalContent.title = "😭 Mochi really needs you"
        finalContent.body = "I'm exhausted. Please give me a proper break."
        finalContent.sound = .default
        
        let finalTrigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 60,
            repeats: false
        )
        
        let finalRequest = UNNotificationRequest(
            identifier: "mochi.breakReminder.3",
            content: finalContent,
            trigger: finalTrigger
        )
        
        center.add(finalRequest)
    }
    
    private func cancelBreakNotifications() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(
                withIdentifiers: [
                    "mochi.breakReminder.1",
                    "mochi.breakReminder.2",
                    "mochi.breakReminder.3"
                ]
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
        let calendar = Calendar.current
        
        let today = calendar.startOfDay(for: Date())
        let todayTimestamp = today.timeIntervalSince1970
        let todayString = String(todayTimestamp)
        
        if dailyUsageDate.isEmpty {
            dailyUsageDate = todayString
            return
        }
        
        if dailyUsageDate == todayString {
            return
        }
        
        if dailyUsageSeconds <= dailyGoalSeconds {
            let previousDate = Date(
                timeIntervalSince1970: Double(dailyUsageDate) ?? 0
            )
            
            let yesterday = calendar.date(
                byAdding: .day,
                value: -1,
                to: today
            )!
            
            if calendar.isDate(previousDate, inSameDayAs: yesterday) {
                streakCount += 1
            } else {
                streakCount = 1
            }
            
            streakLastDate = dailyUsageDate
        } else {
            streakCount = 0
            streakLastDate = ""
        }
        
        dailyUsageSeconds = 0
        dailyUsageDate = todayString
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
                .font(.system(size: 140))
                .scaleEffect(petScale)
                .offset(y: petOffset)
                .onAppear {
                    startPetAnimation()
                }
                .onChange(of: currentHealth) {
                    startPetAnimation()
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
                    value: min(todayUsage / dailyGoalSeconds, 1.0)
                )
                .tint(.orange)
                
                Text("Goal: \(formatUsage(dailyGoalSeconds))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Picker("Daily Goal", selection: $dailyGoalSeconds) {
                    Text("1 hour").tag(1 * 60 * 60.0)
                    Text("2 hours").tag(2 * 60 * 60.0)
                    Text("3 hours").tag(3 * 60 * 60.0)
                    Text("4 hours").tag(4 * 60 * 60.0)
                }
                .pickerStyle(.menu)
            }
            VStack(spacing: 8) {
                
                Text("🔥 \(streakCount) Day Streak")
                    .font(.headline)
                
                if streakCount == 0 {
                    Text("Stay under your goal today!")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Keep it going! 🔥")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
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
                        cancelBreakNotifications()
                        
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
                                Text("Mochi is fully recovered! 🎉🐣")
                                    .font(.headline)
                            } else if recoveredHealth >= 75 {
                                Text("Mochi feels so much better! 🥰")
                                    .font(.headline)
                            } else if recoveredHealth >= 50 {
                                Text("You're doing great! Keep resting. 🌱")
                                    .font(.headline)
                            } else {
                                Text("Thank you for putting your phone down! 🥹")
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
