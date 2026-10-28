import Foundation

if CommandLine.arguments.contains("--local-cleanup-smoke") {
    try await runLocalCleanupSmoke()
} else if CommandLine.arguments.contains("--local-model-smoke") {
    try await runLocalModelSmoke()
} else if CommandLine.arguments.contains("--layout-preview") {
    try runLayoutPreview()
} else {
    try await runBehaviorChecks()
    try await runPilotReadinessChecks()
    try await runConnectionSetupChecks()
    try await runOnboardingChecks()
    try await runLocalTranscriptionChecks()
    try await runLocalCleanupChecks()
}
print("BabbelStream behavior checks passed.")
