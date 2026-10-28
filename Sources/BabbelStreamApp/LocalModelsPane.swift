import SwiftUI
import BabbelStreamCore

struct LocalModelsPane: View {
    @ObservedObject var controller: LocalModelController
    @Binding var selected: LocalModelID
    let canManage: Bool
    @State private var pendingDownload: LocalModelID?
    @State private var pendingRemoval: LocalModelID?

    var body: some View {
        AppFormSection("Local Models") {
            Picker("Model", selection: $selected) {
                if selected == .unavailable { Text("Saved model unavailable").tag(LocalModelID.unavailable) }
                ForEach(LocalModelID.allCases, id: \.self) { id in Text(id.displayName).tag(id) }
            }
            .disabled(controller.isBusy)
            if selected == .unavailable {
                Text("The saved model is not supported by this build. Explicitly choose a supported model; no replacement is selected automatically.")
                    .font(.caption).fixedSize(horizontal: false, vertical: true)
            }
            if let manifest = try? LocalModelCatalog.manifest(selected) {
                AppLongValue(label: "Download", value: "\(ByteCountFormatter.string(fromByteCount: manifest.bytes, countStyle: .file)) · \(selected.license)")
                AppLongValue(label: "Source", value: "huggingface.co/\(manifest.repository)")
                AppLabeledContent("Model status", value: controller.installed.contains(selected) ? "Prepared" : (controller.present.contains(selected) ? "Needs repair — remove and download again" : "Not downloaded"))
                if !controller.runtime.supportedModels.contains(selected) {
                    Text("This build does not include the runtime for this model. Local speech requires Apple Silicon and macOS 14 or later; Qwen and Granite require a build with MLX support.")
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
            Text("After setup, audio is processed on this Mac. Cleanup and cloud fallback are off. Models stay on disk until you remove them; successful audio follows the existing deletion policy.")
                .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            if selected == .graniteSpeech {
                Text("Experimental: native performance and mixed-language quality still need pilot validation. Personal Dictionary hints are not yet connected to this model.")
                    .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
        }
        .alert("Download local speech model?", isPresented: Binding(get: { pendingDownload != nil }, set: { if !$0 { pendingDownload = nil } })) {
            Button("Download and Prepare") {
                if canManage, let id = pendingDownload { controller.download(id) }
                pendingDownload = nil
            }
            Button("Cancel", role: .cancel) { pendingDownload = nil }
        } message: {
            if let id = pendingDownload, let manifest = try? LocalModelCatalog.manifest(id) {
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
