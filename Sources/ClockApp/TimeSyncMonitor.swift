import ClockCore
import Foundation
import Observation

/// 時刻サーバーへの問い合わせを定期的に行い、フッターに出す状態を保持する。
@MainActor
@Observable
final class TimeSyncMonitor {
    private(set) var status: TimeSyncStatus = .unknown

    @ObservationIgnored private let client: SNTPClient
    @ObservationIgnored private let interval: TimeInterval
    @ObservationIgnored private var isChecking = false

    init(client: SNTPClient = SNTPClient(), interval: TimeInterval = 15 * 60) {
        self.client = client
        self.interval = interval
    }

    /// 起動直後に 1 回、以降は `interval` ごとに確認し続ける。
    func run() async {
        while !Task.isCancelled {
            await refresh()
            try? await Task.sleep(for: .seconds(interval))
        }
    }

    /// 手動での再確認。フッターの表示をクリックしたときに呼ぶ。
    func refresh() async {
        guard !isChecking else { return }
        isChecking = true
        defer { isChecking = false }

        status = .checking
        do {
            status = TimeSyncStatus.from(try await client.measure())
        } catch let error as SNTPError {
            status = .failed(reason: error.message)
        } catch {
            status = .failed(reason: error.localizedDescription)
        }
    }
}
