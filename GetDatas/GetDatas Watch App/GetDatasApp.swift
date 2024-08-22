import SwiftUI

struct ContentView: View {
    @ObservedObject var dataManager = DataManager()
    
    var body: some View {
        VStack {
            if dataManager.isMeasuring {
                Button("측정 중지") {
                    dataManager.stopMeasuring()
                }
            } else {
                Button("측정 시작") {
                    dataManager.startMeasuring()
                }
            }
            
            if dataManager.isSendComplete {
                Text("\(dataManager.sentDataCount)개의 데이터 전송 완료")
                    .font(.headline)
                    .padding(.top, 10)
            }
        }
        .padding()
    }
}

@main
struct WatchApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
