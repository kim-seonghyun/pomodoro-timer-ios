import Foundation
import SwiftUI
import Combine
 
class MyTimer: ObservableObject {
    var value: Int = 0
    
    init() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            self.value += 1
            
        }
    }
}
