import Foundation

class ShellCommandService {
    @discardableResult
    func execute(command: String, arguments: [String], timeout: TimeInterval = 30.0) async throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-l", "-c", "source ~/.zshrc 2>/dev/null; source ~/.zprofile 2>/dev/null; source ~/.nvm/nvm.sh 2>/dev/null; \(command) \(arguments.joined(separator: " "))"]

        let outputPipe = Pipe()
        process.standardOutput = outputPipe

        let errorPipe = Pipe()
        process.standardError = errorPipe

        var environment = ProcessInfo.processInfo.environment
        environment["PATH"] = "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/usr/local/opt/node@18/bin"
        process.environment = environment

        do {
            try process.run()
        } catch {
            throw CommandError.notFound(command)
        }

        var didTimeout = false
        let timeoutTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
            if !Task.isCancelled {
                process.terminate()
                didTimeout = true
            }
        }

        process.waitUntilExit()

        timeoutTask.cancel()

        if didTimeout {
            throw CommandError.timeout(command)
        }

        let exitCode = process.terminationStatus
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

        guard let output = String(data: outputData, encoding: .utf8) else {
            throw CommandError.invalidOutput("Could not decode command output")
        }

        if exitCode != 0 {
            let errorOutput = String(data: errorData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            throw CommandError.failed(Int(exitCode), errorOutput.isEmpty ? output : errorOutput)
        }

        return output
    }
}
