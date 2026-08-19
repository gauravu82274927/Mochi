//
//  ContentView.swift
//  Mochi
//
//  Created by Gaurav on 17/08/26.
//

import SwiftUI
import Combine
import UserNotifications

struct DayResult: Codable {
    let date: String
    let achieved: Bool
}

struct ContentView: View {
    @AppStorage("mochiHealth") private var health = 100
    @AppStorage("sessionStartTime") private var sessionStartTime: Double = 0
    @AppStorage("recoveryStartTime") private var recoveryStartTime: Double = 0
    @AppStorage("dailyUsageSeconds") private var dailyUsageSeconds: Double = 0
    @AppStorage("dailyUsageDate") private var dailyUsageDate = ""
    @AppStorage("dailyGoalSeconds") private var dailyGoalSeconds: Double = 2 * 60 * 60
    @AppStorage("streakCount") private var streakCount = 0
    @AppStorage("streakLastDate") private var streakLastDate = ""
    @AppStorage("sessionStartHealth") private var sessionStartHealth = 100
    @AppStorage("dayResultsData") private var dayResultsData: Data = Data()
    @AppStorage("isDarkMode") private var isDarkMode = true
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
        cancelBreakNotifications()
        
        sessionStartHealth = health
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
    
    private func dateKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.calendar = Calendar.current
        formatter.timeZone = Calendar.current.timeZone
        return formatter.string(from: date)
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
    
    private func saveDayResult(date: String, achieved: Bool) {
        var results = loadDayResults()
        
        results.removeAll { $0.date == date }
        results.append(
            DayResult(
                date: date,
                achieved: achieved
            )
        )
        
        if let data = try? JSONEncoder().encode(results) {
            dayResultsData = data
        }
    }

    private func loadDayResults() -> [DayResult] {
        guard !dayResultsData.isEmpty else {
            return []
        }
        
        return (try? JSONDecoder().decode(
            [DayResult].self,
            from: dayResultsData
        )) ?? []
    }
    
    private func resetUsageIfNewDay() {

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let todayString = dateKey(today)

        if dailyUsageDate.isEmpty {
            dailyUsageDate = todayString

            streakCount = 1
            streakLastDate = todayString

            saveDayResult(
                date: todayString,
                achieved: dailyUsageSeconds <= dailyGoalSeconds
            )

            return
        }

        if dailyUsageDate == todayString {
            return
        }

        let previousDayAchieved = dailyUsageSeconds <= dailyGoalSeconds

        saveDayResult(
            date: dailyUsageDate,
            achieved: previousDayAchieved
        )

        if previousDayAchieved {

            let yesterday = calendar.date(
                byAdding: .day,
                value: -1,
                to: today
            )!

            let yesterdayString = dateKey(yesterday)

            if dailyUsageDate == yesterdayString {
                streakCount += 1
            } else {
                streakCount = 1
            }

            streakLastDate = dailyUsageDate

        } else {

            streakCount = 0
            streakLastDate = ""
        }

        // Start the new day
        dailyUsageSeconds = 0
        dailyUsageDate = todayString
    }
    
    private func healthForElapsedTime(_ seconds: TimeInterval) -> Int {
        if testingMode {
            let healthLoss: Int
            
            if seconds < 10 {
                healthLoss = 0
            } else if seconds < 20 {
                healthLoss = 10
            } else if seconds < 30 {
                healthLoss = 20
            } else if seconds < 40 {
                healthLoss = 35
            } else if seconds < 60 {
                healthLoss = 50
            } else if seconds < 90 {
                healthLoss = 75
            } else {
                healthLoss = 100
            }
            
            return max(0, sessionStartHealth - healthLoss)
        }
        else {
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
        NavigationStack{
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                RadialGradient(
                    colors: [
                        Color.yellow.opacity(0.05),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 20,
                    endRadius: 180
                )
                .ignoresSafeArea()
                
                VStack(spacing: 14) {
                    ZStack {
                        Text("Mochi")
                            .font(.system(size: 32, weight: .bold))

                        HStack {
                            Spacer()

                            HStack(spacing: 8) {

                                Button {
                                    isDarkMode.toggle()
                                } label: {
                                    Image(systemName: isDarkMode ? "sun.max.fill" : "moon.fill")
                                        .font(.title3)
                                        .foregroundStyle(.primary)
                                        .padding(10)
                                        .background(.ultraThinMaterial)
                                        .clipShape(Circle())
                                }

                                NavigationLink {
                                    CalendarView()
                                } label: {
                                    Image(systemName: "calendar")
                                        .font(.title3)
                                        .foregroundStyle(.primary)
                                        .padding(10)
                                        .background(.ultraThinMaterial)
                                        .clipShape(Circle())
                                }
                            }
                        }
                    }
                    
                    Text("Your screen-time pet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 8)
                    
                    
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        .yellow.opacity(
                                            currentHealth >= 50 ? 0.18 : 0.08
                                        ),
                                        .clear
                                    ],
                                    center: .center,
                                    startRadius: 10,
                                    endRadius: 100
                                )
                            )
                            .frame(width: 190, height: 190)
                        
                        Text(petEmoji)
                            .font(.system(size: 125))
                            .scaleEffect(petScale)
                            .offset(y: petOffset)
                            .shadow(
                                color: .yellow.opacity(0.15),
                                radius: 15
                            )
                            .onAppear {
                                startPetAnimation()
                            }
                            .onChange(of: currentHealth) {
                                startPetAnimation()
                            }
                    }
                    .frame(height: 150)
                    
                    
                    VStack(spacing: 8) {
                        HStack {
                            Text("Health")
                                .font(.headline)
                            
                            Spacer()
                            
                            Text("❤️ \(currentHealth)/100")
                                .font(.headline)
                        }
                        
                        ProgressView(
                            value: Double(currentHealth) / 100.0
                        )
                        .tint(.pink)
                    }
                    .mochiCard()
                    
                    
                    VStack(spacing: 8) {
                        HStack {
                            Text("Today's Usage")
                                .font(.headline)
                            
                            Spacer()
                            
                            Text(formatUsage(todayUsage))
                                .font(.headline)
                        }
                        
                        ProgressView(
                            value: min(
                                todayUsage / dailyGoalSeconds,
                                1.0
                            )
                        )
                        .tint(.orange)
                        
                        HStack {
                            Text("Goal: \(formatUsage(dailyGoalSeconds))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                            
                            Picker("Daily Goal", selection: $dailyGoalSeconds) {
                                Text("1 hour").tag(1 * 60 * 60.0)
                                Text("2 hours").tag(2 * 60 * 60.0)
                                Text("3 hours").tag(3 * 60 * 60.0)
                                Text("4 hours").tag(4 * 60 * 60.0)
                            }
                            .pickerStyle(.menu)
                        }
                    }
                    .mochiCard()
                    
                    
                    VStack(spacing: 5) {
                        Text("🔥 \(streakCount) Day Streak")
                            .font(.headline)
                        
                        Text(
                            streakCount == 0
                            ? "Stay under your goal!"
                            : "Keep it going! 🔥"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .mochiCard()
                    
                    if sessionStartTime > 0 {
                        VStack(spacing: 14) {

                            HStack {
                                Text("📱 Using Phone")
                                    .font(.headline)

                                Spacer()
                            }

                            TimelineView(
                                .periodic(from: .now, by: 1)
                            ) { context in

                                let startTime = Date(
                                    timeIntervalSince1970: sessionStartTime
                                )

                                let elapsed =
                                    context.date.timeIntervalSince(startTime)

                                let sessionHealth =
                                    healthForElapsedTime(elapsed)

                                HStack {
                                    Text(formatTime(elapsed))
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .monospacedDigit()

                                    Spacer()

                                    Text("❤️ \(sessionHealth)/100")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                }
                            }

                            Button("I'm Putting My Phone Down") {
                                cancelBreakNotifications()

                                let startTime = Date(
                                    timeIntervalSince1970: sessionStartTime
                                )

                                let sessionDuration =
                                    Date().timeIntervalSince(startTime)

                                dailyUsageSeconds += sessionDuration
                                health = currentHealth
                                sessionStartTime = 0
                                recoveryStartTime =
                                    Date().timeIntervalSince1970
                            }
                            .buttonStyle(.borderedProminent)
                            .frame(maxWidth: .infinity)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 22)
                                .fill(Color(.systemGray6).opacity(0.06))
                        )

                    } else if recoveryStartTime > 0 {
                        
                        VStack(spacing: 6) {
                            Text("🌱 Recovery Mode")
                                .font(.headline)
                            
                            TimelineView(
                                .periodic(from: .now, by: 1)
                            ) { context in
                                
                                let startTime = Date(
                                    timeIntervalSince1970: recoveryStartTime
                                )
                                
                                let elapsed =
                                context.date.timeIntervalSince(startTime)
                                
                                let recoveredHealth =
                                healthForRecovery(elapsed)
                                
                                HStack(spacing: 20) {
                                    Text(formatTime(elapsed))
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .monospacedDigit()
                                    
                                    Text("❤️ \(recoveredHealth)/100")
                                        .font(.title3)
                                        .fontWeight(.semibold)
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
                .padding(.horizontal, 8)
                .padding(.top, 4)
                .padding(.bottom, 8)
                .frame(maxWidth: .infinity)
                .foregroundStyle(.primary)
            }
        }
        .onReceive(
            Timer.publish(
                every: 1,
                on: .main,
                in: .common
            ).autoconnect()
        ) { date in
            
            currentDate = date
            
            if recoveryStartTime > 0 {
                let startTime = Date(
                    timeIntervalSince1970: recoveryStartTime
                )
                
                let elapsed =
                    date.timeIntervalSince(startTime)
                
                if healthForRecovery(elapsed) >= 100 {
                    health = 100
                    recoveryStartTime = 0
                }
            }
        }
        .onAppear {
            resetUsageIfNewDay()
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}

struct MochiCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    func body(content: Content) -> some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(
                Color.primary.opacity(colorScheme == .dark ? 0.08 : 0.045)
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 20,
                    style: .continuous
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: 20,
                    style: .continuous
                )
                .stroke(
                    Color.white.opacity(0.08),
                    lineWidth: 0.8
                )
            }
    }
}
extension View {
    func mochiCard() -> some View {
        modifier(MochiCardModifier())
    }
}

struct CalendarView: View {
    @AppStorage("dayResults") private var dayResultsData: Data = Data()
    @AppStorage("dailyUsageSeconds") private var dailyUsageSeconds: Double = 0
    @AppStorage("dailyGoalSeconds") private var dailyGoalSeconds: Double = 2 * 60 * 60

    @State private var displayedMonth = Date()

    private let calendar = Calendar.current
    
    private var dayResults: [DayResult] {
        guard !dayResultsData.isEmpty else {
            return []
        }
        
        return (try? JSONDecoder().decode(
            [DayResult].self,
            from: dayResultsData
        )) ?? []
    }
    
    private var monthTitle: String {
        displayedMonth.formatted(
            .dateTime
                .month(.wide)
                .year()
        )
    }
    
    private var daysInMonth: [Date] {
        guard let range = calendar.range(
            of: .day,
            in: .month,
            for: displayedMonth
        ) else {
            return []
        }
        
        return range.compactMap { day in
            calendar.date(
                bySetting: .day,
                value: day,
                of: displayedMonth
            )
        }
    }
    
    private var firstWeekdayOffset: Int {
        let firstDay = calendar.date(
            from: calendar.dateComponents(
                [.year, .month],
                from: displayedMonth
            )
        )!
        
        let weekday = calendar.component(
            .weekday,
            from: firstDay
        )
        
        return (weekday - calendar.firstWeekday + 7)
            % 7
    }
    
    private func dateKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        return formatter.string(from: date)
    }
    
    private func result(for date: Date) -> Bool? {
        let key = dateKey(date)

        if calendar.isDateInToday(date) {
            return dailyUsageSeconds <= dailyGoalSeconds
        }

        for result in dayResults {
            if result.date == key {
                return result.achieved
            }
        }

        return nil
    }
    
    private func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }
    
    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground)                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                HStack {
                    Button {
                        displayedMonth = calendar.date(
                            byAdding: .month,
                            value: -1,
                            to: displayedMonth
                        ) ?? displayedMonth
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                    }
                    
                    Spacer()
                    
                    Text(monthTitle)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button {
                        displayedMonth = calendar.date(
                            byAdding: .month,
                            value: 1,
                            to: displayedMonth
                        ) ?? displayedMonth
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.title3)
                    }
                }
                .padding(.horizontal)
                
                let weekdays = calendar.shortStandaloneWeekdaySymbols
                
                LazyVGrid(
                    columns: Array(
                        repeating: GridItem(.flexible()),
                        count: 7
                    )
                ) {
                    ForEach(
                        Array(weekdays.enumerated()),
                        id: \.offset
                    ) { _, weekday in
                        Text(weekday)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)
                
                LazyVGrid(
                    columns: Array(
                        repeating: GridItem(.flexible()),
                        count: 7
                    ),
                    spacing: 12
                ) {
                    
                    ForEach(
                        0..<firstWeekdayOffset,
                        id: \.self
                    ) { _ in
                        Color.clear
                            .frame(height: 42)
                    }
                    
                    ForEach(daysInMonth, id: \.self) { date in
                        
                        let result = result(for: date)
                        
                        ZStack {
                            Circle()
                                .fill(
                                    result == true
                                    ? Color.green.opacity(0.25)
                                    : result == false
                                    ? Color.red.opacity(0.25)
                                    : Color.white.opacity(0.05)
                                )
                            
                            Text("\(calendar.component(.day, from: date))")
                                .foregroundStyle(.primary)
                            
                            if result == true {
                                Image(systemName: "checkmark")
                                    .font(.caption2)
                                    .foregroundStyle(.green)
                                    .offset(x: 14, y: -14)
                            } else if result == false {
                                Image(systemName: "xmark")
                                    .font(.caption2)
                                    .foregroundStyle(.red)
                                    .offset(x: 14, y: -14)
                            }
                        }
                        .frame(height: 42)
                        .overlay {
                            if isToday(date) {
                                Circle()
                                    .stroke(
                                        .white.opacity(0.8),
                                        lineWidth: 1.5
                                    )
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .foregroundStyle(.primary)
            .padding(.top)
        }
        .navigationTitle("Calendar")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            print("DAY RESULTS:", dayResults)
        }
    }
}

#Preview {
    ContentView()
}
