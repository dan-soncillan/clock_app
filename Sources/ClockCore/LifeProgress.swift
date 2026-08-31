import Foundation

/// 生まれてから目標年齢の誕生日までのうち、どれだけ残っているか。
///
/// 「今日の残り」「今年の残り」と同じ考え方で、塗りが残りを表すバー用の値を出す。
public struct LifeProgress: Equatable, Sendable {
    /// 目標年齢（例: 80）。
    public var targetAge: Int
    /// 現在の年齢（暦どおり。誕生日が来ていない年は 1 引く）。
    public var age: Int
    /// 目標年齢の誕生日までの残り年数。到達後は 0。
    public var yearsRemaining: Int
    /// 目標年齢の誕生日までの残り日数（切り捨て）。到達後は 0。
    public var daysRemaining: Int
    /// バーの塗り幅（0...1）。
    public var remainingFraction: Double

    /// 残りの表示文字列（例: `47Y 16,996D`）。
    public var remainingText: String {
        let days = daysRemaining.formatted(.number.grouping(.automatic))
        return "\(yearsRemaining)Y \(days)D"
    }

    /// 目盛り。4 等分した位置に置く値を左から返す（例: `[80, 60, 40, 20, 0]`）。
    public var axisMilestones: [Int] {
        stride(from: 4, through: 0, by: -1).map { step in
            Int((Double(targetAge) * Double(step) / 4).rounded())
        }
    }

    /// - Parameters:
    ///   - date: 現在時刻。
    ///   - birthday: 生年月日（`year` / `month` / `day` を使う）。
    ///   - targetAge: 目標年齢。
    ///   - timeZone: 暦の計算に使うタイムゾーン。
    public init(
        date: Date,
        birthday: DateComponents,
        targetAge: Int,
        timeZone: TimeZone = .current
    ) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        self.targetAge = targetAge

        var birthComponents = DateComponents()
        birthComponents.timeZone = timeZone
        birthComponents.year = birthday.year
        birthComponents.month = birthday.month
        birthComponents.day = birthday.day

        var endComponents = birthComponents
        endComponents.year = (birthday.year ?? 0) + targetAge

        guard let birth = calendar.date(from: birthComponents),
              let end = calendar.date(from: endComponents),
              end > birth
        else {
            age = 0
            yearsRemaining = 0
            daysRemaining = 0
            remainingFraction = 0
            return
        }

        age = max(0, calendar.dateComponents([.year], from: birth, to: date).year ?? 0)
        yearsRemaining = max(0, targetAge - age)

        let remaining = max(0, end.timeIntervalSince(date))
        daysRemaining = Int(remaining / 86_400)
        remainingFraction = remaining / end.timeIntervalSince(birth)
    }
}
