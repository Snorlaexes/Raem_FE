import SwiftUI
import HealthKit

struct SleepDataView: View {
    @State private var sleepData: [HKCategorySample] = []
    @State private var displayData: [(level: String, count: Int, duration: TimeInterval)] = []
    @State private var startDate = Date()
    @State private var endDate = Date()
    
    @State private var isStartDatePickerPresented = false
    @State private var isEndDatePickerPresented = false
    
    @State private var temporaryStartDate = Date()
    @State private var temporaryEndDate = Date()
    
    private let healthStore = HKHealthStore()

    var body: some View {
        VStack {
            VStack {
                Button("수면 데이터 불러오기") {
                    requestHealthKitAuthorization()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)

                HStack {
                    Button("시간순 정렬") {
                        displayData = aggregateData(sleepData).sorted(by: { $0.level < $1.level })
                    }
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    
                    Button("수면 단계 정렬") {
                        displayData = aggregateData(sleepData).sorted(by: { $0.level < $1.level })
                    }
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
            .padding()

            VStack {
                HStack {
                    VStack(alignment: .leading) {
                        Text("시작 날짜")
                        Button(action: {
                            temporaryStartDate = startDate // 현재 선택된 날짜로 초기화
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
                                .environment(\.locale, Locale(identifier: "ko_KR")) // 한국어 로케일 사용
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
                            temporaryEndDate = endDate // 현재 선택된 날짜로 초기화
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
                                .environment(\.locale, Locale(identifier: "ko_KR")) // 한국어 로케일 사용
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
            }
            .padding()

            List(displayData, id: \.level) { data in
                VStack(alignment: .leading) {
                    Text("sleep level: \(data.level)")
                    Text("인터벌 횟수 : \(data.count)")
                    Text("총 시간 : \(formatTimeInterval(data.duration))")
                }
            }
        }
    }

    private func requestHealthKitAuthorization() {
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let typesToRead: Set = [sleepType]

        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            if success {
                fetchSleepData()
            } else {
                print("HealthKit Authorization Failed: \(String(describing: error))")
            }
        }
    }

    private func fetchSleepData() {
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)

        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: 0, sortDescriptors: nil) { query, results, error in
            guard let results = results as? [HKCategorySample] else {
                print("Failed to fetch sleep data: \(String(describing: error))")
                return
            }

            DispatchQueue.main.async {
                self.sleepData = results
                self.displayData = self.aggregateData(results)
            }
        }

        healthStore.execute(query)
    }

    private func sleepStage(from sample: HKCategorySample) -> String {
        if #available(iOS 16.0, *) {
            switch sample.value {
            case HKCategoryValueSleepAnalysis.inBed.rawValue:
                return "In Bed"
            case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                return "REM"
            case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                return "Deep"
            case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
                return "Core"
            case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue:
                return "Asleep (Unspecified)"
            default:
                return "Unknown"
            }
        } else {
            switch sample.value {
            case HKCategoryValueSleepAnalysis.inBed.rawValue:
                return "In Bed"
            case HKCategoryValueSleepAnalysis.asleep.rawValue:
                return "Asleep"
            default:
                return "Unknown"
            }
        }
    }

    private func aggregateData(_ samples: [HKCategorySample]) -> [(level: String, count: Int, duration: TimeInterval)] {
        let groupedData = Dictionary(grouping: samples) { sample in
            sleepStage(from: sample)
        }
        
        return groupedData.map { (key, value) in
            let totalDuration = value.reduce(0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
            return (level: key, count: value.count, duration: totalDuration)
        }
    }

    private func formatDateInput(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy MM dd"
        return formatter.string(from: date)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }

    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}
