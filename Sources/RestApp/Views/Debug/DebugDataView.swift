import SwiftUI

struct DebugDataView: View {
    @ObservedObject var vm: FocusViewModel
    var textPrimary: Color
    var textSecondary: Color
    var inactiveBlock: Color
    
    @State private var selectedHour: Int? = nil
    
    private var selectedDayData: DailyActivityData? {
        vm.getDailyData(for: vm.selectedDate)
    }
    
    private var hourlyData: [Int] {
        selectedDayData?.hourlyActivity ?? Array(repeating: 0, count: 24)
    }
    
    private var currentHour: Int {
        Calendar.current.component(.hour, from: Date())
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(vm.selectedDate)
    }
    
    // Compute earliest date with activity data
    private var earliestAvailableDate: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dates = vm.dailyActivities.keys.compactMap { formatter.date(from: $0) }
        return dates.min()
    }

    // Get hours that have minute history data
    private var hoursWithData: [Int] {
        guard let history = selectedDayData?.minuteHistory else { return [] }
        return history.keys.sorted()
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                
                // Date Selector
                DateSelector(
                    selectedDate: $vm.selectedDate,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    inactiveBlock: inactiveBlock,
                    earliestDate: earliestAvailableDate
                )
                .padding(.horizontal, 25)
                .padding(.top, 4)
                
                Divider()
                    .background(textSecondary.opacity(0.3))
                    .padding(.horizontal, 20)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("当前状态")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(textSecondary)
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            InfoRow(label: "工作时间", value: vm.formattedTime, color: textPrimary)
                            InfoRow(label: "当前小时", value: "\(currentHour)", color: textPrimary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        VStack(alignment: .leading, spacing: 6) {
                            InfoRow(label: "状态", value: "\(vm.appState)", color: textPrimary)
                            InfoRow(label: "当前分钟", value: "\(Calendar.current.component(.minute, from: Date()))", color: textPrimary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 20)
                
                Divider()
                    .background(textSecondary.opacity(0.3))
                    .padding(.horizontal, 20)
                
                // Hourly Data
                VStack(alignment: .leading, spacing: 6) {
                    Text("小时活跃数据 (秒) - 点击查看分钟详情")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(textSecondary)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 6), spacing: 4) {
                        ForEach(0..<24, id: \.self) { hour in
                            VStack(spacing: 2) {
                                Text(String(format: "%02d", hour))
                                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                                    .foregroundColor(textSecondary.opacity(0.6))
                                
                                Text("\(hourlyData[hour])")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(hourlyData[hour] > 0 ? Color.green : textSecondary.opacity(0.3))
                            }
                            .padding(.vertical, 4)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(selectedHour == hour ? Color.blue.opacity(0.3) : 
                                          (hourlyData[hour] > 0 ? Color.green.opacity(0.1) : inactiveBlock.opacity(0.3)))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(selectedHour == hour ? Color.blue : Color.clear, lineWidth: 2)
                            )
                            .onTapGesture {
                                withAnimation {
                                    selectedHour = (selectedHour == hour) ? nil : hour
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                // Minute Activity for Selected Hour
                if let hour = selectedHour {
                    Divider()
                        .background(textSecondary.opacity(0.3))
                        .padding(.horizontal, 20)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("分钟活跃数据 (\(String(format: "%02d:00 - %02d:00", hour, (hour + 1) % 24)))")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(textSecondary)
                            
                            if hour == currentHour && isToday {
                                Text("实时")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.green)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(Color.green.opacity(0.15))
                                    .cornerRadius(3)
                            } else {
                                Text("历史")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.orange)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(Color.orange.opacity(0.15))
                                    .cornerRadius(3)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                withAnimation {
                                    selectedHour = nil
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(textSecondary.opacity(0.5))
                            }
                            .buttonStyle(.plain)
                        }
                        
                        let minuteData = vm.getMinuteHistory(for: hour)
                        let totalSeconds = minuteData.reduce(0, +)
                        
                        Text("总计: \(totalSeconds) 秒 (\(totalSeconds / 60) 分钟)")
                            .font(.system(size: 10))
                            .foregroundColor(textSecondary.opacity(0.7))
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 10), spacing: 2) {
                            ForEach(0..<60, id: \.self) { minute in
                                let seconds = minuteData[minute]
                                VStack(spacing: 1) {
                                    Text("\(minute)")
                                        .font(.system(size: 7, design: .monospaced))
                                        .foregroundColor(textSecondary.opacity(0.4))
                                    Text("\(seconds)")
                                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                                        .foregroundColor(seconds > 0 ? Color.blue : textSecondary.opacity(0.3))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(seconds > 0 ? Color.blue.opacity(0.2) : inactiveBlock.opacity(0.2))
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer(minLength: 20)
            }
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(color.opacity(0.6))
            Text(value)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(color)
        }
    }
}

