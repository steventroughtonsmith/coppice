#!/usr/bin/env xcrun swift

import Foundation

func main() -> Int {
    print("Updating Build Number")
    do {
        let path = try buildNumberPath()
        let buildNumberString = try getBuildNumber(from: path)
        guard let buildNumber = Int(buildNumberString) else {
            print("Error: build number is not an integer")
            return -1
        }
        try writeBuildNumber(buildNumber + 1, to: path)
    } catch let e {
        print("Error: \(e)")
        return -1
    }
    return 0
}

func buildNumberPath() throws -> String {
    let arguments = CommandLine.arguments
    guard let buildNumberIndex = arguments.firstIndex(where: {$0 == "--build-number" }), (arguments.count > buildNumberIndex + 1) else {
        throw NSError(domain: "com.mcubedsw.script", code: -1, userInfo: [NSLocalizedDescriptionKey: "--build-number argument not provided"])
    }
    return arguments[buildNumberIndex + 1]
}

func getBuildNumber(from path: String) throws -> String {
    let number = try String(contentsOfFile: path)
    return number.trimmingCharacters(in: .whitespacesAndNewlines)
}

func writeBuildNumber(_ number: Int, to path: String) throws {
    try "\(number)\n".write(toFile: path, atomically: true, encoding: .utf8)
}

print("\(main())")
