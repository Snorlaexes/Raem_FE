import Foundation
import SwiftData
import HealthKit
import HealthKitUI


class HealthKitService {
    let healthStore = HKHealthStore()
    
    // 읽기 및 쓰기 권한 설정
    let read = Set([HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!])
    let share = Set([HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!])
    
    func configure() {
         // 해당 장치가 healthkit을 지원하는지 여부
         if HKHealthStore.isHealthDataAvailable() {
             requestAuthorization()
         }
     }
    
    // 권한 요청 메소드
    private func requestAuthorization() {
        healthStore.requestAuthorization(toShare: share, read: read) { success, error in
            if let error = error {
                print("Error requesting authorization: \(error.localizedDescription)")
                return
            }

            if success {
                print("권한이 허락되었습니다")
            } else {
                print("권한이 없습니다")
            }
        }
    }

    func fetchLatestHeartRateSample(completion: @escaping (Double) -> Void) {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let query = HKSampleQuery(sampleType: heartRateType,
                                  predicate: nil,
                                  limit: 1,
                                  sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { query, samples, error in
            guard let sample = samples?.first as? HKQuantitySample else {
                print("Failed to fetch heart rate sample: \(error?.localizedDescription ?? "Unknown error")")
                completion(0.0)
                return
            }
            let heartRate = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
            print("Heart Rate: \(heartRate) bpm")
            completion(heartRate)
        }
        healthStore.execute(query)
    }
    
    func getSleepData(){
        // 수면 데이터 Type 정의
        if let sleepType = HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier.sleepAnalysis) {
            // 데이터를 필터링할 조건(predicate)를 설정할 수 있음. 여기선 일주일 데이터를 받아오도록 설정
            let calendar = Calendar.current
            let endDate = Date() // 현재 시간
            let startDate = calendar.date(byAdding: .day, value: -7, to: endDate) // 7일 전 시간
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
            // 최신 데이터를 먼저 가져오도록 sort 기준 정의
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            
            
            // 수면 단계를 정수형에서 문자열로 변환하기 위한 딕셔너리
            let sleepCategoryStrings = [
                0: "In Bed",
                1: "Sleep Unspecified",
                2: "Awake",
                3: "Core",
                4: "Deep",
                5: "REM"
            ]

            // 한국 시간대로 설정
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            dateFormatter.timeZone = TimeZone(identifier: "Asia/Seoul")

            
            // 쿼리 수행 완료시 실행할 콜백 정의
            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: 500, sortDescriptors: [sortDescriptor]) { (query, tmpResult, error) -> Void in
                if error != nil {
                    // 에러 처리를 수행합니다.
                    print(error)
                    return
                }
                if let result = tmpResult {
                    for item in result {
                        if let sample = item as? HKCategorySample {
                            // 가져온 데이터 출력
                     
                            // 수면 상태가 "inbed"인 경우에는 출력을 건너뜁니다.
                            guard sample.value != 0 else {
                                continue
                            }
                            
                            // 가져온 데이터 출력
                            print("Start Date: \(dateFormatter.string(from : sample.startDate))")
                            print("End Date: \(dateFormatter.string(from: sample.endDate))")
                            
                            if let stringValue = sleepCategoryStrings[sample.value] {
                                print("Sleep level: \(stringValue)")
                            } else {
                                print("Sleep value: Unknown")
                            }
                            
//                            print("Metadata: \(String(describing: sample.metadata))")
//                            print("UUID: \(sample.uuid)")
//                            print("Source: \(sample.sourceRevision)")
//                            print("Device: \(String(describing: sample.device))")
                            print("\n---------------------------------\n")
                        
                        }
                    }
                }
            }
            // HealthKit store에서 쿼리를 실행
            healthStore.execute(query)
        }
    }
    
    var heartRate: Double = 0.0
    var timer: Timer?

    
    func startMeasuringHeartRate() {
        timer?.invalidate() // 이전 타이머 중지

        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            self.fetchLatestHeartRateSample { heartRate in
                  DispatchQueue.main.async {
                      self.heartRate = heartRate
                  }
              }
        }
        timer?.fire() // 즉시 실행
    }


    func stopMeasuringHeartRate() {
        timer?.invalidate()
    }


    
    
    
    

}

