import Foundation
import Combine
import CoreML

class StageAiPredictionManager: ObservableObject {
    @Published var predictions: [StageAiPredictionResult] = []
    private var model: StageAi_MyTabularClassifier
    private let windowSize90 = 90
    private let windowSize30 = 30
    
    private var aiPredictionTimer: Timer?  // Timer 변수 추가
    private var alarmTime: Date?           // 기상 시각 저장 변수
    private var wakeUpBufferMinutes: Int?  // 여분 시간 저장 변수
    private var receivedData: [MeasurementData] = []  // 데이터 저장 변수
    
    init() {
        self.model = try! StageAi_MyTabularClassifier(configuration: MLModelConfiguration())
    }
    
    // 기상 시각과 여분 시간을 설정하는 함수
    func setAlarmTime(alarmTime: Date, wakeUpBufferMinutes: Int) {
        self.alarmTime = alarmTime  // 마지노선 기상시각
        self.wakeUpBufferMinutes = wakeUpBufferMinutes  // 기상 여분 시간
        if alarmTime != nil && wakeUpBufferMinutes > 0 { // Ensure both are set
            schedulePrediction()  // 예측을 스케줄링
        }
    }
    
    // 예측을 스케줄링하는 함수
    private func schedulePrediction() {
        guard let alarmTime = alarmTime, let wakeUpBufferMinutes = wakeUpBufferMinutes else {
            print("기상 시각과 여분 시간이 설정되지 않았습니다.")
            return
        }

        // 알람 시간에서 여분 시간을 빼서 예측 시작 시간을 계산
        let startTime = Calendar.current.date(byAdding: .minute, value: -wakeUpBufferMinutes, to: alarmTime) ?? alarmTime
        
        // 기존 타이머가 있으면 무효화
        aiPredictionTimer?.invalidate()
        
        // 현재 시간과 예측 시작 시간 간의 간격 계산
        let currentTime = Date()
        let timeInterval = startTime.timeIntervalSince(currentTime)
        
        if timeInterval > 0 {
            // 타이머 설정: 일정 시간이 지나면 AI 예측을 시작
            aiPredictionTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { [weak self] _ in
                self?.performScheduledPrediction()
            }
            // 기상시각 로그를 로컬 시간대로 변환하여 출력
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            dateFormatter.timeZone = TimeZone.current  // 로컬 시간대 사용
            
            print("예측이 \(timeInterval)초 후에 스케줄링되었습니다. 기상시각: \(dateFormatter.string(from: alarmTime)) 여분시간: \(wakeUpBufferMinutes)")
        } else {
            // 기상 시간이 이미 지난 경우, 즉시 예측을 시작
            print("예측 시작 시간이 이미 지났습니다. 즉시 예측을 수행합니다.")
            performScheduledPrediction()
        }
    }
    
    // 타이머에 의해 호출되는 함수
    private func performScheduledPrediction() {
        print("스케줄된 예측을 수행합니다.")
        checkAndPerformPrediction()  // 데이터를 확인하고 예측을 수행합니다.
    }

    // 수신된 데이터를 추가하는 함수
    func appendReceivedData(_ data: [MeasurementData]) {
        receivedData.append(contentsOf: data)
    }
    
    // 시간 검사 및 예측 수행 함수
    func checkAndPerformPrediction() {
        guard !receivedData.isEmpty else {  // 데이터가 비어있는지 확인
            print("수신된 데이터가 없습니다.")
            return
        }

        // 예측을 시작할 수 있는 시각인지 확인
        let currentTime = Date()
        if let alarmTime = alarmTime, let wakeUpBufferMinutes = wakeUpBufferMinutes {
            let startTime = Calendar.current.date(byAdding: .minute, value: -wakeUpBufferMinutes, to: alarmTime) ?? alarmTime
            if currentTime >= startTime {
                processReceivedData(receivedData)
                receivedData.removeAll()  // 예측 후 데이터 클리어
            } else {
                print("예측을 시작할 시각이 아닙니다. 현재 시각: \(currentTime), 예측 시작 시각: \(startTime)")
            }
        }
    }
    
    func processReceivedData(_ data: [MeasurementData]) {
        guard data.count >= windowSize90 else {
            print("데이터가 부족하여 예측을 수행할 수 없습니다.")
            return
        }

        performPrediction(data)
    }

    private func performPrediction(_ data: [MeasurementData]) {
        let window90 = Array(data.suffix(windowSize90))
        let window30 = Array(data.suffix(windowSize30))
        
        if let input = preprocessDataForPrediction(window90, window30: window30) {
            do {
                let predictionOutput = try model.prediction(input: input)
                let predictedLevel = predictionOutput.level_Int_
                let predictedProbability = predictionOutput.level_Int_Probability
                
                let result = StageAiPredictionResult(
                    timestamp: formattedCurrentTime(),
                    predictedLevel: predictedLevel,
                    predictedProbability: predictedProbability
                )
                
                DispatchQueue.main.async {
                    self.predictions.append(result)
                    print("StageAi 예측 결과: \(predictedLevel), 확률: \(predictedProbability)")
                }
            } catch {
                print("예측 실패: \(error.localizedDescription)")
            }
        }
    }

    private func preprocessDataForPrediction(_ window90: [MeasurementData], window30: [MeasurementData]) -> StageAi_MyTabularClassifierInput? {
        guard window90.count == windowSize90 else {
            print("데이터가 충분하지 않아 예측을 수행할 수 없습니다.")
            return nil
        }

        let heartRates90 = window90.map { $0.heartRate }
        let accelerationX90 = window90.map { $0.accelerationX }
        let accelerationY90 = window90.map { $0.accelerationY }
        let accelerationZ90 = window90.map { $0.accelerationZ }
        
        return preprocessIncomingData(
            heartRates: heartRates90,
            accelerationX: accelerationX90,
            accelerationY: accelerationY90,
            accelerationZ: accelerationZ90
        )
    }

    private func formattedCurrentTime() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter.string(from: Date())
    }

    func exportPredictionsToCSV() -> URL? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let date = dateFormatter.string(from: Date())
        let fileName = "user_StageAi_\(date).csv"
        
        let path = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        var csvText = "Timestamp,Predicted Level,Probabilities\n"
        
        for entry in predictions {
            let probabilitiesText = entry.predictedProbability.map { "\($0.key): \($0.value * 100)%" }.joined(separator: "; ")
            let newLine = "\(entry.timestamp),\(entry.predictedLevel),\(probabilitiesText)\n"
            csvText.append(newLine)
        }
        
        do {
            try csvText.write(to: path, atomically: true, encoding: .utf8)
            return path
        } catch {
            print("Failed to create CSV file: \(error)")
            return nil
        }
    }

    func clearPredictions() {
        predictions.removeAll()
    }
}

struct StageAiPredictionResult: Identifiable {
    var id = UUID()
    var timestamp: String
    var predictedLevel: Int64
    var predictedProbability: [Int64: Double]
}
