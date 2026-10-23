import Foundation

if CommandLine.arguments.contains("--layout-preview") {
    try runLayoutPreview()
} else {
    try await runBehaviorChecks()
    try await runPilotReadinessChecks()
    try await runConnectionSetupChecks()
    try await runOnboardingChecks()
}
print("BabbelStream behavior checks passed.")
