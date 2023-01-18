//
//  SettingsView.swift
//  Pomosh
//
//  Created by Steven J. Selcuk on 2.06.2020.
//  Copyright © 2020 Steven J. Selcuk. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var ThePomoshTimer: PomoshTimer
    let generator = UIImpactFeedbackGenerator(style: .heavy)

    init(timer: PomoshTimer) {
        ThePomoshTimer = timer
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("타이머 설정")) {
                    VStack(alignment: .leading, spacing: 20.0) {
                        Spacer()
                        Stepper("집중시간: \(self.ThePomoshTimer.fulltime / 60)분", value: self.$ThePomoshTimer.fulltime, in: 10 ... 3600, step: 300)
                            .foregroundColor(Color("Text"))
                            .font(.custom("Silka Regular", size: 14))

                        Stepper("쉬는 시간: \(self.ThePomoshTimer.fullBreakTime / 60)분", value: self.$ThePomoshTimer.fullBreakTime, in: 300 ... 900, step: 60)
                            .foregroundColor(Color("Text"))
                            .font(.custom("Silka Regular", size: 14))

                        Stepper("긴 휴식시간: \(self.ThePomoshTimer.fullLongBreakTime / 60)분", value: self.$ThePomoshTimer.fullLongBreakTime, in: 300 ... 1800, step: 300)
                            .foregroundColor(Color("Text"))
                            .font(.custom("Silka Regular", size: 14))

                        Stepper("긴 휴식시간은:\n매 \(self.ThePomoshTimer.longBreakRound)라운드 마다", value: self.$ThePomoshTimer.longBreakRound, in: 2 ... 6, step: 1)
                            .foregroundColor(Color("Text"))
                            .font(.custom("Silka Regular", size: 14))

                        VStack(alignment: .leading) {
                            Text("한 세션당 반복 사이클")
                                .foregroundColor(Color("Text"))
                                .font(.custom("Silka Regular", size: 14))
                                .padding(.bottom, 10.0)
                            HStack {
                                ForEach(0 ..< self.ThePomoshTimer.fullround, id: \.self) { _ in
                                    Text("🍅")
                                        .transition(AnyTransition.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .bottom)).combined(with: .opacity))
                                }
                            }
                            Slider(value: Binding(
                                get: {
                                    Double(self.ThePomoshTimer.fullround)

                                },
                                set: { newValue in
                                    if Int(newValue) != self.ThePomoshTimer.fullround {
                                        generator.impactOccurred()
                                        withAnimation(.interpolatingSpring(mass: 1.0,
                                                                           stiffness: 100.0,
                                                                           damping: 10,
                                                                           initialVelocity: 0)) {
                                            settings.set(newValue, forKey: "fullround")
                                            self.ThePomoshTimer.fullround = Int(newValue)
                                        }
                                    }
                                }
                            ), in: 1 ... 12)
                            Spacer()
                        }
                    }
                }
                
                
                Section(header: Text("공부 시간")) {
                    HStack {
                        Text("오늘의 공부시간-> \(self.ThePomoshTimer.textForTimer(time: TimeInterval(self.ThePomoshTimer.todayTime)))")
                            .foregroundColor(Color("Text"))
                            .font(.custom("Silka Regular", size: 14))
                        Spacer()

                    }
                    HStack {
                        Text("총 공부시간-> \(self.ThePomoshTimer.textForTimer(time: TimeInterval(self.ThePomoshTimer.totalTime)))")
                            .foregroundColor(Color("Text"))
                            .font(.custom("Silka Regular", size: 14))
                    }
                }
                Section(header: Text("소리 설정")) {
                    VStack {
                        Toggle(isOn: self.$ThePomoshTimer.playSound) {
                            Text("소리 켜기")
                                .foregroundColor(Color("Text"))
                                .font(.custom("Silka Regular", size: 14))
                        }.padding(.vertical, 5.0)
                    }
                }
            }.navigationBarTitle("환경 설정")
        }
    }

}
