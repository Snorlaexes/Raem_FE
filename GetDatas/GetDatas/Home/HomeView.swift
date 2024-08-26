import SwiftUI

struct HomeView: View {
    @State private var showSleepTrackingView = false  // SleepTrackingView로 이동하기 위한 상태
    @State private var showAccountManagementView = false  // AccountManagementView로 이동하기 위한 상태
    
    var body: some View {
        ZStack {
            VStack(spacing: 16) {
                TopNav()

                // 환영 메시지
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
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
                                    .foregroundColor(Color.home_mint)
                            }
                        }
                    }
                    .padding(.horizontal, 23) // 좌우 여백 추가
                    .padding(.vertical, 20)

                    // 최근 수면 정보 카드
                    VStack(alignment: .leading) {
                        HStack {
                            Text("최근 수면 정보")
                                .font(Font.system(size: 15, weight: .bold))
                                .foregroundColor(.black)
                            Spacer()
                            Button(action: {
                                // 분석 보기 액션 추가
                            }) {
                                Text("분석 보기")
                                    .font(Font.system(size: 15))
                                    .foregroundColor(Color.deepNavy)
                            }
                        }
                        .padding(.horizontal, 20) // 카드 내부의 좌우 여백
                        .padding(.top, 18)

                        HStack(spacing: 45) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 16) {
                                    Image("moon")
                                        .resizable()
                                        .frame(width: 24, height: 24)
                                    VStack(alignment: .leading, spacing: 4){
                                        Text("6시간 52분")
                                            .font(Font.system(size: 18, weight: .bold))
                                            .foregroundColor(.black)
                                        Text("Time in sleep")
                                            .font(Font.system(size: 12))
                                            .foregroundColor(.gray)
                                    }
                                }
                            }

                            VStack(spacing: 4) {
                                HStack(spacing: 16) {
                                    Image("zzz")
                                        .resizable()
                                        .frame(width: 24, height: 24)
                                    VStack(alignment: .leading, spacing: 4){
                                        Text("25분")
                                            .font(Font.system(size: 18, weight: .bold))
                                            .foregroundColor(.black)
                                        Text("Fell asleep")
                                            .font(Font.system(size: 12))
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20) // 카드 내부의 좌우 여백
                        .padding(.top, 20)
                        
                        HStack(spacing: 45) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 16) {
                                    Image("watch")
                                        .resizable()
                                        .frame(width: 24, height: 24)
                                    VStack(alignment: .leading, spacing:4) {
                                        Text("7시간 23분")
                                            .font(Font.system(size: 18, weight: .bold))
                                            .foregroundColor(.black)
                                        Text("Went to bed")
                                            .font(Font.system(size: 12))
                                            .foregroundColor(.gray)
                                    }
                                }
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 16) {
                                    Image("sun")
                                        .resizable()
                                        .frame(width: 24, height: 24)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("07시 12분")
                                            .font(Font.system(size: 18, weight: .bold))
                                            .foregroundColor(.black)
                                        Text("Wake up time")
                                            .font(Font.system(size: 12))
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20) // 카드 내부의 좌우 여백
                        .padding(.top, 25)
                        .padding(.bottom, 18)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.1)) // 연한 회색 배경
                    )
                    .padding(.horizontal, 22) // 카드 바깥의 좌우 여백
                    .padding(.bottom, 20)

                    // 취침 시간 및 알람 카드
                    HStack(spacing: 20){
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
                                .font(Font.system(size: 16, weight: .bold))
                                .foregroundColor(.black)
                            Text("12:20 AM")
                                .font(Font.system(size: 12))
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
                                .font(Font.system(size: 16, weight: .bold))
                                .foregroundColor(.black)
                            Text("08:30 AM - 09:00 AM")
                                .font(Font.system(size: 12))
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
                    .padding(.horizontal, 22) // 카드 바깥의 좌우 여백

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
                }
            }
            .background(Color.white)
            .edgesIgnoringSafeArea(.all)
            .navigationBarHidden(true)
            .background(
                NavigationLink(destination: AccountManagementView(), isActive: $showAccountManagementView) {
                    EmptyView()
                }
            )
            
            

            // WatchButton을 최상위 레이어에 추가
            WatchButton()
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
