import Foundation
import CoreGraphics

/// Screenize project file
/// Contains recorded media and timeline editing data
struct ScreenizeProject: Codable, Identifiable {
    let id: UUID
    var version: Int = 2
    var name: String
    var createdAt: Date
    var modifiedAt: Date

    // Media reference
    var media: MediaAsset
    var captureMeta: CaptureMeta

    // Timeline
    var timeline: Timeline

    // Rendering settings
    var renderSettings: RenderSettings

    // Frame analysis cache (for Smart Zoom)
    var frameAnalysisCache: [VideoFrameAnalyzer.FrameAnalysis]?
    var frameAnalysisVersion: Int = 1  // Algorithm version (re-run analysis when it changes)

    init(
        id: UUID = UUID(),
        name: String,
        media: MediaAsset,
        captureMeta: CaptureMeta,
        timeline: Timeline = Timeline(),
        renderSettings: RenderSettings = RenderSettings(),
        frameAnalysisCache: [VideoFrameAnalyzer.FrameAnalysis]? = nil
    ) {
        self.id = id
        self.version = 2
        self.name = name
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.media = media
        self.captureMeta = captureMeta
        self.timeline = timeline
        self.renderSettings = renderSettings
        self.frameAnalysisCache = frameAnalysisCache
        self.frameAnalysisVersion = 1
    }

    // MARK: - File Operations

    /// Save the project into a .screenize package directory
    func save(to packageURL: URL) throws {
        var project = self
        project.modifiedAt = Date()

        let fm = FileManager.default

        // Create the package directory if needed
        if !fm.fileExists(atPath: packageURL.path) {
            try fm.createDirectory(at: packageURL, withIntermediateDirectories: true)
        }

        // Create the recording subdirectory if needed
        let recordingDir = packageURL.appendingPathComponent("recording")
        if !fm.fileExists(atPath: recordingDir.path) {
            try fm.createDirectory(at: recordingDir, withIntermediateDirectories: true)
        }

        // Write project.json
        let projectFileURL = packageURL.appendingPathComponent(Self.projectFileName)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(project)
        try data.write(to: projectFileURL, options: .atomic)
    }

    /// Load the project from a package directory or legacy .fsproj file
    static func load(from url: URL) throws -> Self {
        let fm = FileManager.default
        var isDirectory: ObjCBool = false
        fm.fileExists(atPath: url.path, isDirectory: &isDirectory)

        if isDirectory.boolValue {
            // Package format: read project.json from inside the directory
            let projectFileURL = url.appendingPathComponent(projectFileName)
            let data = try Data(contentsOf: projectFileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            var project = try decoder.decode(Self.self, from: data)
            project.media.packageURL = url
            return project
        } else {
            // [LEGACY .fsproj] Single JSON file format.
            // Remove: Delete this else-block and the isDirectory check after migration period.
            // Keep only the package-format code above.
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(Self.self, from: data)
        }
    }

    // MARK: - Computed Properties

    /// Project package extension
    static let fileExtension = "screenize"

    /// Project data filename within the package
    static let projectFileName = "project.json"

    /// Total duration
    var duration: TimeInterval {
        media.duration
    }

    /// Total frame count
    var totalFrames: Int {
        Int(media.duration * media.frameRate)
    }

    /// backgroundEnabled triggers window mode rendering (applies to both window and display capture)
    var isWindowMode: Bool {
        renderSettings.backgroundEnabled
    }
}
