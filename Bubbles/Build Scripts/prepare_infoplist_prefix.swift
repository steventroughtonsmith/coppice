#!/usr/bin/env xcrun swift

import Foundation

func main() -> Int {
    do {
        var string = try getInputFile()

        let buildNumber = try getBuildNumber()
        string = string.replacingOccurrences(of: "__BUNDLE_VERSION__", with: buildNumber)

        let gitHash = try getGitHash()
        string = string.replacingOccurrences(of: "__BUNDLE_HASH__", with: gitHash)

        try writeToOutputFile(string)
    } catch let e {
        print("Error: \(e)")
        return -1
    }

    return 0
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

func getInputFile() throws -> String {
    let environment = ProcessInfo.processInfo.environment
    guard environment["SCRIPT_INPUT_FILE_COUNT"] == "1", let inputPath = environment["SCRIPT_INPUT_FILE_0"] else {
        throw NSError(domain: "com.mcubedsw.script", code: -1, userInfo: [NSLocalizedDescriptionKey: "We require a single input file"])
    }

    return try String(contentsOfFile: inputPath)
}

func writeToOutputFile(_ string: String) throws {
    let environment = ProcessInfo.processInfo.environment
    guard environment["SCRIPT_OUTPUT_FILE_COUNT"] == "1", let outputPath = environment["SCRIPT_OUTPUT_FILE_0"] else {
        throw NSError(domain: "com.mcubedsw.script", code: -1, userInfo: [NSLocalizedDescriptionKey: "We require a single output file"])
    }

    try string.write(toFile: outputPath, atomically: true, encoding: .utf8)
}

print("\(main())")

