import Dispatch
import Foundation


func outputLog(_ contents: String) {
    let now = Date()
    let format = DateFormatter()
    format.dateFormat = "MM-dd-yyyy HH:mm:ss"
    print("[\(format.string(from: now))] \(contents)")
}

var args = CommandLine.arguments

if (args.contains("--help") || args.contains("-h")) {
    print("Syncer <destination_host> <remote_path>")
    print("Built from https://github.com/Yasumoto/Syncer")
    exit(1)
}

guard args.count == 3, let remotePath = args.popLast(), let hostname = args.popLast() else {
    print("Please specify your target host and the destination path you want to sync to")
    exit(1)
}

let currentWorkingDirectory = FileManager.default.currentDirectoryPath

let trigger = DispatchWorkItem {
    outputLog("Starting sync to \(hostname)")
    let task = Process()
    task.launchPath = "/usr/bin/rsync"
    task.arguments = ["-a", currentWorkingDirectory, "\(hostname):\(remotePath)"]
    let stdout = Pipe()
    let stderr = Pipe()
    task.standardOutput = stdout
    task.standardInput = FileHandle.standardInput
    task.standardError = stderr
    task.launch()
    task.waitUntilExit()
    if task.terminationStatus != 0,
        let output = String(data: stderr.fileHandleForReading.availableData, encoding: .utf8) {
        outputLog("Error syncing!\n\(output)")
    }
    outputLog("Finished syncing \(currentWorkingDirectory) to \(remotePath)")
}

guard let watcher = try? Watcher(path: currentWorkingDirectory, trigger: trigger) else {
    outputLog("Could not watch: \(currentWorkingDirectory)")
    exit(1)
}

outputLog("Watching \(currentWorkingDirectory)")
RunLoop.current.run()
