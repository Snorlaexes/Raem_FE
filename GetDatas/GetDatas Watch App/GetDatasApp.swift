import SwiftUI
import HealthKit
import AVFoundation
import CoreMotion
import WatchKit
import WatchConnectivity

// 측정 데이터를 저장하기 위한 구조체
struct MeasurementData: Codable, Identifiable {
    var id = UUID()
    var heartRate: Double
    var decibelLevel: Float
    var accelerationX: Double
    var accelerationY: Double
    var accelerationZ: Double
    var timestamp: String
}

// 데이터 관리를 위한 클래스
class DataManager: NSObject, ObservableObject {
    @Published var isMeasuring = false
    @Published var localData: [MeasurementData] = []
    @Published var currentHeartRate: Double = 0.0
    
    private let userDefaultsKey = "savedMeasurements"
    private let healthStore = HKHealthStore()
    private let motionManager = CMMotionManager()
    private var audioRecorder: AVAudioRecorder?
    private var measurementTimer: Timer?
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?
    
    override init() {
        super.init()
        loadLocalData()
        requestHealthKitAuthorization()
        setupWatchConnectivity()
    }
    
    // HealthKit 권한 요청
    func requestHealthKitAuthorization() {
        if HKHealthStore.isHealthDataAvailable() {
            guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
                print("Heart Rate Type is not available")
                return
            }
            let typesToShare: Set = [HKObjectType.workoutType()]
            let typesToRead: Set = [heartRateType]
            
            healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { (success, error) in
                if !success {
                    print("HealthKit authorization failed: \(String(describing: error))")
                }
            }
        }
    }
    
    // 실시간 심박수 측정 시작
    func startHeartRateMonitoring() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .other
        configuration.locationType = .unknown
        
        do {
            workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            workoutBuilder = workoutSession?.associatedWorkoutBuilder()
            
            workoutBuilder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)
            
            workoutBuilder?.delegate = self
            workoutSession?.delegate = self
            
            workoutSession?.startActivity(with: Date())
            workoutBuilder?.beginCollection(withStart: Date(), completion: { (success, error) in
                if !success {
                    print("Workout builder failed to start: \(String(describing: error))")
                }
            })
        } catch {
            print("Failed to start workout session: \(error.localizedDescription)")
        }
    }
    
    // 실시간 심박수 측정 중지
    func stopHeartRateMonitoring() {
        workoutSession?.stopActivity(with: Date())
        workoutSession?.end()
    }
    
    // 소음 측정 시작
    func startNoiseMonitoring() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: URL(fileURLWithPath: "/dev/null"), settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
        } catch {
            print("Failed to set up audio session or AVAudioRecorder: \(error.localizedDescription)")
        }
    }
    
    // 가속도계 측정 시작
    func startAccelerometerUpdates() {
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 2.0
            motionManager.startAccelerometerUpdates()
        }
    }
    
    // 측정 시작
    func startMeasuring() {
        isMeasuring = true
        startHeartRateMonitoring()
        startNoiseMonitoring()
        startAccelerometerUpdates()
        
        measurementTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            self.recordMeasurement()
        }
    }
    
    // 측정 중지
    func stopMeasuring() {
        isMeasuring = false
        measurementTimer?.invalidate()
        measurementTimer = nil
        stopHeartRateMonitoring()
    }
    
    // 데이터 기록
    private func recordMeasurement() {
        self.audioRecorder?.updateMeters()
        let decibelLevel = self.audioRecorder?.averagePower(forChannel: 0) ?? -160.0
        let acceleration = self.motionManager.accelerometerData?.acceleration ?? CMAcceleration(x: 0, y: 0, z: 0)
        let timestamp = self.currentTimestamp()
        
        let newEntry = MeasurementData(
            heartRate: self.currentHeartRate,
            decibelLevel: decibelLevel,
            accelerationX: acceleration.x,
            accelerationY: acceleration.y,
            accelerationZ: acceleration.z,
            timestamp: timestamp
        )
        
        self.localData.append(newEntry)
        self.saveLocalData()
    }
    
    // 현재 타임스탬프 가져오기
    private func currentTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: Date())
    }
    
    // 로컬 데이터 저장
    private func saveLocalData() {
        let data = try? JSONEncoder().encode(localData)
        UserDefaults.standard.set(data, forKey: userDefaultsKey)
    }
    
    // 로컬 데이터 로드
    private func loadLocalData() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let savedData = try? JSONDecoder().decode([MeasurementData].self, from: data) {
            localData = savedData
        }
    }
    
    // 로컬 데이터 삭제
    func clearLocalData() {
        localData.removeAll()
        saveLocalData()
    }
    
    // Watch Connectivity 설정
    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    // 데이터 전송
    func sendDataToiPhone() {
        guard !localData.isEmpty else { return }
        
        if WCSession.default.isReachable {
            do {
                let data = try JSONEncoder().encode(localData)
                WCSession.default.sendMessageData(data, replyHandler: nil, errorHandler: { error in
                    print("Error sending data: \(error.localizedDescription)")
                })
                clearLocalData() // 데이터 전송 후 데이터 삭제
            } catch {
                print("Failed to encode data: \(error.localizedDescription)")
            }
        }
    }
}

extension DataManager: HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        // Handle workout session state changes if needed
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("Workout session failed: \(error.localizedDescription)")
    }
    
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        // Handle workout events if needed
    }
    
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }
        
        if collectedTypes.contains(heartRateType) {
            if let heartRateStatistics = workoutBuilder.statistics(for: heartRateType) {
                let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                let heartRate = heartRateStatistics.mostRecentQuantity()?.doubleValue(for: heartRateUnit) ?? 0.0
                
                DispatchQueue.main.async {
                    self.currentHeartRate = heartRate
                }
            }
        }
    }
}

extension DataManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    
    func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        // 이 부분은 워치가 데이터를 받았을 때 사용되지 않음
    }
}

// 메인 뷰
struct ContentView: View {
    @ObservedObject var dataManager = DataManager()
    
    var body: some View {
        NavigationView {
            ScrollView { // ScrollView로 화면을 스크롤 가능하게 변경
                VStack {
                    if dataManager.isMeasuring {
                        Button("측정 중지") {
                            dataManager.stopMeasuring()
                        }
                    } else {
                        Button("측정 시작") {
                            dataManager.startMeasuring()
                        }
                    }
                    
                    Button("내보내기") {
                        dataManager.sendDataToiPhone()
                    }
                    .padding(.top, 20)
                    
                    NavigationLink("데이터 보기", destination: DataListView(dataManager: dataManager))
                        .padding(.top, 20)
                }
                .padding() // 패딩 추가
            }
            .navigationTitle("메인 화면")
        }
    }
}

// 데이터 리스트 뷰
struct DataListView: View {
    @ObservedObject var dataManager: DataManager
    
    var body: some View {
        List(dataManager.localData) { entry in
            VStack(alignment: .leading) {
                Text("Timestamp: \(entry.timestamp)")
                Text("Heart Rate: \(entry.heartRate, specifier: "%.0f") BPM")
                Text("Noise Level: \(entry.decibelLevel, specifier: "%.2f") dB")
                Text("Acceleration: X: \(entry.accelerationX, specifier: "%.2f")")
                Text("Y: \(entry.accelerationY, specifier: "%.2f")")
                Text("Z: \(entry.accelerationZ, specifier: "%.2f")")
            }
            .padding(.vertical, 5)
        }
        .navigationTitle("측정된 데이터")
    }
}

// 메인 엔트리 포인트
@main
struct WatchApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
