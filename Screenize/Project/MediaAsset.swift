import Foundation
import CoreGraphics

/// Media asset information
/// References to the video and mouse data files within a .screenize package
struct MediaAsset: Codable {
    /// Relative path to video file within the package (e.g. "recording/video.mp4")
    var videoPath: String

    /// Relative path to mouse data file within the package (e.g. "recording/mouse.json")
    var mouseDataPath: String

    /// Package root URL for resolving relative paths (not serialized)
    var packageURL: URL?

    /// Original video resolution (pixels)
    let pixelSize: CGSize

    /// Original frame rate
    let frameRate: Double

    /// Total duration (seconds)
    let duration: TimeInterval

    // MARK: - Initializers

    init(
        videoPath: String = "recording/video.mp4",
        mouseDataPath: String = "recording/mouse.json",
        packageURL: URL? = nil,
        pixelSize: CGSize,
        frameRate: Double,
        duration: TimeInterval
    ) {
        self.videoPath = videoPath
        self.mouseDataPath = mouseDataPath
        self.packageURL = packageURL
        self.pixelSize = pixelSize
        self.frameRate = frameRate
        self.duration = duration
    }

    // MARK: - Resolved URLs

    /// Resolved absolute URL to the video file
    var videoURL: URL {
        if let base = packageURL {
            return base.appendingPathComponent(videoPath)
        }
        // Legacy fallback: treat path as absolute
        return URL(fileURLWithPath: videoPath)
    }

    /// Resolved absolute URL to the mouse data file
    var mouseDataURL: URL {
        if let base = packageURL {
            return base.appendingPathComponent(mouseDataPath)
        }
        return URL(fileURLWithPath: mouseDataPath)
    }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        // New package format keys
        case videoPath, mouseDataPath
        // Legacy .fsproj format keys
        case videoURL, mouseDataURL
        // Shared keys
        case pixelSize, frameRate, duration
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        pixelSize = try container.decode(CGSize.self, forKey: .pixelSize)
        frameRate = try container.decode(Double.self, forKey: .frameRate)
        duration = try container.decode(TimeInterval.self, forKey: .duration)

        // Try new relative path keys first, fall back to legacy absolute URL keys
        if let vPath = try container.decodeIfPresent(String.self, forKey: .videoPath) {
            videoPath = vPath
            mouseDataPath = try container.decodeIfPresent(String.self, forKey: .mouseDataPath)
                ?? "recording/mouse.json"
        } else {
            // Legacy format: absolute URLs stored as URL values
            let vURL = try container.decode(URL.self, forKey: .videoURL)
            let mURL = try container.decode(URL.self, forKey: .mouseDataURL)
            videoPath = vURL.path
            mouseDataPath = mURL.path
        }
        packageURL = nil
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(videoPath, forKey: .videoPath)
        try container.encode(mouseDataPath, forKey: .mouseDataPath)
        try container.encode(pixelSize, forKey: .pixelSize)
        try container.encode(frameRate, forKey: .frameRate)
        try container.encode(duration, forKey: .duration)
    }

    // MARK: - Validation

    /// Check whether both media files exist
    var filesExist: Bool {
        FileManager.default.fileExists(atPath: videoURL.path) &&
        FileManager.default.fileExists(atPath: mouseDataURL.path)
    }

    /// Check whether the video file exists
    var videoExists: Bool {
        FileManager.default.fileExists(atPath: videoURL.path)
    }

    /// Check whether the mouse data file exists
    var mouseDataExists: Bool {
        FileManager.default.fileExists(atPath: mouseDataURL.path)
    }

    // MARK: - Computed Properties

    /// Aspect ratio
    var aspectRatio: CGFloat {
        guard pixelSize.height > 0 else { return 16.0 / 9.0 }
        return pixelSize.width / pixelSize.height
    }

    /// Total frame count
    var totalFrames: Int {
        Int(duration * frameRate)
    }

    /// Frame duration (seconds)
    var frameDuration: TimeInterval {
        guard frameRate > 0 else { return 1.0 / 60.0 }
        return 1.0 / frameRate
    }
}
