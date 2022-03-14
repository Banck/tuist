import Foundation
import TSCBasic
import TuistCore

public final class Cache: CacheStoring {
    // MARK: - Attributes

    private let storageProvider: CacheStorageProviding

    // MARK: - Init

    /// Initializes the cache with its attributes.
    /// - Parameter storageProvider: An instance that returns the storages to be used.
    public init(storageProvider: CacheStorageProviding) {
        self.storageProvider = storageProvider
    }

    // MARK: - CacheStoring

    public func exists(name: String, hash: String) async throws -> Bool {
        for storage in try storageProvider.storages() {
            if try await storage.exists(name: name, hash: hash) {
                return true
            }
        }
        return false
    }

    public func fetch(name: String, hash: String) async throws -> AbsolutePath {
        var throwingError: Error = CacheLocalStorageError.compiledArtifactNotFound(hash: hash)
        for storage in try storageProvider.storages() {
            do {
                return try await storage.fetch(name: name, hash: hash)
            } catch {
                throwingError = error
                continue
            }
        }
        throw throwingError
    }

    public func store(name: String, hash: String, paths: [AbsolutePath]) async throws {
        _ = try await storageProvider.storages().concurrentMap { storage in
            try await storage.store(name: name, hash: hash, paths: paths)
        }
    }
}
