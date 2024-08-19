import WatchKit
import Foundation
import HealthKit
import CoreMotion
import AVFoundation
import WatchConnectivity

class Items: NSObject, ObservableObject, WKExtendedRuntimeSessionDelegate, WCSessionDelegate {
    private var healthStore = HKHealthStore()
    private var motionManager = CMMotionManager()
    private var audioRecorder: AVAudioRecorder?
    private var timer: Timer?
    private var runtimeSession: WKExtendedRuntimeSession?
    
    @Published var isMeasuring = false
    @Published var output: String = ""
    private var collectedData: [String] = []
    
    private var heartRate: Double = 0.0
    private var accelerometerData: CMAccelerometerData?
    private var ambientNoiseLevel: Float = 0.0
    
    private var heartRateQuery: HKQuery?
    private var session: WCSession?
    private var endTime: String? // iPhone에서 설정된 종료 시간을 저장
    
    private var emailSent = false

    override init() {
        super.init()
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }

    func startMeasuring() {
        isMeasuring = true
        requestAuthorization()
        startHeartRateMeasurement()
        startAccelerometerMeasurement()
        startDecibelMeasurement()
        
        startBackgroundTask() // 백그라운드 작업 시작
        
        // CSV 파일에 열 제목을 추가
        collectedData.append("Date,Heart Rate,Decibels,Accelerometer (x,y,z)")
        
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            self.updateOutput()
        }
    }
    
    func stopMeasuring() {
        isMeasuring = false
        if let query = heartRateQuery {
            healthStore.stop(query)
        }
        motionManager.stopAccelerometerUpdates()
        audioRecorder?.stop()
        timer?.invalidate()
        runtimeSession?.invalidate()

        // 데이터를 저장하고 이메일을 전송하는 작업을 분리하여 직접 호출
        saveDataToCSVAndSendEmail()
    }
    
    private func requestAuthorization() {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let readTypes: Set<HKObjectType> = [heartRateType]
        
        healthStore.requestAuthorization(toShare: nil, read: readTypes) { (success, error) in
            if !success {
                print("HealthKit authorization failed: \(String(describing: error))")
            }
        }
    }
    
    private func startHeartRateMeasurement() {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        
        let query = HKAnchoredObjectQuery(type: heartRateType, predicate: nil, anchor: nil, limit: HKObjectQueryNoLimit) { (query, samples, deletedObjects, anchor, error) in
            guard let samples = samples as? [HKQuantitySample] else { return }
            self.handleHeartRateSamples(samples)
        }
        
        query.updateHandler = { (query, samples, deletedObjects, anchor, error) in
            guard let samples = samples as? [HKQuantitySample] else { return }
            self.handleHeartRateSamples(samples)
        }
        
        healthStore.execute(query)
        heartRateQuery = query
    }
    
    private func handleHeartRateSamples(_ samples: [HKQuantitySample]) {
        guard let sample = samples.last else { return }
        heartRate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
    }
    
    private func startAccelerometerMeasurement() {
        motionManager.startAccelerometerUpdates()
    }
    
    private func startDecibelMeasurement() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true)
            audioSession.requestRecordPermission { allowed in
                if allowed {
                    self.startRecording()
                }
            }
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    private func startRecording() {
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatAppleLossless),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue
        ]
        
        let url = URL(fileURLWithPath: "/dev/null", isDirectory: true)
        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
        } catch {
            print("Failed to start recording: \(error)")
        }
    }
    
    @objc private func updateOutput() {
        if let endTime = endTime, getCurrentTime() >= endTime && !emailSent {
            // 측정을 멈추고 이메일을 보내는 메서드를 호출
            stopMeasuring()
            return
        }
        
        if let data = motionManager.accelerometerData {
            accelerometerData = data
        }
        
        audioRecorder?.updateMeters()
        
        // 음압 수준을 절대값으로 변환하여 데시벨을 구함 (시끄러울수록 값이 커짐)
        ambientNoiseLevel = abs(audioRecorder?.averagePower(forChannel: 0) ?? 0.0)
        
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd  HH:mm:ss"
        let dateString = formatter.string(from: date)
        
        let accelerometerString = "\(String(format: "%.2f", accelerometerData?.acceleration.x ?? 0.0)), \(String(format: "%.2f", accelerometerData?.acceleration.y ?? 0.0)), \(String(format: "%.2f", accelerometerData?.acceleration.z ?? 0.0))"
        
        // 데이터를 A열(날짜), B열(심박수), C열(데시벨), D열(가속도계)로 저장
        let outputString = "\(dateString),\(String(format: "%.2f", heartRate)),\(String(format: "%.2f", ambientNoiseLevel)),\(accelerometerString)"
        
        collectedData.append(outputString)
        
        DispatchQueue.main.async {
            self.output = outputString
            print(outputString)
        }
        
        sendDataToPhone(date: dateString, heartRate: heartRate, accelerometer: accelerometerData, decibels: ambientNoiseLevel)
    }
    
    private func getCurrentTime() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        return dateFormatter.string(from: Date())
    }
    
    private func saveDataToCSVAndSendEmail() {
        let fileName = "data.csv"
        let path = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        let csvText = collectedData.joined(separator: "\n")
        
        do {
            try csvText.write(to: path, atomically: true, encoding: .utf8)
            sendEmailWithCSV(attachmentURL: path)
        } catch {
            print("Failed to save CSV: \(error)")
        }
    }
    
    private func sendEmailWithCSV(attachmentURL: URL) {
        guard !emailSent else { return }  // 이메일이 이미 전송되었는지 확인
        
        let session = WCSession.default
        if session.isReachable {
            let emailData: [String: Any] = ["email": "thehd9891@naver.com", "attachmentURL": attachmentURL.path]
            session.sendMessage(emailData, replyHandler: nil) { error in
                print("Failed to send email data: \(error)")
            }
            emailSent = true  // 이메일 전송 완료로 표시
        }
    }
    
    private func sendDataToPhone(date: String, heartRate: Double, accelerometer: CMAccelerometerData?, decibels: Float) {
        let accelerometerString = "x=\(String(format: "%.2f", accelerometer?.acceleration.x ?? 0.0)), y=\(String(format: "%.2f", accelerometer?.acceleration.y ?? 0.0)), z=\(String(format: "%.2f", accelerometer?.acceleration.z ?? 0.0))"
        
        let data: [String: Any] = [
            "date": date,
            "heartRate": heartRate,
            "accelerometer": accelerometerString,
            "decibels": decibels
        ]
        
        if let session = session, session.isReachable {
            session.sendMessage(data, replyHandler: nil) { error in
                print("Failed to send data: \(error)")
            }
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // Handle session activation
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let receivedEndTime = message["endTime"] as? String {
            self.endTime = receivedEndTime
            print("End time set to: \(receivedEndTime)")
        }
    }
    
    func extendedRuntimeSessionDidStart(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        print("Extended runtime session started")
    }
    
    func extendedRuntimeSessionWillExpire(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        print("Extended runtime session will expire soon")
        
        saveDataToCSVAndSendEmail()
        
        if !isMeasuring {
            runtimeSession = WKExtendedRuntimeSession()
            runtimeSession?.delegate = self
            runtimeSession?.start()
        }
    }
    
    func extendedRuntimeSession(_ extendedRuntimeSession: WKExtendedRuntimeSession, didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason, error: (any Error)?) {
        print("Extended runtime session invalidated with reason: \(reason)")
    }
    
    // Background Task 관련 코드
    private func startBackgroundTask() {
        WKExtension.shared().scheduleBackgroundRefresh(withPreferredDate: Date(timeIntervalSinceNow: 15 * 60), userInfo: nil) { error in
            if let error = error {
                print("Failed to schedule background task: \(error)")
                return
            }
            print("Background task scheduled successfully")
        }
    }
    
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for task in backgroundTasks {
            if let refreshTask = task as? WKApplicationRefreshBackgroundTask {
                // 백그라운드 작업에서 해야 할 작업 처리
                print("Handling background refresh task")
                
                refreshTask.setTaskCompletedWithSnapshot(false)
                startMeasuring() // 백그라운드에서 측정 작업 다시 시작
            } else if let snapshotTask = task as? WKSnapshotRefreshBackgroundTask {
                snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date.distantFuture, userInfo: nil)
            } else {
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }
}
