import SwiftUI
import AppKit

/// Annotation keyframe inspector
struct AnnotationInspector: View {

    @Binding var keyframe: AnnotationKeyframe
    var onChange: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            Divider()

            timeSection

            Divider()

            typeSection

            Divider()

            if keyframe.type == .text {
                textSection

                Divider()
            }

            styleSection

            Divider()

            geometrySection

            Spacer()
        }
        .padding(12)
    }

    private var header: some View {
        HStack {
            Image(systemName: icon(for: keyframe.type))
                .foregroundColor(KeyframeColor.annotation)

            Text("Annotation Keyframe")
                .font(.headline)

            Spacer()
        }
    }

    private var typeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Type")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)

            Picker("", selection: $keyframe.type) {
                ForEach(AnnotationType.allCases, id: \.self) { type in
                    Label(type.displayName, systemImage: icon(for: type)).tag(type)
                }
            }
            .pickerStyle(.menu)
            .onChange(of: keyframe.type) { _ in onChange?() }
        }
    }

    private var timeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Time")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)

            HStack {
                TextField("", value: $keyframe.time, format: .number.precision(.fractionLength(2)))
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
                    .onSubmit { onChange?() }

                Text("s")
                    .foregroundColor(.secondary)

                Spacer()
            }
        }
    }

    private var textSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Text")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)

            TextField("Type annotation…", text: $keyframe.text, axis: .vertical)
                .lineLimit(2...6)
                .textFieldStyle(.roundedBorder)
                .onSubmit { onChange?() }
        }
    }

    private var styleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Duration")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)

                Spacer()

                Text(String(format: "%.1fs", keyframe.duration))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            HStack {
                Slider(value: $keyframe.duration, in: 0.5...10.0, step: 0.1)
                    .onChange(of: keyframe.duration) { _ in onChange?() }

                TextField("", value: Binding(
                    get: { Double(keyframe.duration) },
                    set: { keyframe.duration = $0; onChange?() }
                ), format: .number.precision(.fractionLength(1)))
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 50)
            }

            if keyframe.type == .text {
                HStack {
                    Text("Size")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("\(Int(keyframe.fontScale * 100))%")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                }

                Slider(value: $keyframe.fontScale, in: 0.02...0.10, step: 0.005)
                    .onChange(of: keyframe.fontScale) { _ in onChange?() }

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Text Color")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)

                        Spacer()
                    }

                    RGBAColorPickerRow(
                        color: $keyframe.textColor,
                        presets: [.white, .black, .yellow, .red, .blue],
                        supportsOpacity: false,
                        onChange: onChange
                    )

                    HStack {
                        Text("Background")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)

                        Spacer()
                    }

                    RGBAColorPickerRow(
                        color: $keyframe.textBackgroundColor,
                        presets: [
                            RGBAColor(r: 0.08, g: 0.08, b: 0.08, a: 0.78),
                            RGBAColor(r: 1.0, g: 1.0, b: 1.0, a: 0.85),
                            RGBAColor(r: 1.0, g: 0.86, b: 0.2, a: 0.85),
                            RGBAColor(r: 0.0, g: 0.0, b: 0.0, a: 0.55)
                        ],
                        supportsOpacity: true,
                        onChange: onChange
                    )
                }
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Color")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)

                        Spacer()
                    }

                    ArrowColorPicker(color: $keyframe.arrowColor, onChange: onChange)

                    HStack {
                        Text("Line")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)

                        Spacer()

                        Text(String(format: "%.1f%%", keyframe.arrowLineWidthScale * 100))
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                    }

                    Slider(value: $keyframe.arrowLineWidthScale, in: 0.002...0.03, step: 0.001)
                        .onChange(of: keyframe.arrowLineWidthScale) { _ in onChange?() }

                    if keyframe.type == .arrow {
                        HStack {
                            Text("Head")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)

                            Spacer()

                            Text(String(format: "%.1f%%", keyframe.arrowHeadScale * 100))
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.secondary)
                        }

                        Slider(value: $keyframe.arrowHeadScale, in: 0.01...0.10, step: 0.005)
                            .onChange(of: keyframe.arrowHeadScale) { _ in onChange?() }
                    }
                }
            }

            VStack(spacing: 6) {
                HStack {
                    Text("Fade In")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .frame(width: 50, alignment: .leading)

                    Slider(value: $keyframe.fadeInDuration, in: 0...0.5, step: 0.05)
                        .onChange(of: keyframe.fadeInDuration) { _ in onChange?() }

                    Text(String(format: "%.2fs", keyframe.fadeInDuration))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                        .frame(width: 40)
                }

                HStack {
                    Text("Fade Out")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .frame(width: 50, alignment: .leading)

                    Slider(value: $keyframe.fadeOutDuration, in: 0...1.0, step: 0.05)
                        .onChange(of: keyframe.fadeOutDuration) { _ in onChange?() }

                    Text(String(format: "%.2fs", keyframe.fadeOutDuration))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                        .frame(width: 40)
                }
            }
        }
    }

    private var positionSection: some View {
        pointSection(
            title: "Position",
            x: Binding(
                get: { keyframe.position.x },
                set: { keyframe.position = NormalizedPoint(x: $0, y: keyframe.position.y); onChange?() }
            ),
            y: Binding(
                get: { keyframe.position.y },
                set: { keyframe.position = NormalizedPoint(x: keyframe.position.x, y: $0); onChange?() }
            ),
            color: KeyframeColor.annotation
        )
    }

    @ViewBuilder
    private var geometrySection: some View {
        switch keyframe.type {
        case .text:
            positionSection
        case .arrow:
            twoPointSection(sectionTitle: "Arrow Points", startTitle: "Start", endTitle: "End")
        case .line:
            twoPointSection(sectionTitle: "Line Points", startTitle: "Start", endTitle: "End")
        case .rectangle, .ellipse, .circle:
            twoPointSection(sectionTitle: "Bounds", startTitle: "Corner 1", endTitle: "Corner 2")
        }
    }

    private func twoPointSection(sectionTitle: String, startTitle: String, endTitle: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(sectionTitle)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)

            pointSection(
                title: startTitle,
                x: Binding(
                    get: { keyframe.arrowStart.x },
                    set: { keyframe.arrowStart = NormalizedPoint(x: $0, y: keyframe.arrowStart.y); onChange?() }
                ),
                y: Binding(
                    get: { keyframe.arrowStart.y },
                    set: { keyframe.arrowStart = NormalizedPoint(x: keyframe.arrowStart.x, y: $0); onChange?() }
                ),
                color: Color.gray
            )

            pointSection(
                title: endTitle,
                x: Binding(
                    get: { keyframe.arrowEnd.x },
                    set: { keyframe.arrowEnd = NormalizedPoint(x: $0, y: keyframe.arrowEnd.y); onChange?() }
                ),
                y: Binding(
                    get: { keyframe.arrowEnd.y },
                    set: { keyframe.arrowEnd = NormalizedPoint(x: keyframe.arrowEnd.x, y: $0); onChange?() }
                ),
                color: keyframe.arrowColor.color
            )
        }
    }

    private func icon(for type: AnnotationType) -> String {
        switch type {
        case .text:
            return "text.bubble"
        case .arrow:
            return "arrow.up.right"
        case .line:
            return "line.diagonal"
        case .rectangle:
            return "rectangle"
        case .ellipse:
            return "capsule"
        case .circle:
            return "circle"
        }
    }

    private func pointSection(
        title: String,
        x: Binding<CGFloat>,
        y: Binding<CGFloat>,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)

            PositionPicker(x: x, y: y, color: color, onChange: onChange)
                .frame(height: 80)

            VStack(spacing: 8) {
                HStack {
                    Text("X")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .frame(width: 16)

                    Slider(value: x, in: 0...1)

                    TextField("", value: Binding(
                        get: { Double(x.wrappedValue) },
                        set: { x.wrappedValue = CGFloat($0); onChange?() }
                    ), format: .number.precision(.fractionLength(2)))
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 50)
                }

                HStack {
                    Text("Y")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .frame(width: 16)

                    Slider(value: y, in: 0...1)

                    TextField("", value: Binding(
                        get: { Double(y.wrappedValue) },
                        set: { y.wrappedValue = CGFloat($0); onChange?() }
                    ), format: .number.precision(.fractionLength(2)))
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 50)
                }
            }
        }
    }
}

private struct ArrowColorPicker: View {
    @Binding var color: RGBAColor
    var onChange: (() -> Void)?

    private let presets: [RGBAColor] = [.yellow, .red, .blue, .white]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(presets, id: \.self) { preset in
                colorButton(for: preset)
            }
        }
    }

    private func colorButton(for preset: RGBAColor) -> some View {
        let isSelected = color == preset

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                color = preset
            }
            onChange?()
        } label: {
            Circle()
                .fill(preset.color)
                .frame(width: 24, height: 24)
                .overlay(
                    Circle()
                        .stroke(Color.black.opacity(0.18), lineWidth: 0.75)
                )
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2)
                )
                .overlay(
                    Circle()
                        .stroke(isSelected ? preset.color : Color.clear, lineWidth: 1)
                        .padding(3)
                )
                .shadow(color: isSelected ? preset.color.opacity(0.5) : .clear, radius: 4)
        }
        .buttonStyle(.plain)
    }

    private static func rgba(from color: Color) -> RGBAColor {
        let nsColor = NSColor(color)
        let rgb = nsColor.usingColorSpace(.deviceRGB) ?? nsColor

        var r: CGFloat = 1
        var g: CGFloat = 1
        var b: CGFloat = 1
        var a: CGFloat = 1
        rgb.getRed(&r, green: &g, blue: &b, alpha: &a)
        return RGBAColor(r: r, g: g, b: b, a: a)
    }
}

private struct RGBAColorPickerRow: View {
    @Binding var color: RGBAColor
    let presets: [RGBAColor]
    let supportsOpacity: Bool
    var onChange: (() -> Void)?

    var body: some View {
        HStack(spacing: 8) {
            ForEach(presets, id: \.self) { preset in
                swatchButton(for: preset)
            }

            Spacer()

            ColorPicker(
                "",
                selection: Binding(
                    get: { color.color },
                    set: { newValue in
                        color = RGBAColorPickerRow.rgba(from: newValue)
                        onChange?()
                    }
                ),
                supportsOpacity: supportsOpacity
            )
            .labelsHidden()
        }
    }

    private func swatchButton(for preset: RGBAColor) -> some View {
        let isSelected = color == preset

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                color = preset
            }
            onChange?()
        } label: {
            Circle()
                .fill(preset.color)
                .frame(width: 24, height: 24)
                .overlay(
                    Circle()
                        .stroke(Color.black.opacity(0.18), lineWidth: 0.75)
                )
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2)
                )
                .overlay(
                    Circle()
                        .stroke(isSelected ? preset.color : Color.clear, lineWidth: 1)
                        .padding(3)
                )
                .shadow(color: isSelected ? preset.color.opacity(0.5) : .clear, radius: 4)
        }
        .buttonStyle(.plain)
    }

    private static func rgba(from color: Color) -> RGBAColor {
        let nsColor = NSColor(color)
        let rgb = nsColor.usingColorSpace(.deviceRGB) ?? nsColor

        var r: CGFloat = 1
        var g: CGFloat = 1
        var b: CGFloat = 1
        var a: CGFloat = 1
        rgb.getRed(&r, green: &g, blue: &b, alpha: &a)
        return RGBAColor(r: r, g: g, b: b, a: a)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var keyframe = AnnotationKeyframe(time: 1.0, text: "Hello annotation")
        var body: some View {
            AnnotationInspector(keyframe: $keyframe)
                .frame(width: 280)
        }
    }
    return PreviewWrapper()
}
