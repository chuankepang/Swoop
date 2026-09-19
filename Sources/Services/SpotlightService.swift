import Foundation

struct SpotlightFile: Equatable {
    let name: String
    let url: URL
}

final class SpotlightService {
    private let queue = DispatchQueue(label: "local.swoop.spotlight", qos: .userInitiated)
    private let lock = NSLock()
    private var generation = 0

    func search(query: String, limit: Int = 16, completion: @escaping ([SpotlightFile]) -> Void) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            DispatchQueue.main.async { completion([]) }
            return
        }

        lock.lock()
        generation += 1
        let token = generation
        lock.unlock()

        let predicate = Self.filenamePredicate(trimmed)
        DebugLog.fileSearch("Starting Spotlight query: \(predicate)")

        queue.async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/mdfind")
            process.arguments = ["-onlyin", NSHomeDirectory(), predicate]
            let output = Pipe()
            let errors = Pipe()
            process.standardOutput = output
            process.standardError = errors
            do {
                try process.run()
            } catch {
                DebugLog.fileSearch("Process error: \(error.localizedDescription)")
                self.finish(token: token, files: [], completion: completion)
                return
            }

            let data = output.fileHandleForReading.readDataToEndOfFile()
            let errData = errors.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            if let err = String(data: errData, encoding: .utf8), !err.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                DebugLog.fileSearch("stderr: \(err)")
            }
            DebugLog.fileSearch("exit status: \(process.terminationStatus)")
            let text = String(data: data, encoding: .utf8) ?? ""
            let lines = text.split(whereSeparator: \.isNewline)
            DebugLog.fileSearch("Raw result count: \(lines.count)")
            let files = lines.compactMap { line -> SpotlightFile? in
                let path = String(line)
                guard !path.isEmpty else { return nil }
                let url = URL(fileURLWithPath: path)
                return SpotlightFile(name: url.lastPathComponent, url: url)
            }
            .prefix(limit)
            DebugLog.fileSearch("Parsed result count: \(files.count)")
            self.finish(token: token, files: Array(files), completion: completion)
        }
    }

    static func filenamePredicate(_ query: String) -> String {
        let escaped = query
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return "kMDItemFSName == \"*\(escaped)*\"cd"
    }

    private func finish(token: Int, files: [SpotlightFile], completion: @escaping ([SpotlightFile]) -> Void) {
        DispatchQueue.main.async {
            self.lock.lock()
            let current = self.generation
            self.lock.unlock()
            guard token == current else {
                DebugLog.fileSearch("Dropping stale results token=\(token) current=\(current)")
                return
            }
            completion(files)
        }
    }
}
