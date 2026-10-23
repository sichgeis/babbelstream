import Foundation

if CommandLine.arguments.contains("--layout-preview") {
    try runLayoutPreview()
} else {
    try await runBehaviorChecks()
    try await runPilotReadinessChecks()
}
print("BabbelStream behavior checks passed.")
