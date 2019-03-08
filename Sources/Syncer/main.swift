import Dispatch
import Foundation

var args = CommandLine.arguments

if (args.contains("--help") || args.contains("-h")) {
    print("Syncer <destination_host> <path>")
    print("Built from https://github.com/Yasumoto/Syncer")
    exit(1)
}

guard args.count == 3, let path = args.popLast(), let hostname = args.popLast() else {
    print("Please specify a target host and file's path to watch")
    exit(1)
}

let format = DateFormatter()
format.dateFormat = "MM-dd-yyyy HH:mm:ss"

let trigger = DispatchWorkItem {
    let start = Date()
    print("[\(format.string(from: start))] Starting sync")
    let task = Process()
    task.launchPath = "/usr/bin/rsync"
    task.arguments = ["-a", path, "\(hostname):"]
    let stdout = Pipe()
    let stderr = Pipe()
    task.standardOutput = stdout
    task.standardInput = FileHandle.standardInput
    task.standardError = stderr
    task.launch()
    task.waitUntilExit()
    let done = Date()
    print("[\(format.string(from: done))] Finished syncing \(path)")
}

guard let watcher = try? Watcher(path: path, trigger: trigger) else {
    print("Could not watch: \(path)")
    exit(1)
}

print("Watching \(path)")
RunLoop.current.run()
