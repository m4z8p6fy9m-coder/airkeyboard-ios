import UIKit

final class KeyboardViewController: UIInputViewController {
    private var state = KeyboardState()
    private var settings = SharedSettings()
    private let audio = SoundEngine()
    private let stack = UIStackView()
    private let status = UILabel()
    private var height: NSLayoutConstraint?
    private var refreshTask: Task<Void, Never>?
    private var repeatTimer: Timer?
    private var isDeleting = false
    private var lastShift: TimeInterval = 0
    private var documentID: UUID?
    private var visible = false
    private var audioReady = false
    private var renderedState: KeyboardState?
    private var renderedTheme: Theme?
    private var renderedTraits = ""
    private var sharingAvailable = true
    private var showingLocalDesigns = false

    override func viewDidLoad() {
        super.viewDidLoad()
        stack.axis = .vertical
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 4),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4),
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 4),
            stack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -4)
        ])
        let constraint = view.heightAnchor.constraint(equalToConstant: 280)
        constraint.priority = .defaultHigh
        constraint.isActive = true
        height = constraint
        render()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        visible = true
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self, self.visible else { return }
                await self.reloadSettings()
                do { try await Task.sleep(nanoseconds: 2_000_000_000) } catch { return }
            }
        }
        updateTraits()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        visible = false; refreshTask?.cancel(); refreshTask = nil
        stopRepeating(); audio.releaseResources(); audioReady = false
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        audio.releaseResources(); audioReady = false
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let landscape = view.window.map { $0.bounds.width > $0.bounds.height } ?? false
        height?.constant = landscape ? 236 : 288
    }
    override func textDidChange(_ textInput: UITextInput?) { updateTraits() }
    override func selectionDidChange(_ textInput: UITextInput?) { updateTraits() }

    private func reloadSettings() async {
        do {
            let updated = try await SharedStore.load()
            let shared = try await SharedStore.isSharingAvailable()
            guard visible else { return }
            let changed = settings != updated || sharingAvailable != shared
            settings = updated
            sharingAvailable = shared
            if changed { render() }
            status.text = !shared ? "AirKeyboard · Local design" : hasFullAccess ? (settings.sound.audible ? "AirKeyboard · Custom audio" : "AirKeyboard · Silent") : "AirKeyboard · Full Access off · Silent"
        } catch {
            // Read-only keyboard never repairs/writes shared files. Keep a safe in-memory default.
            status.text = "AirKeyboard · Local fallback"
        }
        if hasFullAccess && settings.sound.audible && !audioReady && visible {
            await audio.prepare()
            audioReady = visible && hasFullAccess
            if !audioReady { audio.releaseResources() }
        } else if !hasFullAccess || !settings.sound.audible {
            audio.stop()
        }
    }
    private func updateTraits() {
        let proxy = textDocumentProxy
        if documentID != proxy.documentIdentifier {
            documentID = proxy.documentIdentifier
            state = KeyboardState()
            switch proxy.keyboardType {
            case .numberPad?, .decimalPad?, .phonePad?, .asciiCapableNumberPad?: state.page = .numbers
            default: break
            }
        }
        if state.shift != .locked {
            let context = proxy.documentContextBeforeInput ?? ""
            switch proxy.autocapitalizationType ?? .sentences {
            case .none: state.shift = .off
            case .allCharacters: state.shift = .once
            case .words: state.shift = context.last?.isWhitespace != false ? .once : .off
            case .sentences:
                state.shift = context.isEmpty || context.hasSuffix("\n") || [". ", "! ", "? "].contains(where: context.hasSuffix) ? .once : .off
            @unknown default: state.shift = .off
            }
        }
        render()
    }
    private func render() {
        guard isViewLoaded else { return }
        let traits = "\(textDocumentProxy.keyboardType?.rawValue ?? 0):\(returnTitle):\(needsInputModeSwitchKey):\(textDocumentProxy.enablesReturnKeyAutomatically == true && !textDocumentProxy.hasText):\(sharingAvailable):\(showingLocalDesigns)"
        guard renderedState != state || renderedTheme != settings.theme || renderedTraits != traits else { return }
        renderedState = state; renderedTheme = settings.theme; renderedTraits = traits
        stopRepeating()
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let theme = settings.theme
        view.backgroundColor = UIColor(hex: theme.background)
        overrideUserInterfaceStyle = theme.appearance == .light ? .light : .dark
        stack.spacing = theme.spacing
        stack.layoutMargins = UIEdgeInsets(top: 0, left: theme.padding, bottom: 0, right: theme.padding)
        stack.isLayoutMarginsRelativeArrangement = true
        status.font = .preferredFont(forTextStyle: .caption2)
        status.adjustsFontForContentSizeCategory = true
        status.textColor = UIColor(hex: theme.secondary)
        status.textAlignment = .center
        status.text = hasFullAccess ? "AirKeyboard" : "AirKeyboard · Full Access off · Silent"
        status.heightAnchor.constraint(greaterThanOrEqualToConstant: 18).isActive = true
        if !sharingAvailable {
            let design = button(showingLocalDesigns ? "Back" : "Design", label: "Choose keyboard design") { [weak self] in
                guard let self else { return }
                self.showingLocalDesigns.toggle(); self.render()
            }
            design.accessibilityTraits.remove(.keyboardKey)
            design.widthAnchor.constraint(equalToConstant: 76).isActive = true
            let toolbar = UIStackView(arrangedSubviews: [status, design]); toolbar.spacing = 8
            stack.addArrangedSubview(toolbar)
        } else { stack.addArrangedSubview(status) }
        if showingLocalDesigns && !sharingAvailable {
            for pair in stride(from: 0, to: StarterThemes.all.count, by: 2) {
                let row = rowStack()
                for theme in StarterThemes.all[pair..<min(pair + 2, StarterThemes.all.count)] {
                    row.addArrangedSubview(button(theme.name) { [weak self] in
                        Task { @MainActor in
                            guard let self else { return }
                            do {
                                self.settings = try await SharedStore.update { $0.theme = theme; $0.sound.pack = theme.soundPack }
                                self.showingLocalDesigns = false; self.render()
                            } catch { self.status.text = error.localizedDescription }
                        }
                    })
                }
                stack.addArrangedSubview(row)
            }
            let controls = rowStack()
            controls.addArrangedSubview(button(settings.sound.enabled ? "Sounds: On" : "Sounds: Off") { [weak self] in
                Task { @MainActor in
                    guard let self else { return }
                    do {
                        self.settings = try await SharedStore.update { $0.sound.enabled.toggle() }
                        self.renderedState = nil; self.render()
                    } catch { self.status.text = error.localizedDescription }
                }
            })
            controls.addArrangedSubview(button("Next keyboard") { [weak self] in self?.advanceToNextInputMode() })
            stack.addArrangedSubview(controls)
            return
        }
        var firstRow: UIStackView?
        for (index, values) in state.rows(layout: theme.layout).enumerated() {
            let row = rowStack()
            if let first = firstRow { row.heightAnchor.constraint(equalTo: first.heightAnchor).isActive = true }
            else { firstRow = row }
            if index == 2 {
                let shift = button(state.page == .letters ? (state.shift == .locked ? "⇪" : "⇧") : (state.page == .numbers ? "#+=" : "123"), label: state.page == .letters ? "Shift" : "More symbols") { [weak self] in self?.shift() }
                if state.page == .letters && state.shift != .off { shift.setTitleColor(UIColor(hex: theme.accent), for: .normal) }
                if state.page == .letters { shift.accessibilityValue = state.shift == .locked ? "Caps Lock" : state.shift == .once ? "On" : "Off" }
                row.addArrangedSubview(shift)
            }
            for value in values {
                row.addArrangedSubview(button(state.page == .letters && state.shift != .off ? value.uppercased() : value) { [weak self] in self?.insert(value) })
            }
            if index == 2 {
                let delete = button("⌫", label: "Delete") { [weak self] in self?.delete() }
                delete.addTarget(self, action: #selector(beginRepeating), for: .touchDown)
                delete.addTarget(self, action: #selector(stopRepeating), for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit])
                row.addArrangedSubview(delete)
            }
            stack.addArrangedSubview(row)
        }
        let bottom = rowStack(); bottom.distribution = .fill
        if let first = firstRow { bottom.heightAnchor.constraint(equalTo: first.heightAnchor).isActive = true }
        let mode = button(state.page == .letters ? "123" : "ABC", label: "Change layout") { [weak self] in
            guard let self else { return }
            self.state.page = self.state.page == .letters ? .numbers : .letters; self.render()
        }
        bottom.addArrangedSubview(mode)
        mode.widthAnchor.constraint(equalTo: bottom.widthAnchor, multiplier: 0.14).isActive = true
        if needsInputModeSwitchKey {
            let globe = button("◎", label: "Next keyboard") {}
            globe.removeTarget(nil, action: nil, for: .allEvents)
            // Includes the system's hold-to-select keyboard list and tap-to-advance behavior.
            globe.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
            bottom.addArrangedSubview(globe)
            globe.widthAnchor.constraint(equalTo: bottom.widthAnchor, multiplier: 0.12).isActive = true
        }
        if textDocumentProxy.keyboardType == .emailAddress || textDocumentProxy.keyboardType == .URL {
            let special = button(textDocumentProxy.keyboardType == .emailAddress ? "@" : "/") { [weak self] in
                guard let self else { return }; self.textDocumentProxy.insertText(self.textDocumentProxy.keyboardType == .emailAddress ? "@" : "/"); self.feedback()
            }
            bottom.addArrangedSubview(special)
            special.widthAnchor.constraint(equalTo: bottom.widthAnchor, multiplier: 0.09).isActive = true
        }
        let space = button("space", label: "Space") { [weak self] in self?.textDocumentProxy.insertText(" "); self?.feedback(); self?.updateTraits() }
        bottom.addArrangedSubview(space)
        let enter = button(returnTitle, label: returnTitle) { [weak self] in self?.textDocumentProxy.insertText("\n"); self?.feedback(); self?.updateTraits() }
        enter.setTitleColor(UIColor(hex: theme.accent), for: .normal)
        enter.isEnabled = !(textDocumentProxy.enablesReturnKeyAutomatically == true && !textDocumentProxy.hasText)
        bottom.addArrangedSubview(enter)
        enter.widthAnchor.constraint(equalTo: bottom.widthAnchor, multiplier: 0.2).isActive = true
        stack.addArrangedSubview(bottom)
    }
    private var returnTitle: String {
        switch textDocumentProxy.returnKeyType ?? .default {
        case .go: return "go"
        case .search, .google, .yahoo: return "search"
        case .send: return "send"
        case .done: return "done"
        case .next: return "next"
        case .join: return "join"
        case .route: return "route"
        case .continue: return "continue"
        default: return "return"
        }
    }
    private func rowStack() -> UIStackView {
        let row = UIStackView(); row.axis = .horizontal; row.spacing = settings.theme.spacing
        row.distribution = .fillEqually
        row.heightAnchor.constraint(greaterThanOrEqualToConstant: 40).isActive = true
        return row
    }
    private func button(_ title: String, label: String? = nil, action: @escaping () -> Void) -> UIButton {
        let button = KeyButton(theme: settings.theme)
        button.setTitle(title, for: .normal)
        button.accessibilityLabel = label ?? title
        button.accessibilityTraits.insert(.keyboardKey)
        button.addAction(UIAction { _ in action() }, for: .touchUpInside)
        return button
    }
    private func insert(_ value: String) {
        textDocumentProxy.insertText(state.character(value)); feedback()
        updateTraits()
    }
    private func shift() {
        if state.page != .letters { state.page = state.page == .numbers ? .symbols : .numbers }
        else {
            let now = Date.timeIntervalSinceReferenceDate
            state.toggleShift(lock: now - lastShift < 0.35); lastShift = now
        }
        render()
    }
    private func delete() { textDocumentProxy.deleteBackward(); feedback() }
    private func feedback() {
        guard hasFullAccess else { audio.stop(); return }
        if !audio.play(settings.sound) { status.text = "AirKeyboard · Audio unavailable · Silent" }
    }
    @objc private func beginRepeating() {
        stopRepeating()
        isDeleting = true
        repeatTimer = Timer.scheduledTimer(withTimeInterval: 0.45, repeats: false) { [weak self] _ in
            Task { @MainActor in self?.startFastRepeat() }
        }
    }
    private func startFastRepeat() {
        guard isDeleting else { return }
        repeatTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.isDeleting else { return }
                self.delete()
            }
        }
    }
    @objc private func stopRepeating() { isDeleting = false; repeatTimer?.invalidate(); repeatTimer = nil }
}

private final class KeyButton: UIButton {
    let theme: Theme
    init(theme: Theme) {
        self.theme = theme
        super.init(frame: .zero)
        setTitleColor(UIColor(hex: theme.primary), for: .normal)
        setTitleColor(UIColor(hex: theme.secondary), for: .disabled)
        layer.cornerRadius = theme.cornerRadius
        layer.borderColor = UIColor(hex: theme.border).cgColor
        layer.borderWidth = theme.borderWidth
        let base = UIFont.preferredFont(forTextStyle: .title3)
        let design: UIFontDescriptor.SystemDesign = theme.font == .rounded ? .rounded : theme.font == .monospaced ? .monospaced : .default
        titleLabel?.font = UIFont(descriptor: base.fontDescriptor.withDesign(design) ?? base.fontDescriptor, size: 0)
        titleLabel?.adjustsFontForContentSizeCategory = true
        titleLabel?.adjustsFontSizeToFitWidth = true
        titleLabel?.minimumScaleFactor = 0.5
        backgroundColor = UIColor(hex: theme.key)
    }
    required init?(coder: NSCoder) { fatalError("Programmatic keyboard only") }
    override var isHighlighted: Bool { didSet { backgroundColor = UIColor(hex: isHighlighted ? theme.pressed : theme.key) } }
    override var isEnabled: Bool { didSet { alpha = isEnabled ? 1 : 0.45 } }
}
