import Foundation
import HealthKit
import AVFoundation
import CoreMotion
import WatchKit
import WatchConnectivity

struct MeasurementData: Codable, Identifiable {
    var id = UUID()
    var heartRate: Double
    var decibelLevel: Float
    var accelerationX: Double
    var accelerationY: Double
    var accelerationZ: Double
    var timestamp: String
}

class DataManager: NSObject, ObservableObject {
    @Published var isMeasuring = false
    @Published var localData: [MeasurementData] = []
    @Published var currentHeartRate: Double = 0.0
    @Published var isSendComplete = false
    @Published var sentDataCount: Int = 0
    
    private let userDefaultsKey = "savedMeasurements"
    private let healthStore = HKHealthStore()
    private let motionManager = CMMotionManager()
    private var audioRecorder: AVAudioRecorder?
    private var measurementTimer: Timer?
    private var dataTransferTimer: Timer?
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?
    
    override init() {
        super.init()
        loadLocalData()
        requestHealthKitAuthorization()
        setupWatchConnectivity()
    }
    
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
    
    func stopHeartRateMonitoring() {
        workoutSession?.stopActivity(with: Date())
        workoutSession?.end()
    }
    
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
    
    func startAccelerometerUpdates() {
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 2.0
            motionManager.startAccelerometerUpdates()
        }
    }
    
    func startMeasuring() {
        isMeasuring = true
        startHeartRateMonitoring()
        startNoiseMonitoring()
        startAccelerometerUpdates()
        
        measurementTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            self.recordMeasurement()
        }
        
        dataTransferTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            self.sendDataToiPhone()
        }
    }
    
    func stopMeasuring() {
        isMeasuring = false
        measurementTimer?.invalidate()
        measurementTimer = nil
        dataTransferTimer?.invalidate()
        dataTransferTimer = nil
        stopHeartRateMonitoring()
        sendDataToiPhone() // 측정 종료 시 마지막으로 남은 데이터 전송
    }
    
    private func recordMeasurement() {
        audioRecorder?.updateMeters()
        let decibelLevel = audioRecorder?.averagePower(forChannel: 0) ?? -160.0
        let acceleration = motionManager.accelerometerData?.acceleration ?? CMAcceleration(x: 0, y: 0, z: 0)
        let timestamp = currentTimestamp()
        
        let newEntry = MeasurementData(
            heartRate: currentHeartRate,
            decibelLevel: decibelLevel,
            accelerationX: acceleration.x,
            accelerationY: acceleration.y,
            accelerationZ: acceleration.z,
            timestamp: timestamp
        )
        
        localData.append(newEntry)
        saveLocalData()
    }
    
    private func currentTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: Date())
    }
    
    private func saveLocalData() {
        if let data = try? JSONEncoder().encode(localData) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
    
    private func loadLocalData() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let savedData = try? JSONDecoder().decode([MeasurementData].self, from: data) {
            localData = savedData
        }
    }
    
    private func clearLocalData() {
        localData.removeAll()
        saveLocalData()
    }
    
    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    func sendDataToiPhone() {
        guard !localData.isEmpty else { return }
        
        let totalDataCount = localData.count
        
        DispatchQueue.global(qos: .background).async {
            if WCSession.default.isReachable {
                do {
                    let data = try JSONEncoder().encode(self.localData)
                    WCSession.default.sendMessageData(data, replyHandler: nil, errorHandler: { error in
                        print("Error sending data: \(error.localizedDescription)")
                    })
                    
                    DispatchQueue.main.async {
                        self.sentDataCount = totalDataCount
                        self.isSendComplete = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            self.isSendComplete = false
                        }
                        self.clearLocalData()
                    }
                } catch {
                    print("Failed to encode data: \(error.localizedDescription)")
                }
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
        // Handle incoming data from iPhone (if needed)
    }
}
