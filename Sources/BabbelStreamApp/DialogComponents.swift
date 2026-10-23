import AppKit
import SwiftUI

struct AppGroupedForm<Content: View>: View {
    let maxContentWidth: CGFloat
    private let content: Content

    init(
        maxContentWidth: CGFloat = 680,
        @ViewBuilder content: () -> Content
    ) {
        self.maxContentWidth = maxContentWidth
        self.content = content()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                content
            }
            .padding(16)
            .frame(maxWidth: maxContentWidth, alignment: .topLeading)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

/// Explicit section metrics avoid OS-dependent grouped Form insets and nested scrolling.
/// Controls remain native; the outer AppGroupedForm owns scrolling.
struct AppFormSection<Content: View>: View {
    let title: String
    private let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
            VStack(alignment: .leading, spacing: 10) {
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color(nsColor: .separatorColor), lineWidth: 0.5)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .textFieldStyle(.roundedBorder)
    }
}

struct AppDialogScaffold<Content: View, Status: View, Actions: View>: View {
    let maxContentWidth: CGFloat
    private let content: Content
    private let status: Status
    private let actions: Actions

    init(
        maxContentWidth: CGFloat = 680,
        @ViewBuilder content: () -> Content,
        @ViewBuilder status: () -> Status,
        @ViewBuilder actions: () -> Actions
    ) {
        self.maxContentWidth = maxContentWidth
        self.content = content()
        self.status = status()
        self.actions = actions()
    }

    var body: some View {
        VStack(spacing: 0) {
            AppGroupedForm(maxContentWidth: maxContentWidth) {
                content
            }

            Divider()
            AppDialogFooter {
                status
            } actions: {
                actions
            }
        }
    }
}

struct AppDialogFooter<Status: View, Actions: View>: View {
    private let status: Status
    private let actions: Actions

    init(
        @ViewBuilder status: () -> Status,
        @ViewBuilder actions: () -> Actions
    ) {
        self.status = status()
        self.actions = actions()
    }

    var body: some View {
        HStack(spacing: 12) {
            status
                .font(.caption)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8) {
                actions
            }
            .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(.bar)
    }
}

struct AppLongValue: View {
    let label: String
    let value: String
    var isPending = false

    var body: some View {
        AppLabeledContent(label) {
            Text(value)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(isPending ? .orange : .secondary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

/// Stable label column with wrapping values, independent of Form's platform styles.
struct AppLabeledContent<Content: View>: View {
    let title: String
    let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    init(_ title: String, value: String) where Content == Text {
        self.title = title
        self.content = Text(value)
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(title)
                .frame(width: 168, alignment: .leading)
            content
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct AppFormTextField: View {
    let title: String
    let axis: Axis
    @Binding var text: String
    init(_ title: String, text: Binding<String>, axis: Axis = .horizontal) {
        self.title = title
        self.axis = axis
        self._text = text
    }
    var body: some View {
        AppLabeledContent(title) {
            TextField(title, text: $text, axis: axis)
                .labelsHidden()
        }
    }
}

struct AppFormSecureField: View {
    let title: String
    @Binding var text: String
    init(_ title: String, text: Binding<String>) {
        self.title = title
        self._text = text
    }
    var body: some View {
        AppLabeledContent("API key") {
            SecureField(title, text: $text)
                .labelsHidden()
        }
    }
}
