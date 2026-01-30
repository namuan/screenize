import SwiftUI

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

            textSection

            Divider()

            styleSection

            Divider()

            positionSection

            Spacer()
        }
        .padding(12)
    }

    private var header: some View {
        HStack {
            Image(systemName: "text.bubble")
                .foregroundColor(KeyframeColor.annotation)

            Text("Annotation Keyframe")
                .font(.headline)

            Spacer()
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
        VStack(alignment: .leading, spacing: 8) {
            Text("Position")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)

            PositionPicker(
                x: Binding(
                    get: { keyframe.position.x },
                    set: { keyframe.position = NormalizedPoint(x: $0, y: keyframe.position.y); onChange?() }
                ),
                y: Binding(
                    get: { keyframe.position.y },
                    set: { keyframe.position = NormalizedPoint(x: keyframe.position.x, y: $0); onChange?() }
                ),
                color: KeyframeColor.annotation,
                onChange: onChange
            )
            .frame(height: 100)

            VStack(spacing: 8) {
                HStack {
                    Text("X")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .frame(width: 16)

                    Slider(value: Binding(
                        get: { keyframe.position.x },
                        set: { keyframe.position = NormalizedPoint(x: $0, y: keyframe.position.y); onChange?() }
                    ), in: 0...1)

                    TextField("", value: Binding(
                        get: { Double(keyframe.position.x) },
                        set: { keyframe.position = NormalizedPoint(x: CGFloat($0), y: keyframe.position.y); onChange?() }
                    ), format: .number.precision(.fractionLength(2)))
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 50)
                }

                HStack {
                    Text("Y")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .frame(width: 16)

                    Slider(value: Binding(
                        get: { keyframe.position.y },
                        set: { keyframe.position = NormalizedPoint(x: keyframe.position.x, y: $0); onChange?() }
                    ), in: 0...1)

                    TextField("", value: Binding(
                        get: { Double(keyframe.position.y) },
                        set: { keyframe.position = NormalizedPoint(x: keyframe.position.x, y: CGFloat($0)); onChange?() }
                    ), format: .number.precision(.fractionLength(2)))
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 50)
                }
            }
        }
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
