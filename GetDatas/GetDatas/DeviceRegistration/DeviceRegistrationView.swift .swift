import SwiftUI

struct DeviceRegistrationView: View {
    @EnvironmentObject var bleManager: BLEManager
    @State private var showMainView = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 8) {
                Spacer()
                // 환영 메시지
                VStack(alignment: .center, spacing: 8) {
                    Text("잠만보님, 안녕하세요!")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity, alignment: .center) // 가운데 정렬
                        .padding(.bottom, 10)
                    
                    Text("등록된 기기가 없습니다.\n지금 바로 raem을 등록하고 시작해보세요.")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center) // 가운데 정렬
                }
                
                // 전구 이미지
                Image("light")
                    .resizable()
                    .scaledToFit()
                    .frame(height: geometry.size.height * 0.3)  // 화면 높이에 비례하여 이미지 크기 조정
                    .padding(.bottom, 120)
                
                // 등록하기 버튼
                Button(action: {
                    // 기기 등록하기 버튼 액션 추가
                    //bleManager.connectDevice()
                    showMainView = true
                }) {
                    Text("등록하기")
                        .font(.system(size: 18, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.deepNavy)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.bottom, geometry.size.height * 0.05)  // 하단에 간격 추가
                .padding(24)
//                .alert(isPresented: Binding<Bool>(
//                    get: { bleManager.connectSuccess != nil },
//                    set: { _ in 
//                        if bleManager.connectSuccess == true {
//                            showMainView = true
//                        }
//                        bleManager.connectSuccess = nil }
//                )) {
//                    Alert(
//                        title: Text(bleManager.connectSuccess == true ? "연결 성공" : "연결 실패"),
//                        message: Text(bleManager.connectSuccess == true ? "Raem과의 연결에 성공했습니다." : "Raem과의 연결에 실패했습니다."),
//                        dismissButton: .default(Text("확인"))
//                    )
//                }
                .background(
                    NavigationLink(destination: MainContentView(), isActive: $showMainView){
                        EmptyView()
                    }
                )
                
                Spacer() // 하단 여백 확보
            }
            .background(Color.white)
            .edgesIgnoringSafeArea(.all)
            .navigationBarHidden(true)
            .navigationBarItems(leading: BackButton()) // 커스텀 백 버튼 추가
            .navigationBarBackButtonHidden(true)
            
        }
    }
}

struct DeviceRegistrationView_Previews: PreviewProvider {
    static var previews: some View {
        DeviceRegistrationView()
    }
}

