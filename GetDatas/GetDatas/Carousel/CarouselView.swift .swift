import SwiftUI

struct CarouselView: View {
    @State private var currentIndex = 0
    @State private var showLoginView = false
    @State private var showRegisterView = false
    
    // 우측 하단 버튼에 필요
    @State private var showRecordView = false
    @State private var showFloatingButtons = false
    
    
    let pages: [CarouselPage] = [
        CarouselPage(imageName: "page1", title: "편안한 수면", description: "숙면을 위한 완벽한 환경을 제공합니다."),
        CarouselPage(imageName: "page2", title: "스마트 수면 분석", description: "AI가 당신의 수면 패턴을 분석해 드립니다."),
        CarouselPage(imageName: "page3", title: "건강한 수면 관리", description: "당신의 수면 건강을 최우선으로 생각합니다.")
    ]
    
    
    var body: some View {
        
        NavigationView {
            ZStack {
                VStack {
                    GeometryReader { geometry in
                        TabView(selection: $currentIndex) {
                            ForEach(pages.indices, id: \.self) { index in
                                VStack(spacing: 20) {
                                    Spacer()
                                    
                                    Text(pages[index].title)
                                        .font(.system(size: 24, weight: .bold))
                                    
                                    Image(pages[index].imageName)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 200)
                                    
                                    Text(pages[index].description)
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                        .multilineTextAlignment(.center)
                    
                                    
                                    // 마지막 슬라이드에 로그인과 회원가입 버튼 추가
                                    if index == pages.count - 1 {
                                        VStack(spacing: 16) {
                                            Button(action: {
                                                showLoginView = true
                                            }) {
                                                Text("로그인")
                                                    .font(.system(size: 18, weight: .bold))
                                                    .frame(maxWidth: .infinity)
                                                    .frame(height: 50)
                                                    .background(Color.deepNavy)
                                                    .foregroundColor(.white)
                                                    .cornerRadius(10)
                                            }
                                            
                                            Button(action: {
                                                showRegisterView = true
                                            }) {
                                                Text("회원가입")
                                                    .frame(maxWidth: .infinity)
                                                    .frame(height: 50)
                                                    .background(Color.white)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 10)
                                                            .stroke(Color.deepNavy, lineWidth: 2)
                                                    )
                                                    .foregroundColor(.deepNavy)
                                            }
                                        }
                                        .padding(.horizontal)
                                        .padding(.top, 30)
                                    }else{
                                        Spacer()
                                    }
                                }
                                .tag(index)
                            }
                        }
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                        .frame(height: geometry.size.height * 0.8)
                    }
                }
                
                VStack {
                    Spacer()
                    
                    // 페이지네이션 추가
                    HStack(spacing: 8) {
                        ForEach(pages.indices, id: \.self) { pageIndex in
                            Circle()
                                .fill(pageIndex == currentIndex ? Color.deepNavy : Color.gray.opacity(0.5))
                                .frame(width: 8, height: 8)
                        }
                    }
                    .padding(.bottom, 80)
                }
                
                // 오른쪽 아래의 원형 버튼 추가
                ZStack {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: {
                                withAnimation {
                                    showFloatingButtons.toggle()
                                }
                            }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 24))
                                    .frame(width: 60, height: 60)
                                    .foregroundColor(.white)
                                    .background(Color.deepNavy)
                                    .cornerRadius(30)
                                    .shadow(radius: 10)
                            }
                            .padding()
                        }
                    }
                    
                    // 플로팅 버튼들
                    if showFloatingButtons {
                        VStack {
                           Spacer()
                           HStack {
                               Spacer()
                               VStack(alignment: .trailing) {
                                   NavigationLink(destination: RecordView()) {
                                       Text("실시간 데이터")
                                           .font(.system(size: 18))
                                           .foregroundColor(.white)
                                           .padding()
                                           .background(Color.gray)
                                           .cornerRadius(10)
                                           .shadow(radius: 5)
                                   }
                                   .padding(.bottom, 0)
                                   
                                   NavigationLink(destination: SleepDataView()) {
                                       Text("수면 데이터")
                                           .font(.system(size: 18))
                                           .foregroundColor(.white)
                                           .padding()
                                           .background(Color.gray)
                                           .cornerRadius(10)
                                           .shadow(radius: 5)
                                   }
                               }
                               .padding(.trailing, 20)
                           }
                           .padding(.bottom, 100)
                       }
                       .transition(.opacity)
                    }
                }
            }
            .background(Color.white)
            .edgesIgnoringSafeArea(.all)
            .navigationBarHidden(true)
            .navigationBarBackButtonHidden(true)
            .background(
                NavigationLink(destination: LoginView(), isActive: $showLoginView) {
                    EmptyView()
                }
            )
            .background(
                NavigationLink(destination: RegisterView(), isActive: $showRegisterView) {
                    EmptyView()
                }
            )
        }
    }
}

struct CarouselPage {
    let imageName: String
    let title: String
    let description: String
}

struct CarouselView_Previews: PreviewProvider {
    static var previews: some View {
        CarouselView()
    }
}
