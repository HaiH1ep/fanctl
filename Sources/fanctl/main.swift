import Foundation
import SMCKit

// MARK: - Global state for signal handling

var shouldExit: sig_atomic_t = 0

private func installSignalHandler() {
    signal(SIGINT) { _ in
        shouldExit = 1
    }
}

// MARK: - Main

installSignalHandler()

let args = Array(CommandLine.arguments.dropFirst())
let command = args.first ?? "status"

switch command {
case "status", "s":
    statusCommand()

case "set":
    guard args.count >= 3,
          let fanIndex = Int(args[1]),
          let rpm = Float(args[2]) else {
        printError("Usage: fanctl set <fan-index> <rpm>")
        printError("Example: sudo fanctl set 0 2000")
        exit(1)
    }
    setCommand(fanIndex: fanIndex, rpm: rpm)

case "reset", "r":
    resetCommand()

case "monitor", "m":
    let interval: TimeInterval
    if args.count >= 2, let val = Double(args[1]) {
        interval = val
    } else {
        interval = 2.0
    }
    monitorCommand(interval: interval)

case "--help", "-h", "help":
    printUsage()

default:
    printError("Unknown command: \(command)")
    printUsage()
    exit(1)
}
