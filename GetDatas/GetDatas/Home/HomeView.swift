import SwiftUI

struct HomeView: View {
    @State private var selectedTab: Tab = .home
    @State private var showSleepTrackingView = false  // SleepTrackingView로 이동하기 위한 상태
    @State private var showAccountManagementView = false  // AccountManagementView로 이동하기 위한 상태

    var body: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 50)
            TopNav()
            
            // 환영 메시지
            VStack(alignment: .leading, spacing: 4) {
                Text("잠만보님, 안녕하세요!")
                    .font(Font.system(size: 20, weight: .bold))
                    .foregroundColor(.black)

                HStack {
                    Text("잠만보님의 최적 수면 시간은 7시간 입니다.")
                        .font(Font.system(size: 14))
                        .foregroundColor(.gray)
                    Spacer()
                    Button(action: {
                        // 더보기 액션 추가
                    }) {
                        Text("더보기")
                            .font(Font.system(size: 14))
                            .foregroundColor(Color.mint)
                    }
                }
            }
            .padding(.horizontal, 16) // 좌우 여백 추가

            // 최근 수면 정보 카드
            VStack(spacing: 12) {
                HStack {
                    Text("최근 수면 정보")
                        .font(Font.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                    Spacer()
                    Button(action: {
                        // 분석 보기 액션 추가
                    }) {
                        Text("분석 보기")
                            .font(Font.system(size: 14))
                            .foregroundColor(Color.mint)
                    }
                }
                .padding(.horizontal, 16) // 카드 내부의 좌우 여백

                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image("moon")
                                .resizable()
                                .frame(width: 24, height: 24)
                            Spacer() // 간격 조정
                            Text("6시간 52분")
                                .font(Font.system(size: 18, weight: .bold))
                                .foregroundColor(.black)
                        }
                        Text("Time in sleep")
                            .font(Font.system(size: 12))
                            .foregroundColor(.gray)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image("zzz")
                                .resizable()
                                .frame(width: 24, height: 24)
                            Spacer() // 간격 조정
                            Text("25분")
                                .font(Font.system(size: 18, weight: .bold))
                                .foregroundColor(.black)
                        }
                        Text("Fell asleep")
                            .font(Font.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 16) // 카드 내부의 좌우 여백

                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image("watch")
                                .resizable()
                                .frame(width: 24, height: 24)
                            Spacer() // 간격 조정
                            Text("7시간 23분")
                                .font(Font.system(size: 18, weight: .bold))
                                .foregroundColor(.black)
                        }
                        Text("Went to bed")
                            .font(Font.system(size: 12))
                            .foregroundColor(.gray)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image("sun")
                                .resizable()
                                .frame(width: 24, height: 24)
                            Spacer() // 간격 조정
                            Text("07시 12분")
                                .font(Font.system(size: 18, weight: .bold))
                                .foregroundColor(.black)
                        }
                        Text("Wake up time")
                            .font(Font.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 16) // 카드 내부의 좌우 여백
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.1)) // 연한 회색 배경
            )
            .padding(.horizontal, 16) // 카드 바깥의 좌우 여백

            // 취침 시간 및 알람 카드
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image("bed")
                            .resizable()
                            .frame(width: 24, height: 24)
                        Spacer()
                        Image(systemName: "ellipsis")
                            .foregroundColor(.gray)
                    }
                    Text("취침 시간")
                        .font(Font.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                    Text("12:20 AM")
                        .font(Font.system(size: 14))
                        .foregroundColor(.gray)
                    Toggle(isOn: .constant(true)) {
                        Text("")
                    }
                    .toggleStyle(SwitchToggleStyle(tint: Color.mint))
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.1)) // 연한 회색 배경
                )

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image("alert")
                            .resizable()
                            .frame(width: 24, height: 24)
                        Spacer()
                        Image(systemName: "ellipsis")
                            .foregroundColor(.gray)
                    }
                    Text("알람")
                        .font(Font.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                    Text("08:30 AM - 09:00 AM")
                        .font(Font.system(size: 14))
                        .foregroundColor(.gray)
                    Toggle(isOn: .constant(false)) {
                        Text("")
                    }
                    .toggleStyle(SwitchToggleStyle(tint: Color.mint))
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.1)) // 연한 회색 배경
                )
            }
            .padding(.horizontal, 16) // 카드 바깥의 좌우 여백

            Spacer()

            // 지금 취침하기 버튼
            Button(action: {
                showSleepTrackingView = true  // SleepTrackingView로 이동
            }) {
                Text("지금 취침하기")
                    .font(Font.system(size: 18, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.deepNavy)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
            .background(
                NavigationLink(destination: SleepTrackingView(), isActive: $showSleepTrackingView) {
                    EmptyView()
                }
            )
            
            // Custom TabBar
            CustomTabBar(selectedTab: $selectedTab)
        }
        .background(Color.white)
        .edgesIgnoringSafeArea(.all)
        .navigationBarHidden(true)
        .background(
            NavigationLink(destination: AccountManagementView(), isActive: $showAccountManagementView) {
                EmptyView()
            }
        )
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}

