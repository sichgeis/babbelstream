import Foundation

if CommandLine.arguments.contains("--layout-preview") {
    try runLayoutPreview()
} else {
    try await runBehaviorChecks()
}
print("BabbelStream behavior checks passed.")
