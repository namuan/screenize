import Foundation
import CoreGraphics
import SwiftUI

// MARK: - Keyframe Protocol

/// Time-based keyframe protocol
protocol TimedKeyframe: Codable, Identifiable {
    var id: UUID { get }
    var time: TimeInterval { get set }
    var easing: EasingCurve { get set }
}

/// Interpolatable value protocol
protocol Interpolatable {
    func interpolated(to target: Self, amount: CGFloat) -> Self
}

// MARK: - Transform Keyframe

/// Transform (zoom/pan) keyframe
struct TransformKeyframe: TimedKeyframe, Equatable {
    let id: UUID
    var time: TimeInterval           // Measured in seconds
    var zoom: CGFloat                // 1.0 = 100%, 2.0 = 200%
    var center: NormalizedPoint      // 0.0–1.0 (normalized, top-left origin)
    var easing: EasingCurve          // Interpolation mode to the next keyframe

    // MARK: - Computed Properties (backward compatibility)

    @available(*, deprecated, message: "Use center.x instead")
    var centerX: CGFloat {
        get { center.x }
        set { center = NormalizedPoint(x: newValue, y: center.y) }
    }

    @available(*, deprecated, message: "Use center.y instead")
    var centerY: CGFloat {
        get { center.y }
        set { center = NormalizedPoint(x: center.x, y: newValue) }
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        time: TimeInterval,
        zoom: CGFloat = 1.0,
        center: NormalizedPoint = .center,
        easing: EasingCurve = .springDefault
    ) {
        self.id = id
        self.time = time
        self.zoom = max(1.0, zoom)  // Minimum 1.0
        self.center = center.clamped()
        self.easing = easing
    }

    /// Legacy initializer
    init(
        id: UUID = UUID(),
        time: TimeInterval,
        zoom: CGFloat = 1.0,
        centerX: CGFloat = 0.5,
        centerY: CGFloat = 0.5,
        easing: EasingCurve = .springDefault
    ) {
        self.init(
            id: id,
            time: time,
            zoom: zoom,
            center: NormalizedPoint(x: centerX, y: centerY),
            easing: easing
        )
    }

    /// Identity keyframe (no zoom, centered)
    static func identity(at time: TimeInterval) -> Self {
        Self(time: time, zoom: 1.0, center: .center)
    }

    private static func clamp(_ value: CGFloat) -> CGFloat {
        max(0, min(1, value))
    }
}

/// Transform value (for interpolation)
struct TransformValue: Interpolatable, Equatable {
    let zoom: CGFloat
    let center: NormalizedPoint

    // MARK: - Computed Properties (backward compatibility)

    @available(*, deprecated, message: "Use center.x instead")
    var centerX: CGFloat { center.x }

    @available(*, deprecated, message: "Use center.y instead")
    var centerY: CGFloat { center.y }

    // MARK: - Initialization

    init(zoom: CGFloat, center: NormalizedPoint) {
        self.zoom = zoom
        self.center = center
    }

    /// Legacy initializer
    init(zoom: CGFloat, centerX: CGFloat, centerY: CGFloat) {
        self.zoom = zoom
        self.center = NormalizedPoint(x: centerX, y: centerY)
    }

    func interpolated(to target: Self, amount: CGFloat) -> Self {
        Self(
            zoom: zoom + (target.zoom - zoom) * amount,
            center: NormalizedPoint(
                x: center.x + (target.center.x - center.x) * amount,
                y: center.y + (target.center.y - center.y) * amount
            )
        )
    }

    /// Interpolation tuned for window mode
    /// In screen mode center and zoom interpolate independently,
    /// but in window mode visual position = center × zoom.
    /// Independently interpolating center and zoom would skew visual position.
    /// This method linearly interpolates the anchor point (center × zoom)
    /// so the visual position changes at the same rate as zoom.
    func interpolatedForWindowMode(to target: Self, amount: CGFloat) -> Self {
        // Interpolate zoom as usual
        let interpolatedZoom = zoom + (target.zoom - zoom) * amount

        // Anchor point = center × zoom (determines visual position)
        let startAnchorX = center.x * zoom
        let startAnchorY = center.y * zoom
        let endAnchorX = target.center.x * target.zoom
        let endAnchorY = target.center.y * target.zoom

        // Linearly interpolate the anchor point
        let interpolatedAnchorX = startAnchorX + (endAnchorX - startAnchorX) * amount
        let interpolatedAnchorY = startAnchorY + (endAnchorY - startAnchorY) * amount

        // interpolated center = interpolated anchor / interpolated zoom
        // Clamp zoom to avoid zero
        let safeZoom = max(interpolatedZoom, 0.001)
        let interpolatedCenterX = interpolatedAnchorX / safeZoom
        let interpolatedCenterY = interpolatedAnchorY / safeZoom

        return Self(
            zoom: interpolatedZoom,
            center: NormalizedPoint(x: interpolatedCenterX, y: interpolatedCenterY)
        )
    }

    static let identity = Self(zoom: 1.0, center: .center)
}

extension TransformKeyframe {
    var value: TransformValue {
        TransformValue(zoom: zoom, center: center)
    }
}

// MARK: - Ripple Keyframe

/// Ripple colors
enum RippleColor: Codable, Equatable, Hashable {
    case leftClick      // Blue
    case rightClick     // Orange
    case custom(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat)

    var cgColor: CGColor {
        switch self {
        case .leftClick:
            return CGColor(red: 0.2, green: 0.5, blue: 1.0, alpha: 0.6)
        case .rightClick:
            return CGColor(red: 1.0, green: 0.5, blue: 0.2, alpha: 0.6)
        case .custom(let r, let g, let b, let a):
            return CGColor(red: r, green: g, blue: b, alpha: a)
        }
    }

    /// SwiftUI Color
    var color: Color {
        Color(cgColor)
    }

    /// Preset colors (custom excluded)
    static let presetColors: [Self] = [.leftClick, .rightClick]
}

/// Ripple effect keyframe
struct RippleKeyframe: TimedKeyframe, Equatable {
    let id: UUID
    var time: TimeInterval           // Measured in seconds
    var position: NormalizedPoint    // 0.0–1.0 (normalized, top-left origin)
    var intensity: CGFloat           // 0.0–1.0
    var duration: TimeInterval       // Duration of the ripple
    var color: RippleColor
    var easing: EasingCurve          // Easing for the ripple animation

    // MARK: - Computed Properties (backward compatibility)

    @available(*, deprecated, message: "Use position.x instead")
    var x: CGFloat {
        get { position.x }
        set { position = NormalizedPoint(x: newValue, y: position.y) }
    }

    @available(*, deprecated, message: "Use position.y instead")
    var y: CGFloat {
        get { position.y }
        set { position = NormalizedPoint(x: position.x, y: newValue) }
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        time: TimeInterval,
        position: NormalizedPoint,
        intensity: CGFloat = 0.8,
        duration: TimeInterval = 0.4,
        color: RippleColor = .leftClick,
        easing: EasingCurve = .springBouncy
    ) {
        self.id = id
        self.time = time
        self.position = position.clamped()
        self.intensity = Self.clamp(intensity)
        self.duration = max(0.1, duration)
        self.color = color
        self.easing = easing
    }

    /// Legacy initializer
    init(
        id: UUID = UUID(),
        time: TimeInterval,
        x: CGFloat,
        y: CGFloat,
        intensity: CGFloat = 0.8,
        duration: TimeInterval = 0.4,
        color: RippleColor = .leftClick,
        easing: EasingCurve = .springBouncy
    ) {
        self.init(
            id: id,
            time: time,
            position: NormalizedPoint(x: x, y: y),
            intensity: intensity,
            duration: duration,
            color: color,
            easing: easing
        )
    }

    /// End time of the ripple
    var endTime: TimeInterval {
        time + duration
    }

    /// Check if the ripple is active at the given time
    func isActive(at currentTime: TimeInterval) -> Bool {
        currentTime >= time && currentTime <= endTime
    }

    /// Progress of the ripple at the given time (0.0–1.0)
    func progress(at currentTime: TimeInterval) -> CGFloat {
        guard isActive(at: currentTime), duration > 0 else { return 0 }
        let elapsed = currentTime - time
        return CGFloat(elapsed / duration)
    }

    private static func clamp(_ value: CGFloat) -> CGFloat {
        max(0, min(1, value))
    }
}

// MARK: - Cursor Style Keyframe (future extension)

/// Cursor styles
enum CursorStyle: String, Codable, CaseIterable {
    case arrow
    case pointer
    case iBeam
    case crosshair
    case openHand
    case closedHand
    case contextMenu

    var displayName: String {
        switch self {
        case .arrow: return "Arrow"
        case .pointer: return "Pointer"
        case .iBeam: return "I-Beam"
        case .crosshair: return "Crosshair"
        case .openHand: return "Open Hand"
        case .closedHand: return "Closed Hand"
        case .contextMenu: return "Context Menu"
        }
    }
}

/// Cursor style keyframe (for future extension)
struct CursorStyleKeyframe: TimedKeyframe, Equatable {
    let id: UUID
    var time: TimeInterval
    var position: NormalizedPoint?   // nil uses the original mouse data
    var style: CursorStyle
    var visible: Bool
    var scale: CGFloat
    var velocity: CGFloat?           // Velocity (used for motion blur intensity, normalized per second)
    var movementDirection: CGFloat?  // Movement direction (radians, for motion blur)
    var easing: EasingCurve

    // MARK: - Computed Properties (backward compatibility)

    @available(*, deprecated, message: "Use position?.x instead")
    var x: CGFloat? {
        get { position?.x }
        set {
            if let newValue = newValue {
                position = NormalizedPoint(x: newValue, y: position?.y ?? 0.5)
            } else {
                position = nil
            }
        }
    }

    @available(*, deprecated, message: "Use position?.y instead")
    var y: CGFloat? {
        get { position?.y }
        set {
            if let newValue = newValue {
                position = NormalizedPoint(x: position?.x ?? 0.5, y: newValue)
            } else {
                position = nil
            }
        }
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        time: TimeInterval,
        position: NormalizedPoint? = nil,
        style: CursorStyle = .arrow,
        visible: Bool = true,
        scale: CGFloat = 2.5,
        velocity: CGFloat? = nil,
        movementDirection: CGFloat? = nil,
        easing: EasingCurve = .springSnappy
    ) {
        self.id = id
        self.time = time
        self.position = position?.clamped()
        self.style = style
        self.visible = visible
        self.scale = max(0.5, scale)
        self.velocity = velocity
        self.movementDirection = movementDirection
        self.easing = easing
    }

    /// Legacy initializer (explicit x and y)
    init(
        id: UUID = UUID(),
        time: TimeInterval,
        x: CGFloat,
        y: CGFloat,
        style: CursorStyle = .arrow,
        visible: Bool = true,
        scale: CGFloat = 2.5,
        velocity: CGFloat? = nil,
        movementDirection: CGFloat? = nil,
        easing: EasingCurve = .springSnappy
    ) {
        self.init(
            id: id,
            time: time,
            position: NormalizedPoint(x: x, y: y),
            style: style,
            visible: visible,
            scale: scale,
            velocity: velocity,
            movementDirection: movementDirection,
            easing: easing
        )
    }
}

// MARK: - Keystroke Keyframe

/// Keystroke overlay keyframe
struct KeystrokeKeyframe: TimedKeyframe, Equatable {
    let id: UUID
    var time: TimeInterval           // Keystroke start time
    var displayText: String          // Display text (e.g., "⌘C", "⇧⌘Z")
    var duration: TimeInterval       // Overlay display duration
    var fadeInDuration: TimeInterval  // Fade-in duration
    var fadeOutDuration: TimeInterval // Fade-out duration
    var position: NormalizedPoint    // Overlay center position (default: bottom-center)
    var easing: EasingCurve

    init(
        id: UUID = UUID(),
        time: TimeInterval,
        displayText: String,
        duration: TimeInterval = 1.5,
        fadeInDuration: TimeInterval = 0.15,
        fadeOutDuration: TimeInterval = 0.3,
        position: NormalizedPoint = NormalizedPoint(x: 0.5, y: 0.95),
        easing: EasingCurve = .easeOut
    ) {
        self.id = id
        self.time = time
        self.displayText = displayText
        self.duration = max(0.2, duration)
        self.fadeInDuration = max(0, fadeInDuration)
        self.fadeOutDuration = max(0, fadeOutDuration)
        self.position = position
        self.easing = easing
    }

    /// Overlay end time
    var endTime: TimeInterval {
        time + duration
    }

    /// Check if the overlay is active at the given time
    func isActive(at currentTime: TimeInterval) -> Bool {
        currentTime >= time && currentTime <= endTime
    }

    /// Progress at the given time (0.0-1.0)
    func progress(at currentTime: TimeInterval) -> CGFloat {
        guard isActive(at: currentTime), duration > 0 else { return 0 }
        let elapsed = currentTime - time
        return CGFloat(elapsed / duration)
    }

    /// Opacity at the given time (with fade-in/out applied)
    func opacity(at currentTime: TimeInterval) -> CGFloat {
        guard isActive(at: currentTime) else { return 0 }
        let elapsed = currentTime - time
        let remaining = endTime - currentTime

        // Fade in
        if elapsed < fadeInDuration, fadeInDuration > 0 {
            return CGFloat(elapsed / fadeInDuration)
        }
        // Fade out
        if remaining < fadeOutDuration, fadeOutDuration > 0 {
            return CGFloat(remaining / fadeOutDuration)
        }
        // Fully opaque
        return 1.0
    }
}

// MARK: - Annotation Keyframe

/// Annotation type
enum AnnotationType: String, Codable, CaseIterable {
    case text
    case arrow
    case line
    case rectangle
    case ellipse
    case circle

    var displayName: String {
        switch self {
        case .text: return "Text"
        case .arrow: return "Arrow"
        case .line: return "Line"
        case .rectangle: return "Rectangle"
        case .ellipse: return "Ellipse"
        case .circle: return "Circle"
        }
    }
}

/// Simple RGBA color (Codable)
struct RGBAColor: Codable, Equatable, Hashable {
    var r: CGFloat
    var g: CGFloat
    var b: CGFloat
    var a: CGFloat

    init(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat = 1.0) {
        self.r = Self.clamp(r)
        self.g = Self.clamp(g)
        self.b = Self.clamp(b)
        self.a = Self.clamp(a)
    }

    var color: Color {
        Color(red: Double(r), green: Double(g), blue: Double(b), opacity: Double(a))
    }

    var cgColor: CGColor {
        CGColor(red: r, green: g, blue: b, alpha: a)
    }

    func multipliedAlpha(_ multiplier: CGFloat) -> Self {
        var copy = self
        copy.a = Self.clamp(a * multiplier)
        return copy
    }

    private static func clamp(_ value: CGFloat) -> CGFloat {
        max(0, min(1, value))
    }

    static let white = Self(r: 1.0, g: 1.0, b: 1.0)
    static let black = Self(r: 0.0, g: 0.0, b: 0.0)
    static let yellow = Self(r: 1.0, g: 0.86, b: 0.2)
    static let red = Self(r: 1.0, g: 0.25, b: 0.2)
    static let blue = Self(r: 0.2, g: 0.55, b: 1.0)
}

/// Annotation keyframe
struct AnnotationKeyframe: TimedKeyframe, Equatable {
    let id: UUID
    var time: TimeInterval           // Annotation start time
    var type: AnnotationType         // Text or arrow

    // Text
    var text: String                 // Text to display
    var duration: TimeInterval       // Display duration
    var fadeInDuration: TimeInterval // Fade-in duration
    var fadeOutDuration: TimeInterval // Fade-out duration
    var position: NormalizedPoint    // Overlay center position (UI uses top-left origin)
    var fontScale: CGFloat           // Relative to frame height (e.g. 0.04 = 4%)
    var textColor: RGBAColor          // Text color
    var textBackgroundColor: RGBAColor // Background color (supports alpha)

    // Arrow
    var arrowStart: NormalizedPoint  // Tail position (UI uses top-left origin)
    var arrowEnd: NormalizedPoint    // Head position (UI uses top-left origin)
    var arrowColor: RGBAColor
    var arrowLineWidthScale: CGFloat // Relative to frame height
    var arrowHeadScale: CGFloat      // Relative to frame height

    var easing: EasingCurve

    private enum CodingKeys: String, CodingKey {
        case id
        case time
        case type

        case text
        case duration
        case fadeInDuration
        case fadeOutDuration
        case position
        case fontScale
        case textColor
        case textBackgroundColor

        case arrowStart
        case arrowEnd
        case arrowColor
        case arrowLineWidthScale
        case arrowHeadScale

        case easing
    }

    private enum LegacyCodingKeys: String, CodingKey {
        case x
        case y
        case positionX
        case positionY
    }

    init(
        id: UUID = UUID(),
        time: TimeInterval,
        type: AnnotationType = .text,
        text: String,
        duration: TimeInterval = 2.0,
        fadeInDuration: TimeInterval = 0.15,
        fadeOutDuration: TimeInterval = 0.3,
        position: NormalizedPoint = NormalizedPoint(x: 0.5, y: 0.25),
        fontScale: CGFloat = 0.04,
        textColor: RGBAColor = .white,
        textBackgroundColor: RGBAColor = RGBAColor(r: 0.08, g: 0.08, b: 0.08, a: 0.78),
        arrowStart: NormalizedPoint = NormalizedPoint(x: 0.35, y: 0.35),
        arrowEnd: NormalizedPoint = NormalizedPoint(x: 0.65, y: 0.55),
        arrowColor: RGBAColor = .yellow,
        arrowLineWidthScale: CGFloat = 0.008,
        arrowHeadScale: CGFloat = 0.035,
        easing: EasingCurve = .easeOut
    ) {
        self.id = id
        self.time = time
        self.type = type
        self.text = text
        self.duration = max(0.2, duration)
        self.fadeInDuration = max(0, fadeInDuration)
        self.fadeOutDuration = max(0, fadeOutDuration)
        self.position = position.clamped()
        self.fontScale = max(0.015, min(0.12, fontScale))
        self.textColor = textColor
        self.textBackgroundColor = textBackgroundColor
        self.arrowStart = arrowStart.clamped()
        self.arrowEnd = arrowEnd.clamped()
        self.arrowColor = arrowColor
        self.arrowLineWidthScale = max(0.001, min(0.05, arrowLineWidthScale))
        self.arrowHeadScale = max(0.005, min(0.2, arrowHeadScale))
        self.easing = easing
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let legacy = try? decoder.container(keyedBy: LegacyCodingKeys.self)

        let id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        let time = try container.decode(TimeInterval.self, forKey: .time)
        let type = try container.decodeIfPresent(AnnotationType.self, forKey: .type) ?? .text

        let text = try container.decodeIfPresent(String.self, forKey: .text) ?? ""
        let duration = try container.decodeIfPresent(TimeInterval.self, forKey: .duration) ?? 2.0
        let fadeInDuration = try container.decodeIfPresent(TimeInterval.self, forKey: .fadeInDuration) ?? 0.15
        let fadeOutDuration = try container.decodeIfPresent(TimeInterval.self, forKey: .fadeOutDuration) ?? 0.3
        let decodedPosition = try container.decodeIfPresent(NormalizedPoint.self, forKey: .position)
        let legacyX = try legacy?.decodeIfPresent(CGFloat.self, forKey: .x)
            ?? legacy?.decodeIfPresent(CGFloat.self, forKey: .positionX)
        let legacyY = try legacy?.decodeIfPresent(CGFloat.self, forKey: .y)
            ?? legacy?.decodeIfPresent(CGFloat.self, forKey: .positionY)

        let position: NormalizedPoint
        if let decodedPosition {
            position = decodedPosition
        } else if let legacyX, let legacyY {
            position = NormalizedPoint(x: legacyX, y: legacyY)
        } else {
            position = NormalizedPoint(x: 0.5, y: 0.25)
        }
        let fontScale = try container.decodeIfPresent(CGFloat.self, forKey: .fontScale) ?? 0.04
        let textColor = try container.decodeIfPresent(RGBAColor.self, forKey: .textColor) ?? .white
        let textBackgroundColor = try container.decodeIfPresent(RGBAColor.self, forKey: .textBackgroundColor)
            ?? RGBAColor(r: 0.08, g: 0.08, b: 0.08, a: 0.78)

        let arrowStart = try container.decodeIfPresent(NormalizedPoint.self, forKey: .arrowStart)
            ?? NormalizedPoint(x: 0.35, y: 0.35)
        let arrowEnd = try container.decodeIfPresent(NormalizedPoint.self, forKey: .arrowEnd)
            ?? NormalizedPoint(x: 0.65, y: 0.55)
        let arrowColor = try container.decodeIfPresent(RGBAColor.self, forKey: .arrowColor) ?? .yellow
        let arrowLineWidthScale = try container.decodeIfPresent(CGFloat.self, forKey: .arrowLineWidthScale) ?? 0.008
        let arrowHeadScale = try container.decodeIfPresent(CGFloat.self, forKey: .arrowHeadScale) ?? 0.035

        let easing = try container.decodeIfPresent(EasingCurve.self, forKey: .easing) ?? .easeOut

        self.init(
            id: id,
            time: time,
            type: type,
            text: text,
            duration: duration,
            fadeInDuration: fadeInDuration,
            fadeOutDuration: fadeOutDuration,
            position: position,
            fontScale: fontScale,
            textColor: textColor,
            textBackgroundColor: textBackgroundColor,
            arrowStart: arrowStart,
            arrowEnd: arrowEnd,
            arrowColor: arrowColor,
            arrowLineWidthScale: arrowLineWidthScale,
            arrowHeadScale: arrowHeadScale,
            easing: easing
        )
    }

    /// Overlay end time
    var endTime: TimeInterval {
        time + duration
    }

    /// Check if the overlay is active at the given time
    func isActive(at currentTime: TimeInterval) -> Bool {
        currentTime >= time && currentTime <= endTime
    }

    /// Progress at the given time (0.0-1.0)
    func progress(at currentTime: TimeInterval) -> CGFloat {
        guard isActive(at: currentTime), duration > 0 else { return 0 }
        let elapsed = currentTime - time
        return CGFloat(elapsed / duration)
    }

    /// Opacity at the given time (with fade-in/out applied)
    func opacity(at currentTime: TimeInterval) -> CGFloat {
        guard isActive(at: currentTime) else { return 0 }
        let elapsed = currentTime - time
        let remaining = endTime - currentTime

        if elapsed < fadeInDuration, fadeInDuration > 0 {
            return CGFloat(elapsed / fadeInDuration)
        }
        if remaining < fadeOutDuration, fadeOutDuration > 0 {
            return CGFloat(remaining / fadeOutDuration)
        }
        return 1.0
    }
}
