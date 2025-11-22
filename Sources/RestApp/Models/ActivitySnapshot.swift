import Foundation

struct ActivitySnapshot: Codable {
    let minuteActivity: [Int]
    let workTime: Int
    let lastTickHour: Int
    let fatigueHeat: [Double]
    
    init(minuteActivity: [Int], workTime: Int, lastTickHour: Int, fatigueHeat: [Double]) {
        self.minuteActivity = minuteActivity
        self.workTime = workTime
        self.lastTickHour = lastTickHour
        self.fatigueHeat = fatigueHeat.count == 60 ? fatigueHeat : Array(repeating: 0, count: 60)
    }
    
    enum CodingKeys: String, CodingKey {
        case minuteActivity, workTime, lastTickHour, fatigueHeat
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        minuteActivity = try container.decodeIfPresent([Int].self, forKey: .minuteActivity) ?? Array(repeating: 0, count: 60)
        workTime = try container.decodeIfPresent(Int.self, forKey: .workTime) ?? 0
        lastTickHour = try container.decodeIfPresent(Int.self, forKey: .lastTickHour) ?? Calendar.current.component(.hour, from: Date())
        fatigueHeat = try container.decodeIfPresent([Double].self, forKey: .fatigueHeat) ?? Array(repeating: 0, count: 60)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(minuteActivity, forKey: .minuteActivity)
        try container.encode(workTime, forKey: .workTime)
        try container.encode(lastTickHour, forKey: .lastTickHour)
        try container.encode(fatigueHeat, forKey: .fatigueHeat)
    }
}
