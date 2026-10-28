import SwiftUI
import BabbelStreamCore

struct LocalModelsPane: View {
    @ObservedObject var controller: LocalModelController
    @Binding var selected: LocalModelID
    let canManage: Bool
    var isCleanup = false
    private var modelIDs: [LocalModelID] { isCleanup ? [.qwenCleanup] : LocalModelID.allCases }
    private func manifest(_ id: LocalModelID) -> LocalModelManifest? {
        isCleanup ? LocalCleanupCatalog.manifest : try? LocalModelCatalog.manifest(id)
    }
    @State private var pendingDownload: LocalModelID?
    @State private var pendingRemoval: LocalModelID?

    var body: some View {
        AppFormSection(isCleanup ? "Local Cleanup Model" : "Local Models") {
            Picker("Model", selection: $selected) {
                if selected == .unavailable { Text("Saved model unavailable").tag(LocalModelID.unavailable) }
                ForEach(modelIDs, id: \.self) { id in Text(id.displayName).tag(id) }
            }
            .disabled(controller.isBusy)
            if selected == .unavailable {
                Text("The saved model is not supported by this build. Explicitly choose a supported model; no replacement is selected automatically.")
                    .font(.caption).fixedSize(horizontal: false, vertical: true)
            }
            if let manifest = manifest(selected) {
                AppLongValue(label: "Download", value: "\(ByteCountFormatter.string(fromByteCount: manifest.bytes, countStyle: .file)) · \(selected.license)")
                AppLongValue(label: "Source", value: "huggingface.co/\(manifest.repository)")
                AppLabeledContent("Model status", value: controller.installed.contains(selected) ? "Prepared" : (controller.present.contains(selected) ? "Needs repair — remove and download again" : "Not downloaded"))
                if !controller.runtime.supportedModels.contains(selected) {
                    Text(isCleanup ? "Local cleanup requires Apple Silicon, macOS 14 or later and the bundled cleanup helper." : "This build does not include the runtime for this model. Local speech requires Apple Silicon and macOS 14 or later; Qwen and Granite require a build with MLX support.")
                        .font(.caption).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                HStack {
                    Button("Download Model…") { pendingDownload = selected }
                        .disabled(!canManage || controller.present.contains(selected)
                                  || !controller.runtime.supportedModels.contains(selected))
                    Button("Remove Model…", role: .destructive) { pendingRemoval = selected }
                        .disabled(!canManage || !controller.present.contains(selected))
                    if controller.canCancelDownload { Button("Cancel Download") { controller.cancel() } }
                }
            }
            if controller.canCancelDownload { ProgressView(value: controller.progress) }
            Text(controller.message).font(.callout).fixedSize(horizontal: false, vertical: true)
            Text(isCleanup ? "Cleanup runs on this Mac without a key or separate app. There is no cloud cleanup fallback. Models remain until removed. Enable local cleanup and Apply after setup." : "After setup, audio is processed on this Mac. Cloud fallback is off; optional local cleanup can be enabled below. Models stay on disk until you remove them; successful audio follows the existing deletion policy.")
                .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            if selected == .graniteSpeech {
                Text("Experimental: native performance and mixed-language quality still need pilot validation. Personal Dictionary hints are not yet connected to this model.")
                    .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
        }
        .alert(isCleanup ? "Download local cleanup model?" : "Download local speech model?", isPresented: Binding(get: { pendingDownload != nil }, set: { if !$0 { pendingDownload = nil } })) {
            Button("Download and Prepare") {
                if canManage, let id = pendingDownload { controller.download(id) }
                pendingDownload = nil
            }
            Button("Cancel", role: .cancel) { pendingDownload = nil }
        } message: {
            if let id = pendingDownload, let manifest = manifest(id) {
                Text("Download \(ByteCountFormatter.string(fromByteCount: manifest.bytes, countStyle: .file)) from huggingface.co and its HTTPS file CDN. The host sees ordinary connection metadata. License: \(id.license). Preparation may take several minutes. This does not select the model or send audio; Apply Settings afterwards.")
            }
        }
        .alert("Remove downloaded model?", isPresented: Binding(get: { pendingRemoval != nil }, set: { if !$0 { pendingRemoval = nil } })) {
            Button("Remove Model", role: .destructive) {
                if canManage, let id = pendingRemoval { controller.remove(id) }
                pendingRemoval = nil
            }
            Button("Cancel", role: .cancel) { pendingRemoval = nil }
        } message: { Text("Only this downloaded model is removed. Recordings, settings, dictionary and saved drafts are preserved. Download it again before using it.") }
    }
}
