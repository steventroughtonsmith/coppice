#!/usr/bin/env xcrun swift

import Foundation

func main() -> Int {
    do {
        try enumerateInput() { (inputString) -> String in
            var string = inputString
            let buildNumber = try getBuildNumber()
            string = string.replacingOccurrences(of: "__BUNDLE_VERSION__", with: buildNumber)

            let gitHash = try getGitHash()
            string = string.replacingOccurrences(of: "__BUNDLE_HASH__", with: gitHash)

            return string
        }
    } catch let e {
        print("Prepare Error: \(e)")
        return -1
    }

    return 0
}

func enumerateInput(_ block: (String) throws -> String) throws {
    let environment = ProcessInfo.processInfo.environment
    guard
        let inputCountString = environment["SCRIPT_INPUT_FILE_COUNT"],
        let inputCount = Int(inputCountString)
    else {
        throw NSError(domain: "com.mcubedsw.script", code: -1, userInfo: [NSLocalizedDescriptionKey: "Input File Count is not an integer"])
    }

    for index in 0..<inputCount {
        guard
            let inputPath = environment["SCRIPT_INPUT_FILE_\(index)"],
            let outputPath = environment["SCRIPT_OUTPUT_FILE_\(index)"]
        else {
            throw NSError(domain: "com.mcubedsw.script", code: -1, userInfo: [NSLocalizedDescriptionKey: "No path for index \(index)"])
        }
        let contents = try String(contentsOfFile: inputPath)
        let outputContents = try block(contents)
        try outputContents.write(toFile: outputPath, atomically: true, encoding: .utf8)
    }
}

func getBuildNumber() throws -> String {
    let arguments = CommandLine.arguments
    guard let buildNumberIndex = arguments.firstIndex(where: {$0 == "--build-number" }), (arguments.count > buildNumberIndex + 1) else {
        throw NSError(domain: "com.mcubedsw.script", code: -1, userInfo: [NSLocalizedDescriptionKey: "--build-number argument not provided"])
    }

    let number = try String(contentsOfFile: arguments[buildNumberIndex + 1])
    return number.trimmingCharacters(in: .whitespacesAndNewlines)
}

func getGitHash() throws -> String {
    let arguments = CommandLine.arguments
    guard let gitHashIndex = arguments.firstIndex(where: {$0 == "--git-hash" }), (arguments.count > gitHashIndex + 1) else {
        throw NSError(domain: "com.mcubedsw.script", code: -1, userInfo: [NSLocalizedDescriptionKey: "--git-hash argument not provided"])
    }
    return arguments[gitHashIndex + 1]
}

print("\(main())")

