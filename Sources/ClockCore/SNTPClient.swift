import Foundation
import Network

public enum SNTPError: Error, Equatable {
    case timedOut
    case connectionFailed(String)
    case invalidResponse
    /// Kiss-o'-Death。サーバーが問い合わせを拒否した。
    case serverRejected

    /// 表示用の短い説明。`Error.localizedDescription` とは別に持つ。
    public var message: String {
        switch self {
        case .timedOut: return "応答なし"
        case .connectionFailed(let reason): return "接続失敗: \(reason)"
        case .invalidResponse: return "不正な応答"
        case .serverRejected: return "サーバーが拒否"
        }
    }
}

/// 時刻サーバーに 1 回問い合わせて、こちらの時計とのずれを測る SNTP クライアント。
///
/// 時計を合わせに行くわけではない（それは OS の仕事）。あくまで
/// 「今この Mac の時計が合っているか」を確認するためだけに使う。
public actor SNTPClient {
    private let host: String
    private let port: UInt16
    private let timeout: TimeInterval
    private let queue = DispatchQueue(label: "clock.sntp")

    public init(host: String = "time.apple.com", port: UInt16 = 123, timeout: TimeInterval = 5) {
        self.host = host
        self.port = port
        self.timeout = timeout
    }

    public func measure() async throws -> NTPMeasurement {
        guard let port = NWEndpoint.Port(rawValue: port) else {
            throw SNTPError.connectionFailed("ポート番号が不正")
        }
        let connection = NWConnection(host: NWEndpoint.Host(host), port: port, using: .udp)
        defer { connection.cancel() }

        return try await withTimeout(timeout) { [queue] in
            try await Self.start(connection, on: queue)

            let sentAt = Date()
            let request = NTPPacket.clientRequest(transmit: NTPTimestamp(date: sentAt))
            try await Self.send(request, on: connection)

            let data = try await Self.receive(on: connection)
            let receivedAt = Date()

            guard let packet = NTPPacket(data: data) else { throw SNTPError.invalidResponse }
            guard packet.stratum != 0 else { throw SNTPError.serverRejected }
            guard packet.mode == NTPPacket.serverMode,
                  !packet.transmit.isZero,
                  // 送った時刻がそのまま返ってこない応答は、取り違えか偽装なので捨てる。
                  packet.originate == NTPTimestamp(date: sentAt)
            else {
                throw SNTPError.invalidResponse
            }

            return NTPMeasurement(
                originate: sentAt,
                receive: packet.receive.date,
                transmit: packet.transmit.date,
                destination: receivedAt
            )
        }
    }

    // MARK: - NWConnection の async ラッパー

    private static func start(_ connection: NWConnection, on queue: DispatchQueue) async throws {
        try await withCheckedThrowingContinuation { continuation in
            let box = ContinuationBox(continuation)
            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    box.resume(.success(()))
                case .failed(let error):
                    box.resume(.failure(SNTPError.connectionFailed(error.localizedDescription)))
                case .cancelled:
                    box.resume(.failure(SNTPError.connectionFailed("接続が閉じられた")))
                default:
                    break
                }
            }
            // ハンドラを付けてから開始する。逆にすると .ready を取り逃す。
            connection.start(queue: queue)
        }
    }

    private static func send(_ data: Data, on connection: NWConnection) async throws {
        try await withCheckedThrowingContinuation { continuation in
            let box = ContinuationBox(continuation)
            connection.send(content: data, completion: .contentProcessed { error in
                if let error {
                    box.resume(.failure(SNTPError.connectionFailed(error.localizedDescription)))
                } else {
                    box.resume(.success(()))
                }
            })
        }
    }

    private static func receive(on connection: NWConnection) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            let box = ContinuationBox(continuation)
            connection.receiveMessage { data, _, _, error in
                if let error {
                    box.resume(.failure(SNTPError.connectionFailed(error.localizedDescription)))
                } else if let data {
                    box.resume(.success(data))
                } else {
                    box.resume(.failure(SNTPError.invalidResponse))
                }
            }
        }
    }

    private func withTimeout<T: Sendable>(
        _ seconds: TimeInterval,
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask { try await operation() }
            group.addTask {
                try await Task.sleep(for: .seconds(seconds))
                throw SNTPError.timedOut
            }
            defer { group.cancelAll() }
            guard let result = try await group.next() else { throw SNTPError.timedOut }
            return result
        }
    }
}

/// コールバックが複数回呼ばれても continuation を 1 回しか再開しないようにする箱。
/// NWConnection の状態ハンドラは .ready のあとに .failed / .cancelled も流してくる。
private final class ContinuationBox<T>: @unchecked Sendable {
    private var continuation: CheckedContinuation<T, Error>?
    private let lock = NSLock()

    init(_ continuation: CheckedContinuation<T, Error>) {
        self.continuation = continuation
    }

    func resume(_ result: Result<T, Error>) {
        lock.lock()
        let pending = continuation
        continuation = nil
        lock.unlock()
        pending?.resume(with: result)
    }
}
