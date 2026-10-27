import SwiftUI

struct AppSearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search..."
    var isExpandable: Bool = false
    var isExpandedBinding: Binding<Bool>? = nil
    var autoFocus: Bool = false
    var debounceDuration: TimeInterval = 0.35
    var onDebouncedChange: ((String) -> Void)? = nil
    var onSubmit: ((String) -> Void)? = nil
    var onCancel: (() -> Void)? = nil

    @State private var internalExpanded: Bool = false
    @FocusState private var isFieldFocused: Bool
    @State private var debounceTask: Task<Void, Never>? = nil
    @Environment(\.colorScheme) private var colorScheme
    @Environment(AppEnvironment.self) private var env

    private var isExpanded: Bool {
        isExpandedBinding?.wrappedValue ?? internalExpanded
    }

    private func setExpanded(_ value: Bool) {
        if let binding = isExpandedBinding {
            binding.wrappedValue = value
        } else {
            internalExpanded = value
        }
    }

    // Initializer for standard (always visible) search bar
    init(
        text: Binding<String>,
        placeholder: String,
        autoFocus: Bool = false,
        debounceDuration: TimeInterval = 0.35,
        onDebouncedChange: ((String) -> Void)? = nil,
        onSubmit: ((String) -> Void)? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.isExpandable = false
        self.isExpandedBinding = nil
        self.autoFocus = autoFocus
        self.debounceDuration = debounceDuration
        self.onDebouncedChange = onDebouncedChange
        self.onSubmit = onSubmit
        self.onCancel = nil
    }

    // Initializer for expandable search bar
    init(
        text: Binding<String>,
        placeholder: String,
        isExpanded: Binding<Bool>,
        autoFocus: Bool = true,
        debounceDuration: TimeInterval = 0.35,
        onDebouncedChange: ((String) -> Void)? = nil,
        onSubmit: ((String) -> Void)? = nil,
        onCancel: (() -> Void)? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.isExpandable = true
        self.isExpandedBinding = isExpanded
        self.autoFocus = autoFocus
        self.debounceDuration = debounceDuration
        self.onDebouncedChange = onDebouncedChange
        self.onSubmit = onSubmit
        self.onCancel = onCancel
    }

    var body: some View {
        if isExpandable && !isExpanded {
            collapsedButton
        } else {
            expandedField
        }
    }

    // MARK: - Collapsed Search Icon Button
    private var collapsedButton: some View {
        Button {
            Haptics.tap()
            withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                setExpanded(true)
            }
        } label: {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.primary)
                .frame(width: 38, height: 38)
                .background(.ultraThinMaterial, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(env.l10n.t("search"))
    }

    // MARK: - Expanded Search Input Field
    private var expandedField: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(isFieldFocused ? env.palette.primary : Color.secondary)
                    .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isFieldFocused)

                TextField(placeholder, text: $text)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(env.palette.textPrimary)
                    .autocorrectionDisabled()
                    .focused($isFieldFocused)
                    .textInputAutocapitalization(.never)
                    .submitLabel(.search)
                    .onSubmit {
                        debounceTask?.cancel()
                        onSubmit?(text)
                        onDebouncedChange?(text)
                    }

                if !text.isEmpty {
                    Button {
                        Haptics.tap()
                        text = ""
                        debounceTask?.cancel()
                        onDebouncedChange?("")
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.secondary)
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 44)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(colorScheme == .dark ? Color(hex: 0x162232) : Color.white)
                    .shadow(
                        color: Color.black.opacity(colorScheme == .dark ? 0.25 : 0.05),
                        radius: isFieldFocused ? 8 : 4,
                        x: 0,
                        y: 1.5
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        isFieldFocused
                            ? env.palette.primary.opacity(0.65)
                            : (colorScheme == .dark ? Color.white.opacity(0.12) : env.palette.border),
                        lineWidth: isFieldFocused ? 1.25 : 0.75
                    )
                    .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isFieldFocused)
            }

            if isExpandable {
                Button {
                    Haptics.tap()
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                        text = ""
                        debounceTask?.cancel()
                        onDebouncedChange?("")
                        isFieldFocused = false
                        setExpanded(false)
                        onCancel?()
                    }
                } label: {
                    Text(env.l10n.t("cancel"))
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(env.palette.primary)
                }
                .buttonStyle(.plain)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .onChange(of: text) { _, newText in
            debounceTask?.cancel()
            debounceTask = Task {
                try? await Task.sleep(nanoseconds: UInt64(debounceDuration * 1_000_000_000))
                if !Task.isCancelled {
                    await MainActor.run {
                        onDebouncedChange?(newText)
                    }
                }
            }
        }
        .onAppear {
            if autoFocus || (isExpandable && isExpanded) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    isFieldFocused = true
                }
            }
        }
        .onChange(of: isExpanded) { _, expanded in
            if expanded {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isFieldFocused = true
                }
            } else {
                isFieldFocused = false
            }
        }
    }
}
