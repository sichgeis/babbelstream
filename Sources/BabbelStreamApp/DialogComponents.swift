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
            Form {
                content
            }
            .formStyle(.grouped)
            .padding(.vertical, 12)
            .frame(maxWidth: maxContentWidth, alignment: .top)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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
        LabeledContent(label) {
            Text(value)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(isPending ? .orange : .secondary)
                .multilineTextAlignment(.trailing)
                .lineLimit(3)
                .textSelection(.enabled)
                .frame(maxWidth: 420, alignment: .trailing)
        }
    }
}
