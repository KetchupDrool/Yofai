import Foundation

/// Local listing item type. Not an Etsy taxonomy ID.
enum ListingItemType: String, CaseIterable, Identifiable, Codable {
    case physical = "Physical"
    case digital = "Digital"

    var id: String { rawValue }
}

struct ListingVariation: Codable, Identifiable, Equatable {
    var id: UUID
    var isEnabled: Bool
    var name: String
    var options: [String]
    var priceDifferenceText: String
    var quantity: Int
    var sku: String

    init(
        id: UUID = UUID(),
        isEnabled: Bool = true,
        name: String = "",
        options: [String] = [],
        priceDifferenceText: String = "",
        quantity: Int = 1,
        sku: String = ""
    ) {
        self.id = id
        self.isEnabled = isEnabled
        self.name = name
        self.options = options
        self.priceDifferenceText = priceDifferenceText
        self.quantity = quantity
        self.sku = sku
    }

    var optionsRawText: String {
        options.joined(separator: ", ")
    }

    static func normalizedOptions(fromRaw raw: String) -> [String] {
        raw
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

struct ListingCategoryAttribute: Codable, Identifiable, Equatable {
    var id: UUID
    var name: String
    var value: String

    init(id: UUID = UUID(), name: String = "", value: String = "") {
        self.id = id
        self.name = name
        self.value = value
    }
}

enum ListingInfoFieldPresence: String, Equatable {
    case filled
    case missing
    case notApplicable
    case needsReview
}

struct ListingInfoFieldReport: Identifiable, Equatable {
    var id: String { key }
    let key: String
    let label: String
    let presence: ListingInfoFieldPresence
    let detail: String?
}

struct ListingInformationReview: Equatable {
    let fields: [ListingInfoFieldReport]

    var filled: [ListingInfoFieldReport] {
        fields.filter { $0.presence == .filled }
    }

    var missing: [ListingInfoFieldReport] {
        fields.filter { $0.presence == .missing }
    }

    var notApplicable: [ListingInfoFieldReport] {
        fields.filter { $0.presence == .notApplicable }
    }

    var needingReview: [ListingInfoFieldReport] {
        fields.filter { $0.presence == .needsReview }
    }

    var summaryLine: String {
        "Filled \(filled.count) · Missing \(missing.count) · N/A \(notApplicable.count) · Review \(needingReview.count)"
    }
}

enum ListingInformationSupport {
    /// Local validation for Phase 30 listing-information fields only.
    /// Does not invent Etsy marketplace rules and does not affect Phase 25 queue readiness.
    static func validationIssues(for project: ItemProject) -> [String] {
        var issues: [String] = []

        if !project.listingPersonalizationNotApplicable, project.listingPersonalizationEnabled {
            let limitText = project.listingPersonalizationCharacterLimitText
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if let limit = Int(limitText), limit > 0 {
                // ok
            } else {
                issues.append("Personalization character limit must be a positive whole number")
            }
        }

        if !project.listingVariationsNotApplicable {
            for (index, variation) in project.listingVariations.enumerated() where variation.isEnabled {
                let label = "Variation \(index + 1)"
                if variation.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    issues.append("\(label) name cannot be blank")
                }
                let options = variation.options
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                if options.isEmpty {
                    issues.append("\(label) needs at least one nonblank option")
                }
                if variation.sku.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    issues.append("\(label) SKU cannot be blank when enabled")
                }
            }
        }

        return issues
    }

    static func sanitize(project: ItemProject) {
        if !project.listingPersonalizationNotApplicable {
            project.listingPersonalizationInstructions = project.listingPersonalizationInstructions
                .trimmingCharacters(in: .whitespacesAndNewlines)
            project.listingPersonalizationCharacterLimitText = project.listingPersonalizationCharacterLimitText
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        project.listingCondition = project.listingCondition.trimmingCharacters(in: .whitespacesAndNewlines)
        project.listingWhoMadeIt = project.listingWhoMadeIt.trimmingCharacters(in: .whitespacesAndNewlines)
        project.listingWhenMade = project.listingWhenMade.trimmingCharacters(in: .whitespacesAndNewlines)
        project.listingSKU = project.listingSKU.trimmingCharacters(in: .whitespacesAndNewlines)
        project.listingReturnPolicy = project.listingReturnPolicy.trimmingCharacters(in: .whitespacesAndNewlines)

        var variations = project.listingVariations
        for index in variations.indices {
            variations[index].name = variations[index].name.trimmingCharacters(in: .whitespacesAndNewlines)
            variations[index].sku = variations[index].sku.trimmingCharacters(in: .whitespacesAndNewlines)
            variations[index].priceDifferenceText = variations[index].priceDifferenceText
                .trimmingCharacters(in: .whitespacesAndNewlines)
            variations[index].options = variations[index].options
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            if variations[index].quantity < 0 {
                variations[index].quantity = 0
            }
        }
        project.listingVariations = variations

        let attributes = project.listingAttributes
            .map {
                ListingCategoryAttribute(
                    id: $0.id,
                    name: $0.name.trimmingCharacters(in: .whitespacesAndNewlines),
                    value: $0.value.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            }
            .filter { !$0.name.isEmpty && !$0.value.isEmpty }
        project.listingAttributes = attributes

        for photo in project.photos {
            let trimmed = photo.altText.trimmingCharacters(in: .whitespacesAndNewlines)
            photo.altText = trimmed
        }
    }

    static func review(for project: ItemProject) -> ListingInformationReview {
        var fields: [ListingInfoFieldReport] = []
        let issues = validationIssues(for: project)
        let issueText = issues.isEmpty ? nil : issues.joined(separator: " · ")

        fields.append(optionalStringReport(
            key: "itemType",
            label: "Item type",
            notApplicable: project.listingItemTypeNotApplicable,
            value: project.listingItemType?.rawValue
        ))
        fields.append(optionalStringReport(
            key: "condition",
            label: "Condition",
            notApplicable: project.listingConditionNotApplicable,
            value: project.listingCondition
        ))
        fields.append(optionalStringReport(
            key: "whoMade",
            label: "Who made it",
            notApplicable: project.listingWhoMadeItNotApplicable,
            value: project.listingWhoMadeIt
        ))
        fields.append(optionalStringReport(
            key: "whenMade",
            label: "When it was made",
            notApplicable: project.listingWhenMadeNotApplicable,
            value: project.listingWhenMade
        ))
        fields.append(optionalStringReport(
            key: "sku",
            label: "SKU",
            notApplicable: project.listingSKUNotApplicable,
            value: project.listingSKU
        ))

        if project.listingPersonalizationNotApplicable {
            fields.append(ListingInfoFieldReport(
                key: "personalization",
                label: "Personalization",
                presence: .notApplicable,
                detail: nil
            ))
        } else if project.listingPersonalizationEnabled {
            let limitOK = Int(project.listingPersonalizationCharacterLimitText.trimmingCharacters(in: .whitespacesAndNewlines)).map { $0 > 0 } ?? false
            fields.append(ListingInfoFieldReport(
                key: "personalization",
                label: "Personalization",
                presence: limitOK ? .filled : .needsReview,
                detail: limitOK
                    ? (project.listingPersonalizationRequired ? "Enabled · Required" : "Enabled · Optional")
                    : "Enabled — character limit needs review"
            ))
            fields.append(optionalStringReport(
                key: "personalizationInstructions",
                label: "Personalization buyer instructions",
                notApplicable: project.listingPersonalizationInstructionsNotApplicable,
                value: project.listingPersonalizationInstructions
            ))
        } else {
            fields.append(ListingInfoFieldReport(
                key: "personalization",
                label: "Personalization",
                presence: .filled,
                detail: "Disabled"
            ))
        }

        if project.listingVariationsNotApplicable {
            fields.append(ListingInfoFieldReport(
                key: "variations",
                label: "Variations",
                presence: .notApplicable,
                detail: nil
            ))
        } else if project.listingVariations.isEmpty {
            fields.append(ListingInfoFieldReport(
                key: "variations",
                label: "Variations",
                presence: .missing,
                detail: nil
            ))
        } else if issues.contains(where: { $0.hasPrefix("Variation ") }) {
            fields.append(ListingInfoFieldReport(
                key: "variations",
                label: "Variations",
                presence: .needsReview,
                detail: issueText
            ))
        } else {
            let enabledCount = project.listingVariations.filter(\.isEnabled).count
            fields.append(ListingInfoFieldReport(
                key: "variations",
                label: "Variations",
                presence: .filled,
                detail: "\(project.listingVariations.count) total · \(enabledCount) enabled"
            ))
        }

        if project.listingAttributesNotApplicable {
            fields.append(ListingInfoFieldReport(
                key: "attributes",
                label: "Category attributes",
                presence: .notApplicable,
                detail: nil
            ))
        } else if project.listingAttributes.isEmpty {
            fields.append(ListingInfoFieldReport(
                key: "attributes",
                label: "Category attributes",
                presence: .missing,
                detail: nil
            ))
        } else {
            fields.append(ListingInfoFieldReport(
                key: "attributes",
                label: "Category attributes",
                presence: .filled,
                detail: "\(project.listingAttributes.count) attribute\(project.listingAttributes.count == 1 ? "" : "s")"
            ))
        }

        fields.append(optionalStringReport(
            key: "returnPolicy",
            label: "Return policy",
            notApplicable: project.listingReturnPolicyNotApplicable,
            value: project.listingReturnPolicy
        ))

        let photos = project.sortedPhotos
        if photos.isEmpty {
            fields.append(ListingInfoFieldReport(
                key: "altText",
                label: "Photo alt text",
                presence: .missing,
                detail: "No project photos"
            ))
        } else {
            var filledCount = 0
            var missingCount = 0
            var naCount = 0
            for photo in photos {
                if photo.altTextNotApplicable {
                    naCount += 1
                } else if photo.altText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    missingCount += 1
                } else {
                    filledCount += 1
                }
            }
            let presence: ListingInfoFieldPresence
            if missingCount > 0 {
                presence = .missing
            } else if filledCount > 0 {
                presence = .filled
            } else {
                presence = .notApplicable
            }
            fields.append(ListingInfoFieldReport(
                key: "altText",
                label: "Photo alt text",
                presence: presence,
                detail: "Filled \(filledCount) · Missing \(missingCount) · N/A \(naCount)"
            ))
        }

        if !issues.isEmpty,
           !fields.contains(where: { $0.presence == .needsReview }) {
            fields.append(ListingInfoFieldReport(
                key: "validation",
                label: "Listing information validation",
                presence: .needsReview,
                detail: issueText
            ))
        }

        return ListingInformationReview(fields: fields)
    }

    private static func optionalStringReport(
        key: String,
        label: String,
        notApplicable: Bool,
        value: String?
    ) -> ListingInfoFieldReport {
        if notApplicable {
            return ListingInfoFieldReport(key: key, label: label, presence: .notApplicable, detail: nil)
        }
        let trimmed = (value ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return ListingInfoFieldReport(key: key, label: label, presence: .missing, detail: nil)
        }
        return ListingInfoFieldReport(key: key, label: label, presence: .filled, detail: trimmed)
    }
}
