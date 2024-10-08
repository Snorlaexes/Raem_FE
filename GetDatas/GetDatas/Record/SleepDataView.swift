import SwiftUI
import HealthKit

enum DisplayState {
    case allData
    case timeSorted
    case levelSorted
}

enum SleepStage {
    case rem
    case core
    case deep
}

struct SleepDataView: View {
    @EnvironmentObject var sessionManager: SessionManager // 이메일 사용을 위한 SessionManager
    @EnvironmentObject var bleManager: BLEManager
    @StateObject private var predictionManager: DreamAiPredictionManager
    
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var temporaryStartDate = Date()
    @State private var temporaryEndDate = Date()
    @State private var isStartDatePickerPresented = false
    @State private var isEndDatePickerPresented = false
    @State private var isSortedByLevel = false
    @State private var sleepData: [HKSleepAnalysis] = []
    @State private var displayState: DisplayState = .allData

    private let healthStore = HKHealthStore()
    
    init() {
        _predictionManager = StateObject(wrappedValue: DreamAiPredictionManager(bleManager: BLEManager()))
    }
    
    var body: some View {
        VStack {
            // 상단 타이틀 및 뒤로가기 버튼
            CustomTopBar(title: "수면 데이터")

            HStack {
                VStack(alignment: .leading) {
                    Text("시작 날짜")
                    Button(action: {
                        temporaryStartDate = startDate
                        isStartDatePickerPresented.toggle()
                    }) {
                        HStack {
                            Text("\(formatDateInput(startDate))")
                            Spacer()
                            Image(systemName: "calendar")
                        }
                        .padding()
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                    }
                    .sheet(isPresented: $isStartDatePickerPresented) {
                        VStack {
                            DatePicker(
                                "시작 날짜",
                                selection: $temporaryStartDate,
                                displayedComponents: [.date]
                            )
                            .datePickerStyle(WheelDatePickerStyle())
                            .labelsHidden()
                            .environment(\.locale, Locale(identifier: "ko_KR"))
                            .padding()
                            
                            Button("확인") {
                                startDate = temporaryStartDate
                                isStartDatePickerPresented = false
                            }
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                }
                VStack(alignment: .leading) {
                    Text("끝 날짜")
                    Button(action: {
                        temporaryEndDate = endDate
                        isEndDatePickerPresented.toggle()
                    }) {
                        HStack {
                            Text("\(formatDateInput(endDate))")
                            Spacer()
                            Image(systemName: "calendar")
                        }
                        .padding()
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                    }
                    .sheet(isPresented: $isEndDatePickerPresented) {
                        VStack {
                            DatePicker(
                                "끝 날짜",
                                selection: $temporaryEndDate,
                                displayedComponents: [.date]
                            )
                            .datePickerStyle(WheelDatePickerStyle())
                            .labelsHidden()
                            .environment(\.locale, Locale(identifier: "ko_KR"))
                            .padding()
                            
                            Button("확인") {
                                endDate = temporaryEndDate
                                isEndDatePickerPresented = false
                            }
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                }
            }
            .padding()
            
            HStack {
                Button(action: {
                    loadSleepData()
                    displayState = .allData
                }) {
                    Text("수면 데이터 불러오기")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()

                Button(action: saveDataToServer) {
                    Text("json")
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.blue)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.blue, lineWidth: 2)
                        )
                }
                .padding()
            }
            
            HStack {
                Button(action: {
                    sortByTime()
                    displayState = .timeSorted
                }) {
                    Text("시간순 정렬")
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                Button(action: {
                    sortByLevel()
                    displayState = .levelSorted
                }) {
                    Text("수면단계 정렬")
                        .padding()
                        .background(Color.pink)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                Button(action: exportDataToCSV) {
                    Text("CSV")
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal)
            .frame(maxWidth: .infinity)
            
            List {
                if displayState == .levelSorted {
                    let filteredData = sleepData.filter { $0.level != 2 } // 'Awake' 제거
                    let groupedData = groupAndAggregateSleepData(filteredData)
                    ForEach(groupedData.keys.sorted(), id: \.self) { level in
                        let data = groupedData[level]!
                        VStack(alignment: .leading) {
                            Text("\(data.levelDescription) (\(level))")
                            Text("interval: \(data.count)회")
                            Text("total time: \(formatDuration(data.totalTime))")
                        }
                    }
                } else {
                    let filteredData = sleepData.filter { $0.level != 0 || displayState == .allData } // 'In Bed' 제거 조건 추가
                    ForEach(filteredData) { sleep in
                        VStack(alignment: .leading) {
                            Text("start: \(formatFullDate(sleep.startDate))")
                            Text("end  : \(formatFullDate(sleep.endDate))")
                            Text("level: \(sleep.levelDescription) (\(sleep.level))")
                        }
                    }
                }
            }
        }
        .onAppear {
           requestHealthAuthorization()
       }
        .background(Color.black)
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
    }
    
    func calculateTotalSleepTime(for sleepStage: SleepStage) -> TimeInterval {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss" // `timestamp`의 포맷과 동일하게 설정

        var totalTime: TimeInterval = 0
        var previousDate: Date?

        for result in predictionManager.predictionResults {
            let isMatchingStage: Bool
            switch sleepStage {
            case .rem:
                isMatchingStage = result.isSleeping && result.probability > 0.8
            case .core:
                isMatchingStage = result.isSleeping && result.probability > 0.5
            case .deep:
                isMatchingStage = result.isSleeping && result.probability > 0.9
            }

            // `timestamp`를 `Date`로 변환
            if let currentDate = dateFormatter.date(from: result.timestamp), isMatchingStage {
                if let previousDate = previousDate {
                    // 두 시간의 차이를 더해줌
                    totalTime += currentDate.timeIntervalSince(previousDate)
                }
                // 이전 날짜를 현재 날짜로 업데이트
                previousDate = currentDate
            }
        }

        return totalTime
    }
    func saveDataToServer() {
        let isoDateFormatter = ISO8601DateFormatter()
        isoDateFormatter.formatOptions = [.withInternetDateTime] // ISO 8601 형식
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm" // 시, 분 형식
        let durationFormatter = DateFormatter()
        durationFormatter.dateFormat = "HH:mm:ss" // 시, 분, 초 형식
        
        // 현재 날짜와 시간을 가져와서 대체할 sleptAt 기본값으로 사용
        let sleptAt = Date() // 현재 시간을 Date 타입으로 사용

        // DreamAiPredictionManager에서 예측된 데이터 가져오기
        let fellAsleepAtString = predictionManager.predictionResults.first(where: { $0.isSleeping })?.timestamp ?? "22:00"
        let awakeAtString = predictionManager.predictionResults.last(where: { $0.isSleeping })?.timestamp ?? "08:00"
        
        // 문자열을 Date로 변환
        guard let fellAsleepAt = timeFormatter.date(from: fellAsleepAtString),
              let awakeAt = timeFormatter.date(from: awakeAtString) else {
            print("시간 변환 오류")
            return
        }

        // 총 REM 수면 시간 계산 (데이터 없을 시 7시간 7분 7초로 대체)
        let remSleepTime: Date
        if predictionManager.predictionResults.isEmpty {
            remSleepTime = durationFormatter.date(from: "07:07:07")!
        } else {
            remSleepTime = Date(timeIntervalSince1970: calculateTotalSleepTime(for: .rem))
        }

        // 총 수면 시간 계산 (REM + Core + Deep), 데이터 없을 시 10시간으로 대체
        let totalSleepTime: Date
        if predictionManager.predictionResults.isEmpty {
            totalSleepTime = durationFormatter.date(from: "10:00:00")!
        } else {
            let totalSleepDuration = calculateTotalSleepTime(for: .core) + calculateTotalSleepTime(for: .deep) + calculateTotalSleepTime(for: .rem)
            totalSleepTime = Date(timeIntervalSince1970: totalSleepDuration)
        }
        
        // 서버로 보낼 요청 본문 (Date -> String으로 변환)
        let requestBody: [String: Any] = [
            "sleptAt": isoDateFormatter.string(from: sleptAt), // Date -> String 변환
            "score": 3, // 고정값 3
            "fellAsleepAt": timeFormatter.string(from: fellAsleepAt), // Date -> String 변환
            "awakeAt": timeFormatter.string(from: awakeAt), // Date -> String 변환
            "rem": durationFormatter.string(from: remSleepTime), // Date -> String 변환
            "sleepTime": durationFormatter.string(from: totalSleepTime) // Date -> String 변환
        ]
        
        // 요청 본문 로그로 출력
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody, options: .prettyPrinted)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("Request Body: \(jsonString)")
            }
        } catch {
            print("Error serializing JSON: \(error)")
        }
        
        // 서버로 데이터 전송
        guard let url = URL(string: "https://www.raem.shop/api/sleep/data?type=json") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // SessionManager에서 accessToken을 가져오기
        if let accessToken = sessionManager.accessToken {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization") // Authorization 헤더 추가
        } else {
            print("Access Token이 없습니다.")
            return
        }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error sending data to server: \(error)")
                    showAlert(title: "Error", message: "데이터 전송 실패")
                    return
                }

                if let httpResponse = response as? HTTPURLResponse {
                    print("HTTP Response Status Code: \(httpResponse.statusCode)")
                }

                // 응답 데이터 확인 (서버 오류 메시지 확인 가능)
                if let data = data {
                    do {
                        if let responseData = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                           let success = responseData["isSuccess"] as? Bool, success == true {
                            print("성공적으로 저장되었습니다.")
                        } else {
                            print("응답 데이터가 예상한 형식이 아닙니다.")
                        }
                    } catch {
                        print("응답 데이터 처리 중 오류 발생: \(error)")
                    }
                }
            }
            
            task.resume()
        } catch {
            print("Error serializing JSON: \(error)")
            showAlert(title: "Error", message: "데이터 직렬화 실패")
        }
    }



    func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "확인", style: .default))
            
            // 현재 활성화된 윈도우 씬을 가져옵니다.
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                rootViewController.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func exportDataToCSV() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let formattedEndDate = dateFormatter.string(from: endDate)
        
        // 사용자 이메일 또는 기본 사용자 이름 결정
        let userEmailOrDefaultName = sessionManager.isLoggedIn ? sessionManager.email : "사용자"
        
        // Documents 디렉토리로 파일 저장 위치 변경
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileName = "\(userEmailOrDefaultName)(\(formattedEndDate)).csv"
        let path = documentsDirectory.appendingPathComponent(fileName)
        
        var csvText = "start,end,level,level(Int)\n"
        
        let filteredData: [HKSleepAnalysis]
        switch displayState {
        case .allData:
            filteredData = sleepData
        case .timeSorted:
            filteredData = sleepData.filter { $0.level != 0 }
        case .levelSorted:
            filteredData = sleepData.filter { $0.level != 2 }
            csvText = "level,interval,total time\n"
        }
        
        if displayState == .levelSorted {
            let groupedData = groupAndAggregateSleepData(filteredData)
            for level in groupedData.keys.sorted() {
                let data = groupedData[level]!
                let newLine = "\(data.levelDescription),\(data.count)회,\(formatDuration(data.totalTime))\n"
                csvText.append(contentsOf: newLine)
            }
        } else {
            for sleep in filteredData.sorted(by: { $0.startDate < $1.startDate }) {
                let newLine = "\(formatFullDate(sleep.startDate)),\(formatFullDate(sleep.endDate)),\(sleep.levelDescription),\(sleep.level)\n"
                csvText.append(contentsOf: newLine)
            }
        }
        
        do {
            try csvText.write(to: path, atomically: true, encoding: .utf8)
            print("CSV 파일 생성 성공: \(path.path)")
            shareCSV(path: path)
        } catch {
            print("CSV 파일 생성 실패: \(error)")
        }
    }

    func shareCSV(path: URL) {
        let activityViewController = UIActivityViewController(activityItems: [path], applicationActivities: nil)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            
            if let presentedVC = rootViewController.presentedViewController {
                // 이미 다른 뷰가 표시 중이면 닫고 새로 표시
                presentedVC.dismiss(animated: false) {
                    rootViewController.present(activityViewController, animated: true, completion: nil)
                }
            } else {
                rootViewController.present(activityViewController, animated: true, completion: nil)
            }
        }
    }


    private func formatDateInput(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    private func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    private func requestHealthAuthorization() {
        if HKHealthStore.isHealthDataAvailable() {
            let typesToShare: Set<HKSampleType> = []
            let typesToRead: Set<HKObjectType> = [
                HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
            ]
            
            healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
                if !success {
                    // Handle error.
                }
            }
        }
    }
    
    private func loadSleepData() {
        guard #available(iOS 16.0, *) else {
            showUnsupportedVersionAlert()
            return
        }
        
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, results, error) in
            guard let results = results as? [HKCategorySample], error == nil else {
                return
            }
            
            DispatchQueue.main.async {
                sleepData = results.map { sample in
                    let sleepLevel = HKSleepAnalysis(sample: sample)
                    return sleepLevel
                }
                isSortedByLevel = false
            }
        }
        
        healthStore.execute(query)
    }
    
    private func showUnsupportedVersionAlert() {
        let alert = UIAlertController(title: "지원하지 않는 버전", message: "이 기능은 iOS 16 이상에서만 사용할 수 있습니다.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        
        // 현재 활성화된 윈도우 씬을 가져옵니다.
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(alert, animated: true, completion: nil)
        }
    }

    
    private func sortByTime() {
        sleepData.sort { $0.startDate < $1.startDate }
        isSortedByLevel = false
    }
    
    private func sortByLevel() {
        isSortedByLevel = true
    }
    
    private func groupAndAggregateSleepData(_ data: [HKSleepAnalysis]) -> [Int: (count: Int, totalTime: TimeInterval, levelDescription: String)] {
        var result = [Int: (count: Int, totalTime: TimeInterval, levelDescription: String)]()
        
        for item in data {
            if result[item.level] == nil {
                result[item.level] = (count: 0, totalTime: 0, levelDescription: item.levelDescription)
            }
            result[item.level]!.count += 1
            result[item.level]!.totalTime += item.endDate.timeIntervalSince(item.startDate)
        }
        
        return result
    }
}

struct HKSleepAnalysis: Identifiable, Hashable {
    var id = UUID()
    var startDate: Date
    var endDate: Date
    var level: Int
    
    var levelDescription: String {
        switch level {
        case 0: return "In Bed"
        case 1: return "Unspecified"
        case 2: return "Awake"
        case 3: return "Core"
        case 4: return "Deep"
        case 5: return "Rem"
        default: return "Unknown"
        }
    }
    
    init(sample: HKCategorySample) {
        self.startDate = sample.startDate
        self.endDate = sample.endDate
        self.level = sample.value
    }
}

struct SleepDataView_Previews: PreviewProvider {
    static var previews: some View {
        SleepDataView()
            .environmentObject(SessionManager())
    }
}
