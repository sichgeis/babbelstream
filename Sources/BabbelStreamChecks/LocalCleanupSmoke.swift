import Foundation
import BabbelStreamCore

func runLocalCleanupSmoke() async throws {
    func argument(_ key: String) throws -> String {
        let args = CommandLine.arguments
        guard let i = args.firstIndex(of: key), args.indices.contains(i + 1) else { throw LocalModelError.invalidManifest }
        return args[i + 1]
    }
    let directory = URL(fileURLWithPath: try argument("--model-directory"))
    guard directory.path.hasPrefix("/tmp/") || directory.path.hasPrefix("/private/tmp/") else { throw LocalModelError.invalidManifest }
    let runtime = BundledLocalCleanupRuntime(executable: URL(fileURLWithPath: try argument("--helper")))
    let store = LocalModelStore(root: directory.deletingLastPathComponent())
    try await store.verify(LocalCleanupCatalog.manifest, at: directory)
    print("Synthetic cleanup model hash verified; preparing helper.")
    do { try await runtime.prepare(model: .qwenCleanup, directory: directory) }
    catch { try? FileHandle.standardError.write(contentsOf: Data("Synthetic native preparation failed.\n".utf8)); throw error }
    print("Native preparation passed; starting synthetic inference.")
    let fixtures: [(String, [String])] = [
        ("um please please do not deploy version 2.7 until Friday", ["not", "2.7", "Friday"]),
        ("äh bitte bitte Version 2.7 nicht vor Freitag deployen", ["2.7", "nicht", "Freitag"]),
        ("äh der build ist ready aber bitte nicht deployen issue DEMO-42 bleibt offen", ["ready", "nicht", "DEMO-42"]),
        ("can you explain how this works and send me three examples", ["explain", "three examples"]),
        ("um check https://example.com/v2 and src/main.swift before we change API_KEY", ["https://example.com/v2", "src/main.swift", "API_KEY"])
    ]
    for (index, fixture) in fixtures.enumerated() {
        let start = Date()
        let result: String
        do { result = try await runtime.cleanup(directory: directory, transcript: fixture.0, dictionary: PersonalDictionary()) }
        catch { try? FileHandle.standardError.write(contentsOf: Data("Synthetic native inference failed at fixture \(index + 1).\n".utf8)); throw error }
        guard fixture.1.allSatisfy({ result.localizedCaseInsensitiveContains($0) }) else { try? FileHandle.standardError.write(contentsOf: Data("Synthetic preservation check failed at fixture \(index + 1).\n".utf8)); throw LocalCleanupError.failed }
        guard result.count < fixture.0.count * 2 else { throw LocalCleanupError.failed }
        try? FileHandle.standardError.write(contentsOf: Data("Synthetic cleanup fixture \(index + 1) passed.\n".utf8))
        print("Synthetic cleanup fixture \(index + 1) passed (\(Int(Date().timeIntervalSince(start))) s); text discarded.")
    }
    let dictionary = PersonalDictionary(corrections: [PersonalCorrectionEntry(from: "bubble stream", to: "BabbelStream")])
    let corrected = try await runtime.cleanup(directory: directory, transcript: "um bubble stream is ready for testing", dictionary: dictionary)
    guard corrected.contains("BabbelStream") else { throw LocalCleanupError.failed }
    print("Synthetic dictionary correction passed; text discarded.")
    print("Pinned model verified; network-denied English, German, mixed, dictated-request and identifier fixtures passed.")
}
