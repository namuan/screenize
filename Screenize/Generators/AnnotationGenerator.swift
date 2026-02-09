import Foundation

/// Annotation keyframe generator
/// Automatically creates text annotation keyframes from mouse clicks and keyboard shortcuts
final class AnnotationGenerator: KeyframeGenerator {
    typealias Output = AnnotationTrack

    let name = "Annotation"
    let description = "Generate text annotations from mouse clicks and keyboard actions"

    func generate(from mouseData: MouseDataSource, settings: GeneratorSettings) -> AnnotationTrack {
        let annotationSettings = settings.annotation
        guard annotationSettings.enabled else {
            return AnnotationTrack(name: "Annotation (Auto)", keyframes: [])
        }

        var keyframes: [AnnotationKeyframe] = []
        var lastAnnotationTime: TimeInterval = -annotationSettings.minInterval

        // Generate annotations from click events
        for click in mouseData.clicks where click.clickType == .leftDown || click.clickType == .doubleClick {
            guard click.time - lastAnnotationTime >= annotationSettings.minInterval else { continue }

            if let annotation = generateClickAnnotation(for: click, settings: annotationSettings) {
                let position = calculateAnnotationPosition(for: click, settings: annotationSettings)

                let keyframe = AnnotationKeyframe(
                    time: click.time,
                    type: .text,
                    text: annotation.text,
                    duration: annotationSettings.displayDuration,
                    fadeInDuration: annotationSettings.fadeInDuration,
                    fadeOutDuration: annotationSettings.fadeOutDuration,
                    position: position,
                    fontScale: annotationSettings.fontScale,
                    textColor: annotationSettings.textColor,
                    textBackgroundColor: annotationSettings.backgroundColor,
                    contextLabel: annotation.contextLabel,
                    contextIcon: annotation.contextIcon,
                    contextHierarchy: annotation.contextHierarchy
                )
                keyframes.append(keyframe)
                lastAnnotationTime = click.time
            }
        }

        // Generate annotations from keyboard shortcuts
        if annotationSettings.includeKeyboardShortcuts {
            for event in mouseData.keyboardEvents where event.eventType == .keyDown {
                guard event.time - lastAnnotationTime >= annotationSettings.minInterval else { continue }

                if let annotation = generateKeyboardAnnotation(for: event, settings: annotationSettings) {
                    let position = NormalizedPoint(
                        x: annotationSettings.keyboardAnnotationPosition.x,
                        y: annotationSettings.keyboardAnnotationPosition.y
                    )

                    let keyframe = AnnotationKeyframe(
                        time: event.time,
                        type: .text,
                        text: annotation.text,
                        duration: annotationSettings.displayDuration,
                        fadeInDuration: annotationSettings.fadeInDuration,
                        fadeOutDuration: annotationSettings.fadeOutDuration,
                        position: position,
                        fontScale: annotationSettings.fontScale,
                        textColor: annotationSettings.textColor,
                        textBackgroundColor: annotationSettings.backgroundColor,
                        contextLabel: annotation.contextLabel,
                        contextIcon: annotation.contextIcon,
                        contextHierarchy: nil
                    )
                    keyframes.append(keyframe)
                    lastAnnotationTime = event.time
                }
            }
        }

        return AnnotationTrack(name: "Annotation (Auto)", isEnabled: true, keyframes: keyframes)
    }

    // MARK: - Annotation Result

    struct AnnotationResult {
        let text: String
        let contextLabel: String?
        let contextIcon: String?
        let contextHierarchy: String?
    }

    // MARK: - Click Annotations

    private func generateClickAnnotation(for click: ClickEventData, settings: AnnotationGeneratorSettings) -> AnnotationResult? {
        guard settings.includeClickAnnotations else { return nil }

        // Use UI element info if available
        if let elementInfo = click.elementInfo {
            return generateElementAnnotation(for: elementInfo, clickType: click.clickType, settings: settings)
        }

        // Fallback: generic click annotation
        if settings.includeGenericClicks {
            switch click.clickType {
            case .doubleClick:
                return AnnotationResult(text: "Double-click", contextLabel: nil, contextIcon: "cursorarrow.click.2", contextHierarchy: nil)
            default:
                return AnnotationResult(text: "Click", contextLabel: nil, contextIcon: "cursorarrow.click", contextHierarchy: nil)
            }
        }

        return nil
    }

    private func generateElementAnnotation(for element: UIElementInfo, clickType: ClickEventData.ClickType, settings: AnnotationGeneratorSettings) -> AnnotationResult? {
        let role = element.role
        let title = element.title?.trimmingCharacters(in: .whitespacesAndNewlines)
        let appName = element.applicationName
        var contextLabel = appName
        var contextIcon: String? = nil
        var contextHierarchy: String? = nil
        var text: String

        // Role-based annotation templates
        switch role {
        case "AXButton", "AXLink":
            contextIcon = "hand.tap"
            if let title = title, !title.isEmpty, title.count <= settings.maxTitleLength {
                text = clickType == .doubleClick ? "Double-click \"\(title)\"" : "Click \"\(title)\""
            } else {
                text = clickType == .doubleClick ? "Double-click button" : "Click button"
            }

        case "AXCheckBox", "AXRadioButton", "AXSwitch":
            contextIcon = "checkmark"
            if let title = title, !title.isEmpty, title.count <= settings.maxTitleLength {
                text = "Select \"\(title)\""
            } else {
                text = "Select"
            }

        case "AXMenuItem":
            contextIcon = "menucard"
            if let title = title, !title.isEmpty, title.count <= settings.maxTitleLength {
                text = "Choose \"\(title)\""
                // Try to build hierarchy from title (e.g., "File > Save")
                if title.contains(" > ") {
                    contextHierarchy = title
                    text = "Choose"
                }
            } else {
                text = "Choose menu item"
            }

        case "AXPopUpButton", "AXComboBox":
            contextIcon = "chevron.down"
            if let title = title, !title.isEmpty, title.count <= settings.maxTitleLength {
                text = "Open \"\(title)\""
            } else {
                text = "Open dropdown"
            }

        case "AXTextField", "AXTextArea", "AXSearchField", "AXSecureTextField":
            contextIcon = "keyboard"
            if let title = title, !title.isEmpty, title.count <= settings.maxTitleLength {
                text = "Enter \(title)"
            } else {
                text = "Type here"
            }

        case "AXSlider":
            contextIcon = "slider.horizontal.3"
            text = "Adjust slider"

        case "AXDisclosureTriangle":
            contextIcon = "chevron.right"
            if let title = title, !title.isEmpty, title.count <= settings.maxTitleLength {
                text = "Toggle \"\(title)\""
            } else {
                text = "Expand/Collapse"
            }

        case "AXIncrementor":
            contextIcon = "plusminus"
            text = "Adjust value"

        case "AXTabGroup":
            contextIcon = "rectangle.split.3x1"
            if let title = title, !title.isEmpty, title.count <= settings.maxTitleLength {
                text = "Switch to \"\(title)\""
            } else {
                text = "Switch tab"
            }

        default:
            contextIcon = "cursorarrow.click"
            // Generic fallback with title
            if let title = title, !title.isEmpty, title.count <= settings.maxTitleLength {
                text = clickType == .doubleClick ? "Double-click \"\(title)\"" : "Click \"\(title)\""
            } else if settings.includeGenericClicks {
                text = clickType == .doubleClick ? "Double-click" : "Click"
            } else {
                return nil
            }
        }

        return AnnotationResult(
            text: text,
            contextLabel: contextLabel,
            contextIcon: contextIcon,
            contextHierarchy: contextHierarchy
        )
    }

    // MARK: - Keyboard Annotations

    private func generateKeyboardAnnotation(for event: KeyboardEventData, settings: AnnotationGeneratorSettings) -> AnnotationResult? {
        // Only generate for shortcuts (modifier + key)
        guard event.modifiers.hasShortcutModifiers else { return nil }

        let modSymbols = Self.modifierSymbols(from: event.modifiers)

        guard let keyName = Self.displayName(for: event.keyCode, character: event.character) else {
            return nil
        }

        let shortcutText = modSymbols + keyName
        var contextIcon: String? = "keyboard"

        // Look up known shortcuts
        if let description = Self.shortcutDescription(for: shortcutText, appBundleID: nil) {
            // Determine icon based on action type
            contextIcon = Self.shortcutIcon(for: shortcutText)
            return AnnotationResult(
                text: shortcutText,
                contextLabel: description,
                contextIcon: contextIcon,
                contextHierarchy: nil
            )
        }

        return AnnotationResult(
            text: shortcutText,
            contextLabel: nil,
            contextIcon: contextIcon,
            contextHierarchy: nil
        )
    }

    // MARK: - Position Calculation

    private func calculateAnnotationPosition(for click: ClickEventData, settings: AnnotationGeneratorSettings) -> NormalizedPoint {
        // Position annotation above and to the right of the click point
        let offsetX = settings.annotationOffset.x
        let offsetY = settings.annotationOffset.y

        var x = click.x + offsetX
        var y = click.y + offsetY

        // Clamp to valid range
        x = max(0.05, min(0.95, x))
        y = max(0.05, min(0.9, y))

        return NormalizedPoint(x: x, y: y)
    }

    // MARK: - Key Display Helpers (shared with KeystrokeGenerator)

    private static func displayName(for keyCode: UInt16, character: String?) -> String? {
        switch keyCode {
        case 36: return "Return"
        case 48: return "Tab"
        case 49: return "Space"
        case 51: return "Delete"
        case 53: return "Escape"
        case 71: return "Clear"
        case 76: return "Enter"
        case 117: return "⌦"
        case 123: return "←"
        case 124: return "→"
        case 125: return "↓"
        case 126: return "↑"
        case 122: return "F1"
        case 120: return "F2"
        case 99:  return "F3"
        case 118: return "F4"
        case 96:  return "F5"
        case 97:  return "F6"
        case 98:  return "F7"
        case 100: return "F8"
        case 101: return "F9"
        case 109: return "F10"
        case 103: return "F11"
        case 111: return "F12"
        case 115: return "Home"
        case 119: return "End"
        case 116: return "Page Up"
        case 121: return "Page Down"
        case 54, 55: return nil
        case 56, 60: return nil
        case 58, 61: return nil
        case 59, 62: return nil
        case 63: return nil
        default:
            if let char = character, !char.isEmpty {
                if let scalar = char.unicodeScalars.first, scalar.value < 0x20 {
                    let letterValue = scalar.value + 0x40
                    return Unicode.Scalar(letterValue).map { String($0) }
                }
                return char.uppercased()
            }
            return nil
        }
    }

    private static func modifierSymbols(from modifiers: KeyboardEventData.ModifierFlags) -> String {
        var symbols = ""
        if modifiers.contains(.control) { symbols += "⌃" }
        if modifiers.contains(.option)  { symbols += "⌥" }
        if modifiers.contains(.shift)   { symbols += "⇧" }
        if modifiers.contains(.command) { symbols += "⌘" }
        return symbols
    }

    // MARK: - Shortcut Descriptions

    private static func shortcutDescription(for shortcut: String, appBundleID: String?) -> String? {
        let commonShortcuts: [String: String] = [
            "⌘C": "Copy",
            "⌘V": "Paste",
            "⌘X": "Cut",
            "⌘Z": "Undo",
            "⌘⇧Z": "Redo",
            "⌘A": "Select All",
            "⌘S": "Save",
            "⌘O": "Open",
            "⌘N": "New",
            "⌘W": "Close Window",
            "⌘Q": "Quit",
            "⌘F": "Find",
            "⌘G": "Find Next",
            "⌘⇧G": "Find Previous",
            "⌘P": "Print",
            "⌘T": "New Tab",
            "⌘R": "Refresh",
            "⌘⇧R": "Hard Refresh",
            "⌘,": "Settings",
            "⌘/": "Toggle Comments",
            "⌘B": "Bold",
            "⌘I": "Italic",
            "⌘U": "Underline",
            "⌘]": "Indent",
            "⌘[": "Outdent",
            "⌘+": "Zoom In",
            "⌘-": "Zoom Out",
            "⌘0": "Reset Zoom",
            "⌘⇧3": "Screenshot",
            "⌘⇧4": "Screenshot Selection",
            "⌘⇧5": "Screenshot Menu",
            "⌘Space": "Spotlight",
            "⌘⇥": "Switch Apps",
            "⌘`": "Switch Windows",
            "⌃⌘F": "Fullscreen",
            "⌃⌘Space": "Emoji Picker",
            "⌃A": "Start of Line",
            "⌃E": "End of Line",
            "⌃K": "Delete to End",
            "⌃U": "Delete Line",
            "⌃W": "Delete Word",
            "⌥⌫": "Delete Word",
            "⌥⌦": "Delete Word Forward",
            "⌥←": "Previous Word",
            "⌥→": "Next Word",
            "⌘⌫": "Delete",
            "⌘↑": "Document Start",
            "⌘↓": "Document End",
            "⌘←": "Line Start",
            "⌘→": "Line End",
            "⇧⌘.": "Show Hidden Files"
        ]

        return commonShortcuts[shortcut]
    }

    private static func shortcutIcon(for shortcut: String) -> String {
        switch shortcut {
        case "⌘C": return "doc.on.clipboard"
        case "⌘V": return "doc.on.clipboard"
        case "⌘X": return "scissors"
        case "⌘Z", "⌘⇧Z": return "arrow.uturn.left"
        case "⌘A": return "text.badge.checkmark"
        case "⌘S": return "square.and.arrow.down"
        case "⌘O": return "folder"
        case "⌘N": return "plus.square"
        case "⌘W": return "xmark.square"
        case "⌘Q": return "power"
        case "⌘F": return "magnifyingglass"
        case "⌘P": return "printer"
        case "⌘T": return "plus.rectangle.on.rectangle"
        case "⌘R": return "arrow.clockwise"
        case "⌘,": return "gearshape"
        case "⌘B": return "bold"
        case "⌘I": return "italic"
        case "⌘U": return "underline"
        case "⌘Space": return "magnifyingglass"
        case "⌘⇥": return "app.connected.to.app.below.fill"
        case "⌃⌘F": return "arrow.up.left.and.arrow.down.right"
        case "⌃⌘Space": return "face.smiling"
        case "⌘⇧3", "⌘⇧4", "⌘⇧5": return "camera"
        default: return "keyboard"
        }
    }
}
