//
//  ContentView.swift
//  Pomosh
//
//  Created by Steven J. Selcuk on 2.06.2020.
//  Copyright © 2020 Steven J. Selcuk. All rights reserved.
//

import SwiftUI
import UserNotifications

let settings = UserDefaults.standard

struct ContentView: View {
    // MARK: - Properties

    @State var showingSettings = false

    @ObservedObject var ThePomoshTimer = PomoshTimer()
    var isIpad = UIDevice.current.model.hasPrefix("iPad")
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    let notificationCenter = UNUserNotificationCenter.current()
    let generator = UIImpactFeedbackGenerator(style: .heavy)

    // MARK: - InDaClub
    // 알람 관련
    init() {
        if ThePomoshTimer.showNotifications {
            notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                if granted {
                    settings.set(true, forKey: "didNotificationsAllowed")
                } else {
                    settings.set(false, forKey: "didNotificationsAllowed")
                }
            }
        }
        // Reset notification badge when app opened
        UIApplication.shared.applicationIconBadgeNumber = 0
        // No sleep 🐑
        UIApplication.shared.isIdleTimerDisabled = true
    }

    // MARK: - Main Component

    var body: some View {
        NavigationView {
            
            VStack(alignment: .center) {
                TimerRing(color1: #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1), color2: #colorLiteral(red: 0.3647058904, green: 0.06666667014, blue: 0.9686274529, alpha: 1), width: isIpad ? 600 : 300, height: isIpad ? 600 : 300, percent: CGFloat(((Float(ThePomoshTimer.isBreakActive ? ThePomoshTimer.breakTime : ThePomoshTimer.fulltime) - Float(ThePomoshTimer.timeRemaining)) / Float(ThePomoshTimer.isBreakActive ? ThePomoshTimer.breakTime : ThePomoshTimer.fulltime)) * 100), Timer: ThePomoshTimer)
                    .padding()
                    .scaledToFit()
                    .frame(maxWidth: 1200, maxHeight: 1200, alignment: .center)
            }
            .navigationBarItems(
                //타이머 skip
                leading: Button(action: {
                    generator.impactOccurred()
                    self.ThePomoshTimer.timeRemaining = 3
//                    if self.ThePomoshTimer.round != 0 {
//                        self.ThePomoshTimer.round -= 1
//                    }
//                    self.ThePomoshTimer.fulltime = UserDefaults.standard.integer(forKey: "time")
//                    self.ThePomoshTimer.timeRemaining = UserDefaults.standard.integer(forKey: "time")
                    if self.ThePomoshTimer.playSound {
                       self.ThePomoshTimer.endSound()
                    }
                }) {
                    HStack {
                        Image("Skip")
                            .antialiased(false)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 28, maxHeight: 28, alignment: .center)
                    }
                } // 설정 버튼
                .buttonStyle(PomoshButtonStyle()),
                trailing:
                Button(action: {
                    generator.impactOccurred()
                    self.showingSettings.toggle()
                }) {
                    HStack {
                        Image("Settings")
                            .antialiased(/*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 28, maxHeight: 28, alignment: .center)
                    }
                }
                .buttonStyle(PomoshButtonStyle())
            )
            .sheet(isPresented: $showingSettings) {
                SettingsView(timer: ThePomoshTimer)
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
            .background(Color("Background"))
            .edgesIgnoringSafeArea(.all)
            // 앱이 백그라운드
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                if self.ThePomoshTimer.isActive, self.ThePomoshTimer.showNotifications, self.ThePomoshTimer.timeRemaining > 0 {
                    self.scheduleAlarmNotification(sh: TimeInterval(self.ThePomoshTimer.timeRemaining))
                    settings.set(self.ThePomoshTimer.round, forKey: "lastKnownRound")
                    settings.set(self.ThePomoshTimer.runnedRounds, forKey: "lastRunnedRound")
                    settings.set(self.ThePomoshTimer.isBreakActive, forKey: "itWasBreak")
                }
            }
            // 앱 종료
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)) { _ in
                if self.ThePomoshTimer.isActive, self.ThePomoshTimer.showNotifications, self.ThePomoshTimer.timeRemaining > 0 {
                    self.scheduleAlarmNotification(sh: TimeInterval(self.ThePomoshTimer.timeRemaining))
                    settings.set(self.ThePomoshTimer.runnedRounds, forKey: "lastKnownRound")
                    settings.set(self.ThePomoshTimer.isBreakActive, forKey: "itWasBreak")
                }
            }
            //앱이 active될때 post
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                cancelNotifications()
                if isCameFromNotification {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        generator.impactOccurred()
                        withAnimation(.interpolatingSpring(mass: 1.0,
                                                           stiffness: 100.0,
                                                           damping: 10,
                                                           initialVelocity: 0)) {
                            self.ThePomoshTimer.isActive = true
                            self.ThePomoshTimer.timeRemaining = 2
                            self.ThePomoshTimer.round = UserDefaults.standard.integer(forKey: "lastKnownRound")
                            self.ThePomoshTimer.runnedRounds = UserDefaults.standard.integer(forKey: "lastRunnedRound")
                            if UserDefaults.standard.bool(forKey: "itWasBreak") {
                                self.ThePomoshTimer.isBreakActive = true
                            } else {
                                self.ThePomoshTimer.isBreakActive = false
                            }
                        }
                    }

                    isCameFromNotification = false
                }
            }
            .onReceive(timer) { _ in
                //guard 조건이 아니면 끝내라. active상태가 아니면 끝내라.x
                guard self.ThePomoshTimer.isActive else { return }
                
                
                // 0초보다 많이 남았으면 timeRemaining -1
                if self.ThePomoshTimer.timeRemaining > 0 {
                    self.ThePomoshTimer.timeRemaining -= 1
                    if self.ThePomoshTimer.isBreakActive == false {
                        self.ThePomoshTimer.totalTime += 1
                        self.ThePomoshTimer.todayTime += 1
                    }
                    let date = Date()
                    let calendar = Calendar.current
                    let components = calendar.dateComponents([.hour, .minute, .second], from: date)
                    
                    if (components.hour == 0 && components.minute == 0 && components.second == 0) {
                        resetUserDefaults()
                    }
                }
                
                //1초 남았고, round가 1이상이면
                if self.ThePomoshTimer.timeRemaining == 1, self.ThePomoshTimer.round > 0 {
                    //끝내는 소리
                    if self.ThePomoshTimer.playSound {
                        self.ThePomoshTimer.endSound()
                    }
                    
                    //쉬는시간
                    self.ThePomoshTimer.isBreakActive.toggle()

                    if self.ThePomoshTimer.isBreakActive == true {
                        if self.ThePomoshTimer.round == 1 {
                            self.ThePomoshTimer.timeRemaining = 0
                            self.ThePomoshTimer.isBreakActive = false
                        } else {
                            if self.ThePomoshTimer.runnedRounds == self.ThePomoshTimer.longBreakRound - 1 {
//                               self.ThePomoshTimer.timeRemaining = UserDefaults.standard.optionalInt(forKey: "fullLongBreakTime") ?? 1200
                                self.ThePomoshTimer.timeRemaining = UserDefaults.standard.integer(forKey: "fullLongBreakTime")
                                self.ThePomoshTimer.breakTime = UserDefaults.standard.integer(forKey: "fullLongBreakTime")
                            } else {
                                print(UserDefaults.standard.integer(forKey: "fullBreakTime"))
                                self.ThePomoshTimer.timeRemaining = UserDefaults.standard.integer(forKey: "fullBreakTime")
                                self.ThePomoshTimer.breakTime = UserDefaults.standard.integer(forKey: "fullBreakTime")
                            }
                        }
                        self.ThePomoshTimer.runnedRounds += 1
                        self.ThePomoshTimer.round -= 1
                    } else {
                        self.ThePomoshTimer.timeRemaining = UserDefaults.standard.integer(forKey: "time")
                    }
                    generator.impactOccurred()
                } else if self.ThePomoshTimer.timeRemaining == 0 {
                    self.ThePomoshTimer.isActive = false
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    // MARK: - Local Notifications
    
    func scheduleAlarmNotification(sh: TimeInterval) {
        
        let content = UNMutableNotificationContent()
        var bodyString: String {
            var string = ""
            if self.ThePomoshTimer.isBreakActive == true {
                string = "학습을 시작할 시간이에요."
            } else {
                string = "고생했어요, 쉬는시간입니다☕️. "
            }
            return string
        }
        content.title = "🍅 포모도로"
        content.body = bodyString
        content.badge = 1
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: sh, repeats: false)
        let identifier = "localNotification"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        notificationCenter.getNotificationSettings { settings in
            if settings.authorizationStatus == .authorized {
                self.notificationCenter.add(request) { error in
                    if let error = error {
                        print("Error: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    func resetUserDefaults() {
        self.ThePomoshTimer.todayTime = 0
            UserDefaults.standard.synchronize()
        }

    func cancelNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
