import Foundation
import SwiftUI
import MessageUI
import WatchConnectivity

class Items: NSObject, ObservableObject, WCSessionDelegate, MFMailComposeViewControllerDelegate {
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {}
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {}
    
    @Published var records: [String] = []
    @Published var endTime: String = "09:00" // 기본 종료 시간 설정
    
    private var session: WCSession?

    override init() {
        super.init()
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }
    
    func sendEndTimeToWatch() {
        if let session = session, session.isReachable {
            session.sendMessage(["endTime": endTime], replyHandler: nil) { error in
                print("Failed to send end time: \(error)")
            }
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let testMessage = message["test"] as? String {
            DispatchQueue.main.async {
                self.records.append(testMessage)
            }
        }
        
        if let date = message["date"] as? String,
           let heartRate = message["heartRate"] as? Double,
           let accelerometer = message["accelerometer"] as? String,
           let decibels = message["decibels"] as? Float {
            
            let dataString = """
            \(date)
            심박수 : \(String(format: "%.2f", heartRate)) | 데시벨 : \(String(format: "%.2f", decibels))
            가속도계 : \(accelerometer)
            """

            DispatchQueue.main.async {
                self.records.append(dataString)
            }
        }
        
        if let email = message["email"] as? String, let filePath = message["attachmentURL"] as? String {
            sendEmailWithAttachment(to: email, filePath: filePath)
        }
    }
    
    func saveRecordsToCSV() -> URL? {
        let fileName = "data.csv"
        let path = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        let csvText = records.joined(separator: "\n")
        
        do {
            try csvText.write(to: path, atomically: true, encoding: .utf8)
            print("CSV file saved at: \(path)")
            return path
        } catch {
            print("Failed to save CSV: \(error)")
            return nil
        }
    }
    
    private func sendEmailWithAttachment(to email: String, filePath: String) {
        guard MFMailComposeViewController.canSendMail() else {
            print("Cannot send mail")
            return
        }
        
        let composeVC = MFMailComposeViewController()
        composeVC.mailComposeDelegate = self
        
        composeVC.setToRecipients([email])
        composeVC.setSubject("Data")
        composeVC.setMessageBody("Please find attached the data CSV file.", isHTML: false)
        
        if let attachmentData = try? Data(contentsOf: URL(fileURLWithPath: filePath)) {
            composeVC.addAttachmentData(attachmentData, mimeType: "text/csv", fileName: "data.csv")
        }
        
        if let rootVC = UIApplication.shared.windows.first?.rootViewController {
            rootVC.present(composeVC, animated: true, completion: nil)
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}
