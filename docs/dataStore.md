# RestApp 数据存储架构文档

## 概述

RestApp 使用双层 JSON 文件存储系统来追踪用户的活跃时间和休息模式。所有数据持久化到本地文件，无需外部数据库。

## 存储位置

```
~/Library/Application Support/RestApp/
├── activity.json           # 当前会话状态（实时数据）
└── daily_activities.json   # 历史每日数据（永久保存）
```

## 数据结构

### 1. activity.json - 当前会话状态

**用途：** 保存当前小时的分钟级活跃数据，用于主界面的60分钟热力图

**数据模型：** `ActivitySnapshot`

```swift
struct ActivitySnapshot: Codable {
    let minuteActivity: [Int]    // 60个元素，每分钟的活跃秒数
    let workTime: Int            // 当前累计工作时间（秒）
    let lastTickHour: Int        // 上次记录的小时（0-23）
    let fatigueHeat: [Double]    // 60个元素，疲劳热度（0.0-1.0）
}
```

**示例：**
```json
{
  "minuteActivity": [0, 12, 0, 0, 45, 60, 51, ...],
  "workTime": 11,
  "lastTickHour": 22,
  "fatigueHeat": [0, 1, 0, 0, 0, ...]
}
```

**特点：**
- 每小时重置（保留历史前先转存）
- 实时更新（每秒）
- 用于显示当前工作状态

### 2. daily_activities.json - 每日历史数据

**用途：** 永久保存每天24小时的活跃数据，用于数据分析页面

**数据模型：** `DailyActivityData`

```swift
struct DailyActivityData: Codable {
    let dateString: String        // 日期标识 "yyyy-MM-dd"
    var hourlyActivity: [Int]     // 24个元素，每小时的活跃秒数
    var peakHour: Int?           // 高峰时段（0-23）
    var totalActiveTime: Int     // 当日总活跃时间（秒）
}
```

**示例：**
```json
{
  "2025-11-21": {
    "dateString": "2025-11-21",
    "hourlyActivity": [0, 0, 0, ..., 307, 0],
    "peakHour": 22,
    "totalActiveTime": 307
  },
  "2025-11-20": {
    "dateString": "2025-11-20",
    "hourlyActivity": [0, 0, 450, 1200, ...],
    "peakHour": 14,
    "totalActiveTime": 18600
  }
}
```

**特点：**
- 按日期索引（字符串键）
- 永久保存（无自动删除）
- 支持历史回溯

## 数据流程

### 启动流程

```
应用启动
   ↓
loadPersistedConfig()          # 加载用户配置
   ↓
loadPersistedActivity()        # 加载当前会话状态
   ↓
loadDailyActivities()          # 加载所有历史数据
   ↓
initializeTodayData()          # 初始化今天的数据结构
   ├─ 创建 DailyActivityData(今天)
   └─ syncCurrentHourFromMinuteActivity()
   ↓
startLoop()                    # 开始每秒 tick()
```

### 运行时数据追踪

每秒执行 `tick()` 方法：

```
1. 检测屏幕状态（如果关屏则暂停追踪）
   ↓
2. 获取系统空闲时间
   ↓
3. 检查小时是否改变
   如果是 → 保存上一小时数据到 dailyActivities
         → 重置 minuteActivity 数组
   ↓
4. 判断用户是否活跃（基于空闲时间）
   如果活跃 → workTime++
           → minuteActivity[当前分钟]++
           → fatigueHeat[当前分钟] 更新
   ↓
5. 同步当前小时数据
   syncCurrentHourFromMinuteActivity()
   └─ 计算 minuteActivity 总和
   └─ 更新 dailyActivities[今天][当前小时]
   ↓
6. 保存数据（每分钟 + 数据变化时）
   persistActivity()           # 保存 activity.json
   saveDailyActivities()       # 保存 daily_activities.json
```

### 小时边界处理

```
当前小时 ≠ 上次记录小时
   ↓
1. 计算上一小时总活跃秒数
   totalSecondsLastHour = sum(minuteActivity)
   ↓
2. 保存到历史数据
   dailyActivities[今天][上一小时] = totalSecondsLastHour
   ↓
3. 重置数组
   minuteActivity = [0, 0, 0, ..., 0]  (60个0)
   fatigueHeat = [0, 0, 0, ..., 0]
   ↓
4. 更新小时标记
   lastTickHour = 当前小时
```

### 日期边界处理

```
当前日期 ≠ 上次记录日期
   ↓
1. 保存昨天的完整数据
   saveDailyActivities()
   ↓
2. 更新日期字符串
   currentDayString = "2025-11-22"
   ↓
3. 创建新的今天数据
   dailyActivities["2025-11-22"] = DailyActivityData()
```

## 保存策略

### 保存触发条件

```swift
// 每次数据变化时 OR 每分钟的第0秒
if didMutate || Calendar.current.component(.second, from: Date()) == 0 {
    saveDailyActivities()
}
```

### 异步持久化

```swift
private let persistenceQueue = DispatchQueue(
    label: "com.restapp.persistence", 
    qos: .utility
)

persistenceQueue.async {
    // 编码 JSON
    let data = try? JSONEncoder().encode(dailyActivities)
    // 写入文件
    try? data.write(to: dailyURL, options: .atomic)
}
```

**优点：**
- 不阻塞主线程
- 原子写入（.atomic）防止文件损坏
- 低优先级队列（.utility）不影响UI性能

## 数据安全保护机制

### 自动保存触发场景

RestApp 在以下所有场景都会自动保存数据，确保零数据丢失：

#### 1. 正常运行时
- **每秒更新**：`syncCurrentHourFromMinuteActivity()` 同步当前小时数据
- **每分钟保存**：`saveDailyActivities()` 写入文件
- **数据变化时**：`didMutate = true` 时立即保存

#### 2. App 退出
```swift
func applicationWillTerminate(_ notification: Notification) {
    FocusViewModel.shared.saveAllData()
}
```
**场景：** 用户点击菜单栏 "退出" 或按 Cmd+Q

#### 3. 屏幕熄屏
```swift
@objc private func handleScreenSleep() {
    saveAllData()  // 熄屏前保存
    isScreenOff = true
}
```
**场景：** 
- 合上 MacBook 盖子
- 设置的时间到了自动熄屏
- 手动按电源键熄屏

#### 4. 系统休眠
```swift
@objc private func handleSystemSleep() {
    saveAllData()  // 休眠前保存
    isScreenOff = true
}
```
**场景：** 
- macOS 进入休眠模式
- 电池耗尽自动休眠

#### 5. 系统关机
```swift
@objc private func handleSystemPowerOff() {
    saveAllData()  // 关机前保存
}
```
**场景：** 
- 点击 Apple 菜单 → 关机
- 点击 Apple 菜单 → 重新启动
- 强制关机（系统会先发送通知）

### saveAllData() 实现

```swift
func saveAllData() {
    // 1. 同步当前小时数据
    syncCurrentHourFromMinuteActivity()
    
    // 2. 保存两个文件
    persistActivity()        // activity.json
    saveDailyActivities()    // daily_activities.json
    
    // 3. 等待异步队列完成（确保写入磁盘）
    persistenceQueue.sync {}
    
    print("All data saved successfully")
}
```

**特点：**
- ✅ 同步等待写入完成（`persistenceQueue.sync`）
- ✅ 先同步当前数据再保存
- ✅ 双文件都保存
- ✅ 原子写入（`.atomic`）防止文件损坏

### 数据丢失风险分析

| 场景 | 是否保存 | 最大丢失数据量 |
|------|----------|----------------|
| 正常退出 | ✅ 保存 | 0 |
| 熄屏 | ✅ 保存 | 0 |
| 休眠 | ✅ 保存 | 0 |
| 关机/重启 | ✅ 保存 | 0 |
| 正常运行 | ✅ 每分钟 | < 60秒 |
| 应用崩溃 | ❌ 无法保存 | < 60秒 |
| 强制杀进程 | ❌ 无法保存 | < 60秒 |
| 突然断电 | ❌ 无法保存 | < 60秒 |

**结论：** 除了极端异常情况（崩溃、断电），数据完全安全。

## 数据完整性保证

### 1. 无数据丢失
- ✅ 小时切换前先保存再重置
- ✅ 每分钟自动保存
- ✅ 应用崩溃最多丢失1分钟数据

### 2. 永久保存
- ✅ 无30天限制（已移除）
- ✅ 所有历史数据永久保留
- ✅ 手动删除前数据不会丢失

### 3. 格式兼容
- ✅ JSON 编码（人类可读）
- ✅ Codable 协议（类型安全）
- ✅ 向后兼容（可扩展字段）

## 性能评估

### 文件大小
| 时长 | 记录天数 | 文件大小 | 内存占用 |
|------|----------|----------|----------|
| 1个月 | ~30天 | ~6KB | ~10KB |
| 1年 | ~365天 | ~73KB | ~100KB |
| 10年 | ~3650天 | ~730KB | ~1MB |

### 写入频率
- **activity.json**: 每分钟 + 数据变化时
- **daily_activities.json**: 每分钟 + 数据变化时
- **实际磁盘写入**: 每分钟 ~2次（异步）

### 启动加载
- 加载时间: < 10ms（即使10年数据）
- 内存占用: ~1MB（全部加载到内存）

**结论：** JSON 文件方案完全满足性能要求，无需 SQLite

## 数据访问接口

### 读取历史数据

```swift
// 获取指定日期的数据
func getDailyData(for date: Date) -> DailyActivityData? {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    let dateString = formatter.string(from: date)
    return dailyActivities[dateString]
}
```

### 当前状态查询

```swift
// 当前工作时间
vm.workTime  // Int (秒)

// 当前小时活跃分钟
vm.minuteActivity  // [Int] (60个元素)

// 疲劳热度
vm.fatigueHeat  // [Double] (60个元素)

// 应用状态
vm.appState  // .active | .warning | .idle | .paused
```

## 文件操作命令

### 查看数据

```bash
# 格式化查看每日历史数据
python3 -m json.tool ~/Library/Application\ Support/RestApp/daily_activities.json

# 格式化查看当前会话
python3 -m json.tool ~/Library/Application\ Support/RestApp/activity.json

# 查看文件大小
ls -lh ~/Library/Application\ Support/RestApp/
```

### 备份数据

```bash
# 备份所有数据
cp -r ~/Library/Application\ Support/RestApp ~/Desktop/RestApp_Backup_$(date +%Y%m%d)
```

### 清空数据（测试用）

```bash
# 删除所有数据文件
rm ~/Library/Application\ Support/RestApp/*.json

# 或删除整个文件夹
rm -rf ~/Library/Application\ Support/RestApp/
```

## 未来扩展

### 可能的优化方向

1. **数据压缩**
   - 如果文件超过10MB，可考虑 gzip 压缩
   - 压缩率约80%（JSON文本压缩效果好）

2. **数据导出**
   - CSV 导出功能（Excel 分析）
   - 统计报告生成

3. **云同步**
   - iCloud Drive 同步
   - 跨设备数据共享

4. **数据分析**
   - 周/月/年统计
   - 趋势分析
   - 健康建议

### 不推荐的方案

- ❌ **SQLite**: 过度设计，数据量小不需要
- ❌ **Core Data**: 复杂度高，维护成本大
- ❌ **Realm**: 引入第三方依赖，体积大

## 总结

RestApp 的数据存储系统设计简洁高效：

- **双文件分离**：实时状态 + 历史数据
- **每分钟保存**：数据安全有保障
- **永久保存**：完整追踪用户习惯
- **性能优异**：启动快、占用低
- **易于维护**：纯JSON、人类可读

该架构适合长期使用，10年数据仅约730KB，完全满足个人使用需求。
