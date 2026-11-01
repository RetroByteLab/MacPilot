import Foundation

/// A local inventory, not permission to execute a model-supplied path or command.
struct InstalledApplicationCatalog {
    struct Application: Identifiable, Equatable {
        let name: String
        let bundleIdentifier: String
        let url: URL
        let aliases: [String]

        // Keep separate copies visible instead of choosing an arbitrary installation.
        var id: String { url.path }
    }

    struct ScanIssue: Equatable {
        let url: URL
        let message: String
    }

    struct Snapshot {
        let applications: [Application]
        let issues: [ScanIssue]

        /// Zero results means unknown; multiple results require a user choice.
        /// Natural-language interpretation belongs in the later AI integration.
        func matches(_ nameOrBundleIdentifier: String) -> [Application] {
            let query = InstalledApplicationCatalog.normalized(nameOrBundleIdentifier)
            guard !query.isEmpty else { return [] }
            return applications.filter { app in
                ([app.name, app.bundleIdentifier] + app.aliases).contains {
                    InstalledApplicationCatalog.normalized($0) == query
                }
            }
        }
    }

    /// Conventional install locations, including Finder and other system apps.
    /// Additional folders can be supplied after the user grants access to them.
    static var defaultRoots: [URL] {
        let paths = ["/Applications", "/System/Applications", "/System/Library/CoreServices"]
        return paths.map { URL(fileURLWithPath: $0, isDirectory: true) }
            + FileManager.default.urls(for: .applicationDirectory, in: .userDomainMask)
    }

    /// Run scans on demand rather than polling or walking the entire disk.
    /// Delivery is on the main queue; the caller can cache the returned snapshot.
    static func discover(
        in roots: [URL] = defaultRoots,
        completion: @escaping (Snapshot) -> Void
    ) {
        DispatchQueue.global(qos: .utility).async {
            let snapshot = scan(in: roots)
            DispatchQueue.main.async { completion(snapshot) }
        }
    }

    /// Synchronous entry point for background workers and standalone validation.
    /// Nested folders are scanned, but application/package contents are excluded.
    static func scan(in roots: [URL] = defaultRoots) -> Snapshot {
        let manager = FileManager.default
        var applications: [Application] = []
        var issues: [ScanIssue] = []
        var visited = Set<String>()
        var pending = roots

        while let directory = pending.popLast() {
            let canonical = directory.resolvingSymlinksInPath().standardizedFileURL
            guard visited.insert(canonical.path).inserted else { continue }
            do {
                let children = try manager.contentsOfDirectory(
                    at: canonical,
                    includingPropertiesForKeys: [.isDirectoryKey, .isPackageKey, .isSymbolicLinkKey],
                    options: [.skipsHiddenFiles]
                )
                for child in children {
                    do {
                        let values = try child.resourceValues(
                            forKeys: [.isDirectoryKey, .isPackageKey, .isSymbolicLinkKey]
                        )
                        guard values.isDirectory == true else { continue }
                        if child.pathExtension.lowercased() == "app" {
                            let url = child.resolvingSymlinksInPath().standardizedFileURL
                            guard visited.insert(url.path).inserted,
                                  let app = application(at: url) else { continue }
                            applications.append(app)
                        } else if values.isPackage != true && values.isSymbolicLink != true {
                            pending.append(child)
                        }
                    } catch {
                        issues.append(ScanIssue(url: child, message: error.localizedDescription))
                    }
                }
            } catch {
                // A missing ~/Applications directory is normal. Access failures
                // remain visible so a sandbox-limited inventory is not called complete.
                if (error as NSError).code != NSFileReadNoSuchFileError {
                    issues.append(ScanIssue(url: canonical, message: error.localizedDescription))
                }
            }
        }

        applications.sort {
            let order = $0.name.localizedStandardCompare($1.name)
            return order == .orderedSame ? $0.url.path < $1.url.path : order == .orderedAscending
        }
        return Snapshot(applications: applications, issues: issues)
    }

    private static func application(at url: URL) -> Application? {
        guard let bundle = Bundle(url: url),
              let identifier = bundle.bundleIdentifier, !identifier.isEmpty,
              bundle.infoDictionary?["CFBundlePackageType"] as? String == "APPL",
              let executable = bundle.executableURL,
              FileManager.default.isExecutableFile(atPath: executable.path) else { return nil }

        // Exclude background helpers from the user-facing launch inventory.
        for key in ["LSUIElement", "LSBackgroundOnly"] {
            let value = bundle.infoDictionary?[key]
            if (value as? NSNumber)?.boolValue == true { return nil }
            if let text = value as? String,
               ["1", "true", "yes"].contains(text.lowercased()) { return nil }
        }

        let keys = ["CFBundleDisplayName", "CFBundleName"]
        let names = keys.compactMap { bundle.localizedInfoDictionary?[$0] as? String }
            + keys.compactMap { bundle.infoDictionary?[$0] as? String }
            + [url.deletingPathExtension().lastPathComponent]
        let aliases = Array(Set(names.map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }.filter { !$0.isEmpty })).sorted()
        let name = names.first { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            ?? url.deletingPathExtension().lastPathComponent
        return Application(name: name, bundleIdentifier: identifier, url: url, aliases: aliases)
    }

    private static func normalized(_ text: String) -> String {
        text.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
            .folding(options: [.caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
    }
}
