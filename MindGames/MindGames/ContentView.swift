import SwiftUI
import Foundation

// MARK: - Home Screen

struct HomeScreenView: View {
    @StateObject var brainwaveVM = BrainwaveViewModel()
    @State private var showEscapeVR = false
    @State private var showSOSConfirmation = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Daily History at the top
                DailyHistoryView()
                
                // Mood Overview based on average brainwave data
                MoodOverviewView(mood: brainwaveVM.mood, emoji: brainwaveVM.moodEmoji)
                
                // Brainwave Activity display (bar graphs) that update continuously
                BrainwaveActivityView(brainwaveData: brainwaveVM.brainwaveData)
                
                Spacer()
                
                // Large centered ESCAPE button (VR feature stub)
                Button(action: {
                    showEscapeVR = true
                }) {
                    Text("ESCAPE")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 100)
                        .background(Color.blue)
                        .cornerRadius(20)
                        .padding(.horizontal)
                }
                .sheet(isPresented: $showEscapeVR) {
                    VREscapePlaceholderView()
                }
                
                // SOS button at bottom with confirmation alert
                Button(action: {
                    showSOSConfirmation = true
                }) {
                    Text("SOS")
                        .font(.title)
                        .bold()
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 60)
                        .background(Color.red)
                        .cornerRadius(20)
                        .padding(.horizontal)
                }
                .alert(isPresented: $showSOSConfirmation) {
                    Alert(
                        title: Text("Confirm SOS"),
                        message: Text("Are you sure you want to send an SOS alert?"),
                        primaryButton: .destructive(Text("Send Alert"), action: {
                            print("SOS Alert sent!")
                        }),
                        secondaryButton: .cancel()
                    )
                }
            }
            .navigationBarTitle("Mindful Escape", displayMode: .inline)
            .onAppear {
                brainwaveVM.fetchBrainwaveDataAndAnalyzePatterns()
            }
        }
    }
}

// MARK: - VR Escape Placeholder

struct VREscapePlaceholderView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("VR Escape Experience")
                .font(.largeTitle)
                .bold()
            Text("Where do you want to go?\n(Feature coming soon)")
                .multilineTextAlignment(.center)
                .padding()
            Button("Return Home") {
                dismiss()
            }
            .font(.headline)
            .padding()
            .background(Color.blue.opacity(0.8))
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
    }
}

// MARK: - Brainwave Data Model

struct BrainwaveData {
    var alpha: Double = 0.0
    var beta: Double = 0.0
    var theta: Double = 0.0
    var delta: Double = 0.0
    var gamma: Double = 0.0

    func value(for wave: String) -> Double {
        switch wave {
        case "Alpha": return alpha
        case "Beta": return beta
        case "Theta": return theta
        case "Delta": return delta
        case "Gamma": return gamma
        default: return 0.0
        }
    }
}

// Each CSV row becomes a BrainwavePoint.
struct BrainwavePoint: Identifiable {
    let id = UUID()
    let timestamp: Double
    let delta: Double
    let theta: Double
    let alpha: Double
    let beta: Double
    let gamma: Double
}

// MARK: - View Model for Brainwave Data, Mood Analysis & Continuous Updates

class BrainwaveViewModel: ObservableObject {
    @Published var brainwaveData = BrainwaveData()
    @Published var mood: String = "Neutral"
    @Published var moodEmoji: String = "😐"
    
    // All data points parsed from the CSVs.
    @Published var allBrainwavePoints: [BrainwavePoint] = []
    
    // Holds the final pattern summary from Llama (optional).
    @Published var patternSummary: String = ""
    
    // Timer to update display continuously.
    var timer: Timer?
    var currentPointIndex = 0
    
    /// Fetches CSV files from Pinata using different CIDs, parses all rows,
    /// and then sends the CSV content to Llama for pattern analysis in 3-second chunks.
    func fetchBrainwaveDataAndAnalyzePatterns() {
        // Each CSV file is pinned individually.
        let cids = [
            "bafybeihqztclrpb7fquiieuroekmsxmlqqasz4n3qieikrashalbof75a4",  // File 0
            "bafybeih5o5u5tc56g5wfo7vwe3d2ouad7lkgmf4t3wgffbfehiijarzmmm",  // File 1
            "bafybeibbvtojt6y3c4xldijyak25qbut2l7zqojji37542l2nx2th7dqlu",  // File 2
            "bafybeifutyztz6juicmi5qubj3p7mmiirdc5dpt6rchst4gqni3vhrgaiy"   // File 3
        ]
        
        var aggregatedData = [BrainwaveData]()
        var csvContents = [String]()
        var allPoints: [BrainwavePoint] = []
        let group = DispatchGroup()
        
        for cid in cids {
            group.enter()
            let urlString = "https://gateway.pinata.cloud/ipfs/\(cid)"
            guard let url = URL(string: urlString) else {
                print("Invalid URL: \(urlString)")
                group.leave()
                continue
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("text/csv", forHTTPHeaderField: "Accept")
            request.setValue("Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySW5mb3JtYXRpb24iOnsiaWQiOiIzMTIwZjhjYy0yN2Y4LTQyZDEtODJjYi00YWI2YjgwYjc4OTgiLCJlbWFpbCI6InByYWduYXNyaS52ZWxsYW5raUBnbWFpbC5jb20iLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwicGluX3BvbGljeSI6eyJyZWdpb25zIjpbeyJkZXNpcmVkUmVwbGljYXRpb25Db3VudCI6MSwiaWQiOiJGUkExIn0seyJkZXNpcmVkUmVwbGljYXRpb25Db3VudCI6MSwiaWQiOiJOWUMxIn1dLCJ2ZXJzaW9uIjoxfSwibWZhX2VuYWJsZWQiOmZhbHNlLCJzdGF0dXMiOiJBQ1RJVkUifSwiYXV0aGVudGljYXRpb25UeXBlIjoic2NvcGVkS2V5Iiwic2NvcGVkS2V5S2V5IjoiZDk1YTA1NzMyOGFmNWZkNDExYzkiLCJzY29wZWRLZXlTZWNyZXQiOiJlZTE0MGNhMWY2MjU4M2Q0YmM0NzZhOWNmYWE0MzY5ZmQ4NzJkOWExNzM3MTM3YzZhMzZjZTEwOGNlMmVjZjJjIiwiZXhwIjoxNzYzMzU2MTI5fQ.z-Qk2smN0UTYHAduDXuZxnL6Fl3WmSR8Ig_9OWjBu0M", forHTTPHeaderField: "Authorization")
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                defer { group.leave() }
                
                if let error = error {
                    print("Error fetching file for CID \(cid): \(error.localizedDescription)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("Status code for CID \(cid): \(httpResponse.statusCode)")
                }
                
                guard let data = data,
                      let csvString = String(data: data, encoding: .utf8) else {
                    print("Failed to convert data to string for CID \(cid)")
                    return
                }
                
                print("Fetched CSV for CID \(cid):\n\(csvString)")
                csvContents.append(csvString)
                
                // Parse CSV into points.
                let points = self.parseCSVToPoints(csvString: csvString)
                allPoints.append(contentsOf: points)
                
                // Compute average for mood analysis from these points.
                let avgData = self.averageBrainwaveData(from: points)
                aggregatedData.append(avgData)
                
            }.resume()
        }
        
        group.notify(queue: .main) {
            if !aggregatedData.isEmpty {
                let count = Double(aggregatedData.count)
                let avgAlpha = aggregatedData.map { $0.alpha }.reduce(0, +) / count
                let avgBeta = aggregatedData.map { $0.beta }.reduce(0, +) / count
                let avgTheta = aggregatedData.map { $0.theta }.reduce(0, +) / count
                let avgDelta = aggregatedData.map { $0.delta }.reduce(0, +) / count
                let avgGamma = aggregatedData.map { $0.gamma }.reduce(0, +) / count
                
                self.brainwaveData = BrainwaveData(alpha: avgAlpha,
                                                   beta: avgBeta,
                                                   theta: avgTheta,
                                                   delta: avgDelta,
                                                   gamma: avgGamma)
                self.analyzeMood()
            }
            
            self.allBrainwavePoints = allPoints.sorted { $0.timestamp < $1.timestamp }
            
            // Process CSV contents in chunks (each covering 3 seconds).
            self.analyzePatternsWithLlama(csvContents: csvContents)
            
            // Start continuous updates.
            self.startContinuousUpdates()
        }
    }
    
    /// Parses the entire CSV into an array of BrainwavePoint.
    /// Expected CSV format: timestamps,Delta,Theta,Alpha,Beta,Gamma
    func parseCSVToPoints(csvString: String) -> [BrainwavePoint] {
        var points: [BrainwavePoint] = []
        let lines = csvString.components(separatedBy: "\n").filter { !$0.isEmpty }
        let dataLines = lines.dropFirst() // Skip header
        
        for line in dataLines {
            let values = line.components(separatedBy: ",")
            if values.count >= 6,
               let timestamp = Double(values[0]),
               let delta = Double(values[1]),
               let theta = Double(values[2]),
               let alpha = Double(values[3]),
               let beta = Double(values[4]),
               let gamma = Double(values[5]) {
                let point = BrainwavePoint(timestamp: timestamp,
                                             delta: delta,
                                             theta: theta,
                                             alpha: alpha,
                                             beta: beta,
                                             gamma: gamma)
                points.append(point)
            }
        }
        return points
    }
    
    /// Computes the average BrainwaveData from an array of points.
    func averageBrainwaveData(from points: [BrainwavePoint]) -> BrainwaveData {
        guard !points.isEmpty else { return BrainwaveData() }
        let count = Double(points.count)
        let avgDelta = points.map { $0.delta }.reduce(0, +) / count
        let avgTheta = points.map { $0.theta }.reduce(0, +) / count
        let avgAlpha = points.map { $0.alpha }.reduce(0, +) / count
        let avgBeta = points.map { $0.beta }.reduce(0, +) / count
        let avgGamma = points.map { $0.gamma }.reduce(0, +) / count
        
        return BrainwaveData(alpha: avgAlpha,
                             beta: avgBeta,
                             theta: avgTheta,
                             delta: avgDelta,
                             gamma: avgGamma)
    }
    
    /// Determines mood based on overall averaged brainwave data.
    func analyzeMood() {
        let data = brainwaveData
        if data.theta > 1.0 && data.alpha < 0.5 {
            mood = "Sad"
            moodEmoji = "😔"
        } else if data.theta > 1.0 && data.alpha > 1.0 && data.gamma < 0.5 {
            mood = "Depressed"
            moodEmoji = "😢"
        } else if data.beta > 1.0 && data.alpha < 0.5 && data.delta < 0.5 && data.theta < 0.5 {
            mood = "Stressed"
            moodEmoji = "😟"
        } else if data.alpha < 0.5 && data.beta > 1.0 {
            mood = "Anxious"
            moodEmoji = "😰"
        } else {
            mood = "Calm"
            moodEmoji = "😊"
        }
    }
    
    /// Groups an array of BrainwavePoint into chunks covering a given time interval (in seconds).
    func groupPoints(_ points: [BrainwavePoint], interval: Double) -> [[BrainwavePoint]] {
        var groups: [[BrainwavePoint]] = []
        var currentGroup: [BrainwavePoint] = []
        guard let first = points.first else { return groups }
        var startTime = first.timestamp
        
        for point in points {
            if point.timestamp < startTime + interval {
                currentGroup.append(point)
            } else {
                groups.append(currentGroup)
                currentGroup = [point]
                startTime = point.timestamp
            }
        }
        if !currentGroup.isEmpty {
            groups.append(currentGroup)
        }
        return groups
    }
    
    /// Generates a CSV string from a group of BrainwavePoint.
    func generateCSVChunkText(from points: [BrainwavePoint]) -> String {
        var lines = ["timestamps,Delta,Theta,Alpha,Beta,Gamma"]
        for point in points {
            let line = "\(point.timestamp),\(point.delta),\(point.theta),\(point.alpha),\(point.beta),\(point.gamma)"
            lines.append(line)
        }
        return lines.joined(separator: "\n")
    }
    
    /// Uses Llama to analyze patterns in each CSV file, processing the data in 3-second chunks.
    func analyzePatternsWithLlama(csvContents: [String]) {
        let dispatchGroup = DispatchGroup()
        var patternResponses = [String]()
        
        for csv in csvContents {
            // Parse CSV and group rows into 3-second chunks.
            let points = parseCSVToPoints(csvString: csv)
            let groups = groupPoints(points, interval: 3.0)
            
            for group in groups {
                dispatchGroup.enter()
                let chunkText = generateCSVChunkText(from: group)
                let question = "Analyze the following CSV data representing brainwave frequencies (Delta, Theta, Alpha, Beta, Gamma) for a 3-second interval and describe any patterns or trends you observe."
                LlamaTextAnalysisHandler.getResponse(for: question, text: chunkText) { response in
                    if !response.isEmpty {
                        patternResponses.append(response)
                    }
                    dispatchGroup.leave()
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            let combined = patternResponses.joined(separator: "\n\n")
            self.patternSummary = combined
            print("Combined Pattern Summary:\n\(combined)")
        }
    }
    
    /// Starts a timer to continuously update the displayed brainwaveData from allBrainwavePoints.
    func startContinuousUpdates() {
        guard !allBrainwavePoints.isEmpty else { return }
        currentPointIndex = 0
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if self.allBrainwavePoints.isEmpty { return }
            let point = self.allBrainwavePoints[self.currentPointIndex]
            self.brainwaveData = BrainwaveData(alpha: point.alpha,
                                               beta: point.beta,
                                               theta: point.theta,
                                               delta: point.delta,
                                               gamma: point.gamma)
            self.currentPointIndex = (self.currentPointIndex + 1) % self.allBrainwavePoints.count
        }
    }
}

// MARK: - Llama Text Analysis Handler
// This model is based on your working SuggestionHandler. It sends a full prompt (question plus CSV chunk)
// and returns the text response from the API.
class LlamaTextAnalysisHandler {
    static func getResponse(for question: String, text: String, completion: @escaping (String) -> Void) {
        guard let url = URL(string: "https://api.sambanova.ai/v1/chat/completions") else {
            print("Invalid URL")
            completion("Error: Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer 228b7855-4be3-4d84-8754-49865c5071f4", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let fullPrompt = question + "\n\nData:\n" + text
        let requestBody: [String: Any] = [
            "model": "Meta-Llama-3.1-405B-Instruct",
            "messages": [
                [
                    "role": "user",
                    "content": fullPrompt
                ]
            ]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        } catch {
            print("Error serializing request body: \(error)")
            completion("Error: Failed to serialize request body")
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Request error: \(error)")
                completion("Error: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("No response data")
                completion("Error: No response data")
                return
            }
            
            do {
                // Log the raw response for debugging.
                if let rawResponse = String(data: data, encoding: .utf8) {
                    print("Raw response: \(rawResponse)")
                }
                
                // Attempt to parse using .allowFragments
                let jsonResponse = try JSONSerialization.jsonObject(with: data, options: [.allowFragments])
                if let dict = jsonResponse as? [String: Any],
                   let choices = dict["choices"] as? [[String: Any]],
                   let message = choices.first?["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    completion(content)
                } else {
                    print("Failed to parse 'choices' or extract 'content'")
                    // Fallback: If response is plain text, return that.
                    if let textResponse = String(data: data, encoding: .utf8) {
                        completion(textResponse)
                    } else {
                        completion("Error: Failed to parse response")
                    }
                }
            } catch {
                print("Error decoding JSON: \(error)")
                // Fallback: Try returning the raw text.
                if let textResponse = String(data: data, encoding: .utf8) {
                    completion(textResponse)
                } else {
                    completion("Error decoding response: \(error.localizedDescription)")
                }
            }

        }
        
        task.resume()
    }
}

// MARK: - Brainwave Activity View

struct BrainwaveActivityView: View {
    let brainwaveData: BrainwaveData

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Brainwave Activity")
                .font(.headline)
                .padding(.bottom, 5)
            ForEach(["Alpha", "Beta", "Theta", "Delta", "Gamma"], id: \.self) { wave in
                HStack {
                    Text(wave)
                        .frame(width: 70, alignment: .leading)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                            Rectangle()
                                .fill(Color.green)
                                .frame(width: CGFloat(brainwaveData.value(for: wave)) * geo.size.width / 100.0)
                        }
                    }
                    .frame(height: 20)
                    Text(String(format: "%.2f", brainwaveData.value(for: wave)))
                        .frame(width: 50, alignment: .trailing)
                }
                .frame(height: 20)
            }
        }
        .padding()
    }
}

// MARK: - Daily History (Mood Tracking) View

struct DailyHistoryView: View {
    private let days: [Date] = {
        var dates = [Date]()
        for i in 0..<7 {
            if let date = Calendar.current.date(byAdding: .day, value: -i, to: Date()) {
                dates.append(date)
            }
        }
        return dates.reversed()
    }()
    
    private let moodForDay: [Date: String] = {
        var dict = [Date: String]()
        let calendar = Calendar.current
        let emojis = ["😊", "😐", "😔", "😢", "😰"]
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: Date()) {
                dict[calendar.startOfDay(for: date)] = emojis[i % emojis.count]
            }
        }
        return dict
    }()
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(days, id: \.self) { day in
                    let emoji = moodForDay[Calendar.current.startOfDay(for: day)] ?? "😐"
                    VStack {
                        Text(formattedDate(day))
                            .font(.caption)
                        Text(emoji)
                            .font(.largeTitle)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                }
            }
            .padding(.horizontal)
        }
    }
    
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Mood Overview View

struct MoodOverviewView: View {
    let mood: String
    let emoji: String
    
    var body: some View {
        HStack {
            Text(emoji)
                .font(.largeTitle)
            Text("You are feeling \(mood)")
                .font(.headline)
        }
        .padding()
    }
}
