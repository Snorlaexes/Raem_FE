import SwiftUI

struct RecordView: View {
    @ObservedObject var items = Items()
    @State private var selectedDate = Date() // Date 타입으로 시간을 관리
    
    var body: some View {
        NavigationView {
            VStack {
                // 종료 시간 설정
                DatePicker("End Time", selection: $selectedDate, displayedComponents: .hourAndMinute)
                    .padding()
                    .onChange(of: selectedDate) { newDate in
                        // Date를 String으로 변환하여 items.endTime에 저장
                        let formatter = DateFormatter()
                        formatter.dateFormat = "HH:mm"
                        items.endTime = formatter.string(from: newDate)
                        items.sendEndTimeToWatch()
                    }

                Button(action: {
                    exportToCSV()
                }) {
                    Text("Export to CSV")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(8)
                }
                .padding()

                List(items.records, id: \.self) { record in
                    Text(record)
                        .foregroundColor(.white)
                        .padding(.vertical, 5)
                }
                .navigationBarTitle("Records", displayMode: .inline)
                .background(Color.black)
            }
            .onAppear {
                startDataRefreshTimer() // 타이머 시작
            }
        }
        .background(Color.black)
    }

    private func startDataRefreshTimer() {
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            items.records = items.records
        }
    }
    
    private func exportToCSV() {
        let fileName = "records.csv"
        let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        
        var csvText = "Date, Heart Rate, Accelerometer, Decibels\n"
        
        for record in items.records {
            csvText += "\(record)\n"
        }
        
        do {
            try csvText.write(to: path!, atomically: true, encoding: String.Encoding.utf8)
            shareCSV(path: path!)
        } catch {
            print("Failed to create file")
            print("\(error)")
        }
    }
    
    private func shareCSV(path: URL) {
        let activityViewController = UIActivityViewController(activityItems: [path], applicationActivities: nil)
        
        if let topController = UIApplication.shared.windows.first?.rootViewController {
            topController.present(activityViewController, animated: true, completion: nil)
        }
    }
}

struct RecordsView_Previews: PreviewProvider {
    static var previews: some View {
        RecordView()
    }
}
