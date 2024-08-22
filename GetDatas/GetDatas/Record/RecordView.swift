import SwiftUI
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

class iPhoneConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    func sessionDidBecomeInactive(_ session: WCSession) {}
    
    func sessionDidDeactivate(_ session: WCSession) {}
    
    @Published var receivedData: [MeasurementData] = []
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    
    func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        do {
            let receivedData = try JSONDecoder().decode([MeasurementData].self, from: messageData)
            
            DispatchQueue.main.async {
                self.receivedData.append(contentsOf: receivedData)
            }
        } catch {
            print("Failed to decode received data: \(error.localizedDescription)")
        }
    }
    
    func exportDataToCSV() -> URL? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let date = dateFormatter.string(from: Date())
        
        // Retrieve the user's name from UserDefaults or use device name as a fallback
        let userName = UserDefaults.standard.string(forKey: "userName") ?? UIDevice.current.name
        
        // Set the file name as "Name(Date).csv"
        let fileName = "\(userName)(\(date)).csv"
        
        let path = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        var csvText = "Timestamp,Heart Rate,Decibel Level,Acceleration X,Acceleration Y,Acceleration Z\n"
        
        for entry in receivedData {
            let newLine = "\(entry.timestamp),\(entry.heartRate),\(entry.decibelLevel),\(entry.accelerationX),\(entry.accelerationY),\(entry.accelerationZ)\n"
            csvText.append(contentsOf: newLine)
        }
        
        do {
            try csvText.write(to: path, atomically: true, encoding: .utf8)
            return path
        } catch {
            print("Failed to create CSV file: \(error)")
            return nil
        }
    }
    
    func clearReceivedData() {
        receivedData.removeAll()
    }
}

struct SettingsView: View {
    @AppStorage("userName") var userName: String = ""
    
    var body: some View {
        Form {
            TextField("이름 입력", text: $userName)
        }
        .navigationTitle("설정")
    }
}

struct RecordView: View {
    @ObservedObject var connectivityManager = iPhoneConnectivityManager()
    
    var body: some View {
        VStack {
            if !connectivityManager.receivedData.isEmpty {
                HStack {
                    Button("CSV로 내보내기") {
                        if let csvURL = connectivityManager.exportDataToCSV() {
                            let activityVC = UIActivityViewController(activityItems: [csvURL], applicationActivities: nil)
                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                               let rootVC = windowScene.windows.first?.rootViewController {
                                rootVC.present(activityVC, animated: true)
                            }
                        }
                    }
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    
                    Button("데이터 삭제하기") {
                        connectivityManager.clearReceivedData()
                    }
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
            
            List(connectivityManager.receivedData) { entry in
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
        }
        .navigationTitle("실시간 데이터")
        .toolbar {
            NavigationLink(destination: SettingsView()) {
                Text("설정")
            }
        }
    }
}
