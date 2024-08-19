import SwiftUI

struct ContentView: View {
    @ObservedObject var items = Items()
    
    var body: some View {
        VStack {
            // 측정 시작 버튼
            Button(action: {
                items.startMeasuring()
            }) {
                Text("측정 시작")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(items.isMeasuring ? Color.gray : Color.green)
                    .cornerRadius(10)
            }
            .disabled(items.isMeasuring)
            .padding(.bottom, 10)
            
            // 측정 중지 버튼
            Button(action: {
                items.stopMeasuring()
            }) {
                Text("측정 중지")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(items.isMeasuring ? Color.red : Color.gray)
                    .cornerRadius(10)
            }
            .disabled(!items.isMeasuring)
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
