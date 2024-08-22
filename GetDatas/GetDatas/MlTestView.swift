import SwiftUI
import CoreML
import Foundation

// 연: 인공지능 모델 테스트 예측 뷰

struct MlTestView: View {
    @State private var sleepStage: Int = -1 // 예측 값
    @State private var correctStage: Int = -1 // 실제 값
    @State private var predictionTime: String = ""
    @State private var timer: Timer?
    @State private var dataIndex: Int = 0
    
    let model: MyTabularClassifier0814_2 = {
        do {
            let config = MLModelConfiguration()
            return try MyTabularClassifier0814_2(configuration: config)
        } catch {
            fatalError("Couldn't load model: \(error)")
        }
    }()
    
    let csvData: [[Double]] = loadCSVData()
    
    var body: some View {
        VStack {
            Text("Predicted Sleep Stage:")
            Text("Predicted: \(sleepStage)")
                .font(.title2)
                .padding()
            Text("Correct: \(correctStage)")
                .font(.title2)
                .padding()
            Text("Time: \(predictionTime)")
                .font(.footnote)
                .padding()
        }
        .onAppear {
            startRealTimePrediction()
        }
    }
    
    func startRealTimePrediction() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if dataIndex < csvData.count {
                let data = csvData[dataIndex]
                if dataIndex % 60 == 59 { // 60초에 한번 예측
                    if let prediction = predictSleepStage(from: data) {
                        sleepStage = prediction
                        correctStage = Int(data[4]) // 정답값은 CSV의 5번째 컬럼에 있다고 가정
                        predictionTime = getCurrentTime()
                    }
                }
                dataIndex += 1
            } else {
                timer?.invalidate()
            }
        }
    }
    
    func predictSleepStage(from data: [Double]) -> Int? {
        let input = MyTabularClassifier0814_2Input(
            ACC_X: data[0],
            ACC_Y: data[1],
            ACC_Z: data[2],
            HR: data[3]
        )
        
        do {
            let prediction = try model.prediction(input: input)
            
            return Int(prediction.Sleep_Stage)
        } catch {
            print("Prediction error: \(error)")
            return nil
        }
    }
    
    func getCurrentTime() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        return dateFormatter.string(from: Date())
    }
}

func loadCSVData() -> [[Double]] {
    guard let path = Bundle.main.path(forResource: "S020_test", ofType: "csv") else {
        fatalError("CSV file not found.")
    }
    
    do {
        let content = try String(contentsOfFile: path)
        let rows = content.components(separatedBy: "\n")
        var result: [[Double]] = []
        
        for row in rows {
            let columns = row.components(separatedBy: ",")
            if columns.count >= 5,  // 4개의 특징 데이터와 1개의 정답 데이터가 포함됨
               let accX = Double(columns[0]),
               let accY = Double(columns[1]),
               let accZ = Double(columns[2]),
               let hr = Double(columns[3]),
               let label = Double(columns[4]) {  // 정답 라벨
                result.append([accX, accY, accZ, hr, label])
            }
        }
        
        return result
    } catch {
        fatalError("Error reading CSV file: \(error)")
    }
}
