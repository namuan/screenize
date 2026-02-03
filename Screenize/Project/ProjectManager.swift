import Foundation
import SwiftUI

/// Project manager
/// Handles saving, loading, and managing recent projects
@MainActor
final class ProjectManager: ObservableObject {

    // MARK: - Published Properties

    /// Recent project list
    @Published private(set) var recentProjects: [RecentProjectInfo] = []

    /// Loading indicator
    @Published private(set) var isLoading: Bool = false

    /// Error message
    @Published private(set) var errorMessage: String?

    // MARK: - Properties

    /// Project package extension
    static let projectExtension = "screenize"

    /// Legacy project file extension
    static let legacyProjectExtension = "fsproj"

    /// Maximum number of recent projects
    private let maxRecentProjects = 10

    /// UserDefaults key
    private let recentProjectsKey = "RecentProjects"

    /// File manager
    private let fileManager = FileManager.default

    // MARK: - Singleton

    static let shared = ProjectManager()

    private init() {
        loadRecentProjects()
    }

    // MARK: - Package Creation

    /// Create a .screenize package and move media files into it
    /// - Parameters:
    ///   - videoURL: Original video file URL
    ///   - mouseDataURL: Mouse data file URL (optional, auto-detected if nil)
    /// - Returns: Package URL
    func createPackage(
        for videoURL: URL,
        mouseDataURL: URL? = nil
    ) throws -> URL {
        let videoName = videoURL.deletingPathExtension().lastPathComponent
        let parentDirectory = videoURL.deletingLastPathComponent()
        let packageURL = parentDirectory.appendingPathComponent("\(videoName).\(Self.projectExtension)")

        // Create the package and recording subdirectory
        let recordingDir = packageURL.appendingPathComponent("recording")
        try fileManager.createDirectory(at: recordingDir, withIntermediateDirectories: true)

        // Move the video into recording/video.mp4
        let destVideoURL = recordingDir.appendingPathComponent("video.mp4")
        if !fileManager.fileExists(atPath: destVideoURL.path) {
            if fileManager.fileExists(atPath: videoURL.path) {
                try fileManager.moveItem(at: videoURL, to: destVideoURL)
            }
        }

        // Move the mouse data into recording/mouse.json
        let mouseURL = mouseDataURL ?? findMouseDataURL(for: videoURL)
        let destMouseURL = recordingDir.appendingPathComponent("mouse.json")
        if !fileManager.fileExists(atPath: destMouseURL.path) {
            if fileManager.fileExists(atPath: mouseURL.path) {
                try fileManager.moveItem(at: mouseURL, to: destMouseURL)
            }
        }

        return packageURL
    }

    /// Find the mouse data file associated with a video
    private func findMouseDataURL(for videoURL: URL) -> URL {
        let baseName = videoURL.deletingPathExtension().lastPathComponent
        let directory = videoURL.deletingLastPathComponent()

        let candidates = [
            "\(baseName).mouse.json",
            "\(baseName)_mouse.json",
            "mouse.json"
        ]

        for candidate in candidates {
            let candidateURL = directory.appendingPathComponent(candidate)
            if fileManager.fileExists(atPath: candidateURL.path) {
                return candidateURL
            }
        }

        return directory.appendingPathComponent("\(baseName).mouse.json")
    }

    // MARK: - Save

    /// Save a project to its .screenize package
    /// - Parameters:
    ///   - project: Project to save
    ///   - url: Package URL (nil uses default location)
    /// - Returns: Saved package URL
    func save(_ project: ScreenizeProject, to url: URL? = nil) async throws -> URL {
        let saveURL: URL

        if let url = url {
            saveURL = url
        } else {
            // Default save location: ~/Movies/Screenize/<name>.screenize
            let moviesDir = fileManager.urls(for: .moviesDirectory, in: .userDomainMask).first!
            let screenizeDir = moviesDir.appendingPathComponent("Screenize")
            if !fileManager.fileExists(atPath: screenizeDir.path) {
                try fileManager.createDirectory(at: screenizeDir, withIntermediateDirectories: true)
            }
            saveURL = screenizeDir.appendingPathComponent("\(project.name).\(Self.projectExtension)")
        }

        // Delegate to ScreenizeProject.save(to:)
        try project.save(to: saveURL)

        // Add to recent projects
        await addToRecentProjects(project, url: saveURL)

        return saveURL
    }

    // MARK: - Load

    /// Load a project from a .screenize package or legacy .fsproj file
    /// - Parameter url: Package URL or legacy project file URL
    /// - Returns: Loaded project
    func load(from url: URL) async throws -> ScreenizeProject {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        // Auto-migrate legacy .fsproj files
        if url.pathExtension.lowercased() == Self.legacyProjectExtension {
            let packageURL = try migrateToPackage(legacyProjectURL: url)
            let project = try ScreenizeProject.load(from: packageURL)

            guard project.media.videoExists else {
                throw ProjectManagerError.videoFileNotFound(project.media.videoURL)
            }

            await addToRecentProjects(project, url: packageURL)
            return project
        }

        // Load from package
        let project = try ScreenizeProject.load(from: url)

        // Ensure the media file exists
        guard project.media.videoExists else {
            throw ProjectManagerError.videoFileNotFound(project.media.videoURL)
        }

        // Add to recent projects
        await addToRecentProjects(project, url: url)

        return project
    }

    /// Attempt to load from a URL (returns nil on failure)
    func tryLoad(from url: URL) async -> ScreenizeProject? {
        do {
            return try await load(from: url)
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    // MARK: - Migration

    /// Migrate a legacy .fsproj project to the .screenize package format
    /// - Parameter legacyProjectURL: URL to the .fsproj file
    /// - Returns: URL to the new .screenize package
    func migrateToPackage(legacyProjectURL: URL) throws -> URL {
        // Load the legacy project (single JSON file with absolute paths)
        let data = try Data(contentsOf: legacyProjectURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let legacyProject = try decoder.decode(ScreenizeProject.self, from: data)

        let videoURL = legacyProject.media.videoURL
        let mouseDataURL = legacyProject.media.mouseDataURL

        // Create the package
        let packageURL = try createPackage(for: videoURL, mouseDataURL: mouseDataURL)

        // Create a new project with relative paths
        var migratedProject = legacyProject
        migratedProject.media = MediaAsset(
            videoPath: "recording/video.mp4",
            mouseDataPath: "recording/mouse.json",
            packageURL: packageURL,
            pixelSize: legacyProject.media.pixelSize,
            frameRate: legacyProject.media.frameRate,
            duration: legacyProject.media.duration
        )
        migratedProject.version = 2

        try migratedProject.save(to: packageURL)

        // Remove the old .fsproj file
        try? fileManager.removeItem(at: legacyProjectURL)

        return packageURL
    }

    // MARK: - Recent Projects

    /// Add to recent projects
    private func addToRecentProjects(_ project: ScreenizeProject, url: URL) async {
        let info = RecentProjectInfo(
            id: project.id,
            name: project.name,
            projectURL: url,
            duration: project.media.duration,
            lastOpened: Date()
        )

        // Remove existing entries
        recentProjects.removeAll { $0.id == project.id || $0.projectURL == url }

        // Insert at the front
        recentProjects.insert(info, at: 0)

        // Maintain the maximum count
        if recentProjects.count > maxRecentProjects {
            recentProjects = Array(recentProjects.prefix(maxRecentProjects))
        }

        // Save
        saveRecentProjects()
    }

    /// Save the recent project list
    private func saveRecentProjects() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(recentProjects) {
            UserDefaults.standard.set(data, forKey: recentProjectsKey)
        }
    }

    /// Load the recent project list
    private func loadRecentProjects() {
        guard let data = UserDefaults.standard.data(forKey: recentProjectsKey),
              let projects = try? JSONDecoder().decode([RecentProjectInfo].self, from: data) else {
            return
        }

        // Filter out projects that no longer exist
        recentProjects = projects.filter { info in
            fileManager.fileExists(atPath: info.projectURL.path)
        }
    }

    /// Remove a recent project
    func removeFromRecent(_ id: UUID) {
        recentProjects.removeAll { $0.id == id }
        saveRecentProjects()
    }

    /// Clear recent projects
    func clearRecentProjects() {
        recentProjects.removeAll()
        saveRecentProjects()
    }

    // MARK: - Delete

    /// Delete a project package
    func delete(at url: URL) throws {
        try fileManager.removeItem(at: url)

        // Also remove it from recent projects
        recentProjects.removeAll { $0.projectURL == url }
        saveRecentProjects()
    }

    // MARK: - Utilities

    /// Check if the URL points to a project file or package
    static func isProjectFile(_ url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        return ext == projectExtension || ext == legacyProjectExtension
    }

    /// Find an existing project for a video file
    func findExistingProject(for videoURL: URL) -> URL? {
        let videoName = videoURL.deletingPathExtension().lastPathComponent
        let directory = videoURL.deletingLastPathComponent()

        // Check for .screenize package first
        let packageURL = directory.appendingPathComponent("\(videoName).\(Self.projectExtension)")
        if fileManager.fileExists(atPath: packageURL.path) {
            return packageURL
        }

        // Check for legacy .fsproj
        let legacyURL = directory.appendingPathComponent("\(videoName).\(Self.legacyProjectExtension)")
        if fileManager.fileExists(atPath: legacyURL.path) {
            return legacyURL
        }

        return nil
    }
}

// MARK: - Recent Project Info

/// Recent project info
struct RecentProjectInfo: Codable, Identifiable {
    let id: UUID
    let name: String
    let projectURL: URL
    let duration: TimeInterval
    let lastOpened: Date

    // MARK: - Codable (backward compatible)

    private enum CodingKeys: String, CodingKey {
        case id, name, projectURL, duration, lastOpened
        // Legacy key (ignored on decode, not encoded)
        case videoURL
    }

    init(id: UUID, name: String, projectURL: URL, duration: TimeInterval, lastOpened: Date) {
        self.id = id
        self.name = name
        self.projectURL = projectURL
        self.duration = duration
        self.lastOpened = lastOpened
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        projectURL = try container.decode(URL.self, forKey: .projectURL)
        duration = try container.decode(TimeInterval.self, forKey: .duration)
        lastOpened = try container.decode(Date.self, forKey: .lastOpened)
        // Legacy videoURL is silently ignored
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(projectURL, forKey: .projectURL)
        try container.encode(duration, forKey: .duration)
        try container.encode(lastOpened, forKey: .lastOpened)
    }

    /// Formatted date
    var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastOpened, relativeTo: Date())
    }

    /// Formatted duration
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Errors

enum ProjectManagerError: Error, LocalizedError {
    case videoFileNotFound(URL)
    case mouseDataNotFound(URL)
    case invalidProjectFile
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .videoFileNotFound(let url):
            return "Video file not found: \(url.lastPathComponent)"
        case .mouseDataNotFound(let url):
            return "Mouse data file not found: \(url.lastPathComponent)"
        case .invalidProjectFile:
            return "Invalid project file format"
        case .saveFailed:
            return "Failed to save project"
        }
    }
}
