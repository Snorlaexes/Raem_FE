import SwiftUI

struct RegisterView: View {
    @State private var nickname: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var isRegistered = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // 제목 텍스트
            Text(attributedTitle)
                .font(.system(size: 24, weight: .bold))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            // 닉네임 입력 필드
            VStack(alignment: .leading, spacing: 8) {
                TextField("사용하실 닉네임 입력", text: $nickname)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                    )
            }
            .padding(.horizontal, 24)

            // 이메일 입력 필드
            VStack(alignment: .leading, spacing: 8) {
                TextField("이메일 주소 입력", text: $email)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                    )
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
            }
            .padding(.horizontal, 24)

            // 비밀번호 입력 필드
            VStack(alignment: .leading, spacing: 8) {
                SecureField("비밀번호 입력", text: $password)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                    )
            }
            .padding(.horizontal, 24)

            // 비밀번호 확인 입력 필드
            VStack(alignment: .leading, spacing: 8) {
                SecureField("비밀번호 확인", text: $confirmPassword)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                    )
            }
            .padding(.horizontal, 24)

            // 회원가입 버튼
            Button(action: {
                isRegistered = true
            }) {
                Text("회원가입")
                    .font(.system(size: 18, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.deepNavy)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .background(
                NavigationLink(destination: RegisterCompleteView(), isActive: $isRegistered) {
                    EmptyView()
                }
            )

            Spacer()
        }
        .background(Color.white)
        .edgesIgnoringSafeArea(.all)
    }
    
    private var attributedTitle: AttributedString {
        var attributedString = AttributedString("raem 가입을 환영합니다.")
        if let range = attributedString.range(of: "raem") {
            attributedString[range].foregroundColor = Color.deepNavy
        }
        return attributedString
    }
}

struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterView()
    }
}

