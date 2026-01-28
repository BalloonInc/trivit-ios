import Foundation
import CoreSpotlight
import UniformTypeIdentifiers
#if canImport(UIKit)
import UIKit
#endif

/// Service for indexing trivits in Spotlight search.
@MainActor
final class SpotlightService {
    // MARK: - Shared Instance

    static let shared = SpotlightService()

    // MARK: - Properties

    private let domainIdentifier = "be.ballooninc.trivit.trivits"
    private let searchableIndex = CSSearchableIndex.default()

    // MARK: - Initialization

    private init() {}

    // MARK: - Indexing

    /// Indexes a trivit for Spotlight search.
    /// - Parameter trivit: The trivit to index
    func index(_ trivit: Trivit) async {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .content)
        attributeSet.title = trivit.title
        attributeSet.contentDescription = "Count: \(trivit.count)"
        attributeSet.keywords = [trivit.title, "tally", "count", "counter", "trivit"]

        // Add thumbnail based on count
        attributeSet.thumbnailData = generateThumbnail(for: trivit)

        let item = CSSearchableItem(
            uniqueIdentifier: trivit.id.uuidString,
            domainIdentifier: domainIdentifier,
            attributeSet: attributeSet
        )

        // Items expire after 30 days of no update
        item.expirationDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())

        do {
            try await searchableIndex.indexSearchableItems([item])
        } catch {
            print("Failed to index trivit: \(error)")
        }
    }

    /// Indexes multiple trivits.
    /// - Parameter trivits: The trivits to index
    func indexAll(_ trivits: [Trivit]) async {
        let items = trivits.map { trivit -> CSSearchableItem in
            let attributeSet = CSSearchableItemAttributeSet(contentType: .content)
            attributeSet.title = trivit.title
            attributeSet.contentDescription = "Count: \(trivit.count)"
            attributeSet.keywords = [trivit.title, "tally", "count", "counter", "trivit"]
            attributeSet.thumbnailData = generateThumbnail(for: trivit)

            let item = CSSearchableItem(
                uniqueIdentifier: trivit.id.uuidString,
                domainIdentifier: domainIdentifier,
                attributeSet: attributeSet
            )
            item.expirationDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())
            return item
        }

        do {
            try await searchableIndex.indexSearchableItems(items)
        } catch {
            print("Failed to index trivits: \(error)")
        }
    }

    /// Removes a trivit from the Spotlight index.
    /// - Parameter trivitId: The ID of the trivit to remove
    func removeFromIndex(_ trivitId: UUID) async {
        do {
            try await searchableIndex.deleteSearchableItems(withIdentifiers: [trivitId.uuidString])
        } catch {
            print("Failed to remove trivit from index: \(error)")
        }
    }

    /// Removes all trivits from the Spotlight index.
    func removeAllFromIndex() async {
        do {
            try await searchableIndex.deleteSearchableItems(withDomainIdentifiers: [domainIdentifier])
        } catch {
            print("Failed to remove all trivits from index: \(error)")
        }
    }

    // MARK: - Deep Linking

    /// Extracts the trivit ID from a Spotlight activity.
    /// - Parameter userActivity: The user activity from Spotlight
    /// - Returns: The trivit ID, or nil if not a Spotlight activity
    func extractTrivitId(from userActivity: NSUserActivity) -> UUID? {
        guard userActivity.activityType == CSSearchableItemActionType,
              let identifier = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String,
              let uuid = UUID(uuidString: identifier) else {
            return nil
        }
        return uuid
    }

    // MARK: - Private Helpers

    private func generateThumbnail(for trivit: Trivit) -> Data? {
        // Generate a simple colored thumbnail
        // In a real implementation, this would render the actual tally marks
        let size = CGSize(width: 60, height: 60)

        #if canImport(UIKit)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            // Background
            let bgColor = UIColor(
                TrivitColors.color(at: trivit.colorIndex, scheme: 2, isDark: true)
            )
            bgColor.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            // Count text
            let text = "\(trivit.count)"
            let font = UIFont.systemFont(ofSize: 24, weight: .bold)
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.white
            ]
            let textSize = text.size(withAttributes: attrs)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            text.draw(in: textRect, withAttributes: attrs)
        }
        return image.pngData()
        #else
        return nil
        #endif
    }
}

// MARK: - Trivit Extension

extension Trivit {
    /// Updates this trivit in the Spotlight index.
    @MainActor
    func updateSpotlightIndex() async {
        await SpotlightService.shared.index(self)
    }

    /// Removes this trivit from the Spotlight index.
    @MainActor
    func removeFromSpotlightIndex() async {
        await SpotlightService.shared.removeFromIndex(id)
    }
}
