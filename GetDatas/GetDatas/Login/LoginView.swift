import SwiftUI

struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isPasswordVisible: Bool = false
    @State private var showHomeView = false
    @State private var showErrorMessage = false // 에러 메시지 표시 상태
    @State private var showRegisterView = false // RegisterView를 표시하기 위한 상태

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            // 제목 텍스트
            Text("raem")
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(Color.deepNavy)
            
            // 이메일 입력 필드
            VStack(alignment: .leading, spacing: 8) {
                Text("이메일 입력")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                
                TextField("이메일 입력", text: $email)
                    .foregroundColor(.black) // 텍스트 색상 변경
                    .frame(height: 50)
                    .padding(.horizontal, 15)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                    )
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
            }

            // 비밀번호 입력 필드
            VStack(alignment: .leading, spacing: 8) {
                Text("비밀번호 입력")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                
                HStack {
                    if isPasswordVisible {
                        TextField("비밀번호 입력", text: $password)
                            .foregroundColor(.black) // 텍스트 색상 변경
                            .frame(height: 50)
                            .padding(.horizontal, 15)
                    } else {
                        SecureField("비밀번호 입력", text: $password)
                            .foregroundColor(.black) // 텍스트 색상 변경
                            .frame(height: 50)
                            .padding(.horizontal, 15)
                    }

                    Button(action: {
                        isPasswordVisible.toggle()
                    }) {
                        Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 15)
                }
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                )
                
                // 에러 메시지
                if showErrorMessage {
                    Text("비밀번호를 다시 입력해주세요.")
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                        .padding(.top, 4)
                }
            }

            // 비밀번호 찾기 버튼
            HStack {
                Spacer()
                Button(action: {
                    // 비밀번호 찾기 액션 추가
                }) {
                    Text("비밀번호 찾기")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
            }

            // 로그인 버튼
            Button(action: {
                if password.isEmpty || email.isEmpty || password != "expectedPassword" { // 임시 비밀번호 조건
                    showErrorMessage = true
                } else {
                    showErrorMessage = false
                    showHomeView = true
                }
            }) {
                Text("로그인")
                    .font(.system(size: 18, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.deepNavy)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 20)
            .background(
                NavigationLink(destination: HomeView(), isActive: $showHomeView) {
                    EmptyView()
                }
            )

            // 회원가입 링크
            HStack {
                Text("회원이 아니신가요?")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                
                Button(action: {
                    showRegisterView = true
                }) {
                    Text("회원가입 하러가기")
                        .font(.system(size: 14))
                        .foregroundColor(Color.mint)
                }
                .background(
                    NavigationLink(destination: RegisterView(), isActive: $showRegisterView) {
                        EmptyView()
                    }
                )
            }
            .padding(.top, 20)

            Spacer()
        }
        .globalPadding()
        .background(Color.white)
        .edgesIgnoringSafeArea(.all)
        .navigationBarItems(leading: BackButton()) // 커스텀 백 버튼 추가
        .navigationBarBackButtonHidden(true)
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
