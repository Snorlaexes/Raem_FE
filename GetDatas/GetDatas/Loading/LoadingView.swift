import SwiftUI

struct LoadingView: View {
    @State private var isActive = false
    @State private var isLoading = true
    @State private var isLoggedIn = false

    @EnvironmentObject var sessionManager: SessionManager

    var body: some View {
        VStack {
            if isActive {
                if isLoggedIn {
                    // 로그인 상태라면 MainContentView로 이동
                    MainContentView()
                } else {
                    // 로그인 상태가 아니라면 CarouselView로 이동
                    CarouselView(isLoggedIn: .constant(false))
                }
            } else {
                VStack {
                    Spacer()
                    Text("raem")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.deepNavy)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white)
                .edgesIgnoringSafeArea(.all)
                .onAppear {
                    loadData()
                }
            }
        }
        .background(Color.white)
        .edgesIgnoringSafeArea(.all)
        .navigationBarBackButtonHidden(true)
    }

    // 데이터 로딩 함수 (비동기 처리)
    func loadData() {
        DispatchQueue.global().async {
            // 실제 데이터 로딩 작업을 이곳에 작성 (API 호출, 데이터베이스 읽기 등)
            sleep(2) // 가상 데이터 로딩 시간 (2초)
            
            DispatchQueue.main.async {
                // 로그인 상태를 판단하여 결정
                if let token = UserDefaults.standard.string(forKey: "accessToken") {
                    self.isLoggedIn = true // accessToken이 있으면 로그인 상태로 설정
                    sessionManager.saveAccessToken(token: token) // SessionManager에 토큰 저장 및 회원 정보 로드
                } else {
                    self.isLoggedIn = false // accessToken이 없으면 로그아웃 상태로 설정
                }
                self.isActive = true // 로딩이 완료되면 화면 전환
            }
        }
    }
}

struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingView()
            .environmentObject(SessionManager())
    }
}
