import Foundation

struct SpotlightFile {
    let name: String
    let url: URL
}

final class SpotlightService {
    private let queue = DispatchQueue(label: "local.swoop.spotlight", qos: .userInitiated)
    private var generation = 0

    func search(query: String, limit: Int = 12, completion: @escaping ([SpotlightFile]) -> Void) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            DispatchQueue.main.async { completion([]) }
            return
        }

        generation += 1
        let token = generation
        queue.async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/mdfind")
            process.arguments = ["-onlyin", NSHomeDirectory(), "-name", trimmed]
            let output = Pipe()
            process.standardOutput = output
            process.standardError = Pipe()
            do {
                try process.run()
            } catch {
                self.finish(token: token, files: [], completion: completion)
                return
            }

            let data = output.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            let text = String(data: data, encoding: .utf8) ?? ""
            let files = text.split(separator: "\n").compactMap { line -> SpotlightFile? in
                let path = String(line)
                guard !path.isEmpty else { return nil }
                let url = URL(fileURLWithPath: path)
                let hidden = url.pathComponents.contains { $0.hasPrefix(".") }
                if hidden { return nil }
                return SpotlightFile(name: url.lastPathComponent, url: url)
            }
            .prefix(limit)
            self.finish(token: token, files: Array(files), completion: completion)
        }
    }

    private func finish(token: Int, files: [SpotlightFile], completion: @escaping ([SpotlightFile]) -> Void) {
        DispatchQueue.main.async {
            guard token == self.generation else { return }
            completion(files)
        }
    }
}
