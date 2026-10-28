import Foundation

if CommandLine.arguments.contains("--local-model-smoke") {
    try await runLocalModelSmoke()
} else if CommandLine.arguments.contains("--layout-preview") {
    try runLayoutPreview()
} else {
    try await runBehaviorChecks()
    try await runPilotReadinessChecks()
    try await runConnectionSetupChecks()
    try await runOnboardingChecks()
    try await runLocalTranscriptionChecks()
}
print("BabbelStream behavior checks passed.")
