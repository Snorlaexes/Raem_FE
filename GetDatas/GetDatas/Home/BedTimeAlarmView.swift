import SwiftUI

struct BedTimeAlarmView: View {
    @Binding var selectedTab: Tab
    @StateObject var stageAiPredictionManager = StageAiPredictionManager()

    enum Tab {
        case bedtime
        case alarm
        case none
        case sleepTrack
        case sleepDetail
    }

    var body: some View {
        VStack(spacing: 20) {
            // 상단 Back 버튼 및 탭 선택
            HStack {
                Button(action: {
                    NotificationCenter.default.post(name: Notification.Name("changeHomeView"),
                                                    object: BedTimeAlarmView.Tab.none)
                }) {
                    Image("backbutton")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.black)
                }
                Spacer()
                Text("취침 시간")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(selectedTab == .bedtime ? .black : .gray)
                    .onTapGesture {
                        selectedTab = .bedtime
                    }
                Spacer()
                Text("알람")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(selectedTab == .alarm ? .black : .gray)
                    .onTapGesture {
                        selectedTab = .alarm
                    }
                Spacer()
                // 빈 공간 확보
                Image(systemName: "chevron.left")
                    .foregroundColor(.clear)
                    .font(.system(size: 20, weight: .bold))
            }
            .padding(.horizontal, 16)
            .padding(.top, 70) // 상단에 약간의 여백 추가

            // 선택된 탭에 따라 다른 뷰 표시
            ScrollView {
                if selectedTab == .bedtime {
                    BedtimeView()
                } else {
                    AlarmView(stageAiPredictionManager: stageAiPredictionManager)
                }
            }
            .padding(.horizontal, 16)
        }
        .background(Color.white)
        .navigationBarHidden(true)
    }
}

struct BedtimeView: View {
    @State private var selectedTime = {
        if let savedTime = UserDefaults.standard.object(forKey: "selectedBedTime") as? Date {
            return savedTime
        } else {
            return Date()
        }
    }()
    @State private var receiveAlarm = true
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone.current  // 로컬 시간대 사용
        return formatter
    }()

    var body: some View {
        VStack(spacing: 20) {
            DatePicker("Please enter a date", selection: $selectedTime, displayedComponents: .hourAndMinute)
                .datePickerStyle(WheelDatePickerStyle())
                .labelsHidden()
                .padding(.horizontal, 16)
                .onChange(of: selectedTime) { newValue in
                    UserDefaults.standard.set(newValue, forKey: "selectedBedTime")
                }

            Text("수면 시간 목표는 7시간 30분 입니다.\n취침시간 및 알람시간에 근거함")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)

            Toggle(isOn: $receiveAlarm) {
                Text("취침 시간 알림 받기")
                    .font(.system(size: 16))
                    .foregroundColor(.black)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray.opacity(0.5))
            )
            .padding(.horizontal, 16)
            .toggleStyle(SwitchToggleStyle(tint: Color.mint))
        }
        .padding(.top, 20) // 상단 여백 추가
    }
}

struct AlarmView: View {
    
    @ObservedObject var stageAiPredictionManager: StageAiPredictionManager  // StageAi 관련 인스턴스 생성

    @State private var selectedTime = {
        if let savedTime = UserDefaults.standard.object(forKey: "selectedAlarmTime") as? Date {
            return savedTime
        } else {
            return Date()
        }
    }()
    
    @State private var tempSelectedTime: Date = Date() // 임시 저장 변수
    @State private var tempSelectedWakeup: Int = 30 // 임시 저장 변수
    
    @State private var showingWakeupSheet = false
    @State private var showingRealarmSheet = false
    @State private var selectedWakeup = {
        if let wakeUpTime = UserDefaults.standard.object(forKey: "selectedWakeUp") as? Int {
            return wakeUpTime
        } else {
            return 30
        }
    }()
    @State private var selectedRealarm = {
        if let realarmAfter = UserDefaults.standard.object(forKey: "selectedRealarm") as? String {
            return realarmAfter
        } else {
            return "사용 안 함"
        }
    }()
    @State private var receiveAlarm = true

    var body: some View {
        VStack(spacing: 20) {
            DatePicker("Please enter a date", selection: $tempSelectedTime, displayedComponents: .hourAndMinute)
                .datePickerStyle(WheelDatePickerStyle())
                .labelsHidden()
                .padding(.horizontal, 16)
//                .environment(\.locale, Locale(identifier: "en_GB")) // 24-hour 포멧

            Text("수면 시간 목표는 7시간 30분 입니다.\n취침시간 및 알람시간에 근거함")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)

            VStack(alignment: .center, spacing: 20) {
                HStack {
                    Text("스마트 알람")
                        .font(.system(size: 16))
                        .foregroundColor(.black)
                    Spacer()
                    Toggle("", isOn: $receiveAlarm)
                        .toggleStyle(SwitchToggleStyle(tint: Color.mint))
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.5))
                )
                .padding(.horizontal, 16)

                HStack {
                    Text("기상 시간대")
                        .font(.system(size: 16))
                        .foregroundColor(.black)
                    Spacer()
                    Text("\(tempSelectedWakeup)분")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                    Button(action: {
                        showingWakeupSheet = true
                    }) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                    .confirmationDialog("기상 시간대", isPresented: $showingWakeupSheet) {
                        Button("30분") {
                            tempSelectedWakeup = 30
                        }
                        Button("45분") {
                            tempSelectedWakeup = 45
                        }
                        Button("60분") {
                            tempSelectedWakeup = 60
                        }
                        Button("취소", role: .cancel) {}
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.5))
                )
                .padding(.horizontal, 16)

                HStack {
                    Text("다시 알림")
                        .font(.system(size: 16))
                        .foregroundColor(.black)
                    Spacer()
                    Text(selectedRealarm)
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                    Button(action: {
                        showingRealarmSheet = true
                    }) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                    .confirmationDialog("다시 알림", isPresented: $showingRealarmSheet) {
                        Button("사용 안 함") {
                            selectedRealarm = "사용 안 함"
                            UserDefaults.standard.set("사용 안 함", forKey: "selectedRealarm")
                        }
                        Button("5분 뒤") {
                            selectedRealarm = "5분 뒤"
                            UserDefaults.standard.set("5분 뒤", forKey: "selectedRealarm")
                        }
                        Button("10분 뒤") {
                            selectedRealarm = "10분 뒤"
                            UserDefaults.standard.set("10분 뒤", forKey: "selectedRealarm")
                        }
                        Button("15분 뒤") {
                            selectedRealarm = "15분 뒤"
                            UserDefaults.standard.set("15분 뒤", forKey: "selectedRealarm")
                        }
                        Button("30분 뒤") {
                            selectedRealarm = "30분 뒤"
                            UserDefaults.standard.set("30분 뒤", forKey: "selectedRealarm")
                        }
                        Button("취소", role: .cancel) {}
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.5))
                )
                .padding(.horizontal, 16)
            }
            
            // "완료" 버튼 추가
            Button(action: {
                // "완료" 버튼을 눌렀을 때만 기상 시각과 여분 시간을 저장하고 적용
                UserDefaults.standard.set(tempSelectedTime, forKey: "selectedAlarmTime")
                UserDefaults.standard.set(tempSelectedWakeup, forKey: "selectedWakeUp")
                selectedTime = tempSelectedTime
                selectedWakeup = tempSelectedWakeup
                stageAiPredictionManager.setAlarmTime(alarmTime: selectedTime, wakeUpBufferMinutes: selectedWakeup)
            }) {
                HStack {
                    Spacer()
                    Text("완료")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.mint) // 다른 UI와 맞추기 위해 스타일 통일
                )
            }
            .padding(.horizontal, 16)
            .padding(.top, 10) // 완료 버튼을 위로 올려서 화면에 잘 보이도록 조정
        }
        .padding(.top, 20) // 상단 여백 추가
    }
}

struct BedTimeAlarmView_Previews: PreviewProvider {
    static var previews: some View {
        BedTimeAlarmView(selectedTab: .constant(.bedtime))
    }
}
