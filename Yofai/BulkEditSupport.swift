import Foundation
import SwiftData

/// Individual recipe fields that can be included or excluded during bulk edit.
enum BulkEditSetting: String, CaseIterable, Identifiable, Codable, Equatable {
    case rotation
    case crop
    case filter
    case brightness
    case contrast
    case saturation
    case exportPreset
    case background
    case fitMode
    case watermark

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .rotation: return "Rotation"
        case .crop: return "Crop"
        case .filter: return "Filter"
        case .brightness: return "Brightness"
        case .contrast: return "Contrast"
        case .saturation: return "Saturation"
        case .exportPreset: return "Export preset"
        case .background: return "Background"
        case .fitMode: return "Fit mode"
        case .watermark: return "Watermark settings"
        }
    }

    static var allSelectable: Set<BulkEditSetting> {
        Set(allCases)
    }
}

struct BulkEditUndoRecord: Codable, Equatable {
    var photoLocalFileName: String
    var previousEditStateData: Data?
}

struct BulkEditUndoPayload: Codable, Equatable {
    var records: [BulkEditUndoRecord]
    var createdAt: Date
}

enum BulkEditSupport {
    /// Merges selected fields from `source` into `target`.
    static func merge(
        source: PhotoEditState,
        into target: PhotoEditState,
        including settings: Set<BulkEditSetting>
    ) -> PhotoEditState {
        var result = target
        if settings.contains(.rotation) {
            result.quarterTurns = source.quarterTurns
        }
        if settings.contains(.crop) {
            result.cropRect = source.cropRect
        }
        if settings.contains(.filter) {
            result.filter = source.filter
        }
        if settings.contains(.brightness) {
            result.brightness = source.brightness
        }
        if settings.contains(.contrast) {
            result.contrast = source.contrast
        }
        if settings.contains(.saturation) {
            result.saturation = source.saturation
        }
        if settings.contains(.exportPreset) {
            result.exportPreset = source.exportPreset
        }
        if settings.contains(.background) {
            result.exportBackground = source.exportBackground
        }
        if settings.contains(.fitMode) {
            result.exportFitMode = source.exportFitMode
        }
        if settings.contains(.watermark) {
            result.watermarkEnabled = source.watermarkEnabled
            result.watermarkText = source.watermarkText
        }
        return result
    }

    /// Applies source recipe to targets. Does not touch image files or History.
    @discardableResult
    static func apply(
        sourcePhoto: ItemProjectPhoto,
        targetPhotos: [ItemProjectPhoto],
        including settings: Set<BulkEditSetting>,
        on project: ItemProject
    ) -> Int {
        guard !settings.isEmpty else { return 0 }
        let sourceState = sourcePhoto.savedEditState ?? PhotoEditState()
        let sourceID = sourcePhoto.persistentModelID
        var undoRecords: [BulkEditUndoRecord] = []
        var applied = 0

        for photo in targetPhotos {
            guard photo.persistentModelID != sourceID else { continue }
            guard let fileName = photo.localFileName, !fileName.isEmpty else { continue }

            undoRecords.append(
                BulkEditUndoRecord(
                    photoLocalFileName: fileName,
                    previousEditStateData: photo.savedEditStateData
                )
            )

            let current = photo.savedEditState ?? PhotoEditState()
            photo.savedEditState = merge(source: sourceState, into: current, including: settings)
            applied += 1
        }

        if !undoRecords.isEmpty {
            let payload = BulkEditUndoPayload(records: undoRecords, createdAt: .now)
            project.lastBulkEditUndoData = try? JSONEncoder().encode(payload)
            project.touchModified()
        }
        return applied
    }

    static func canUndo(project: ItemProject) -> Bool {
        project.lastBulkEditUndoData != nil
    }

    /// Restores previous edit settings from the most recent bulk edit on this project only.
    @discardableResult
    static func undoLastBulkEdit(on project: ItemProject) -> Int {
        guard let data = project.lastBulkEditUndoData,
              let payload = try? JSONDecoder().decode(BulkEditUndoPayload.self, from: data) else {
            return 0
        }

        var restored = 0
        let byFile = Dictionary(uniqueKeysWithValues: project.photos.compactMap { photo -> (String, ItemProjectPhoto)? in
            guard let name = photo.localFileName else { return nil }
            return (name, photo)
        })

        for record in payload.records {
            guard let photo = byFile[record.photoLocalFileName] else { continue }
            if let previous = record.previousEditStateData {
                photo.savedEditStateData = previous
            } else {
                photo.savedEditStateData = nil
            }
            restored += 1
        }

        project.lastBulkEditUndoData = nil
        project.touchModified()
        return restored
    }

    static func recipeSummary(state: PhotoEditState, including settings: Set<BulkEditSetting>) -> [String] {
        BulkEditSetting.allCases.compactMap { setting in
            guard settings.contains(setting) else { return nil }
            switch setting {
            case .rotation:
                return "\(setting.displayName): \(state.normalizedTurns)×90°"
            case .crop:
                return "\(setting.displayName): \(state.didCrop ? "custom" : "none")"
            case .filter:
                return "\(setting.displayName): \(state.filter.rawValue)"
            case .brightness:
                return "\(setting.displayName): \(Int((state.brightness * 100).rounded()))"
            case .contrast:
                return "\(setting.displayName): \(Int(((state.contrast - 1) * 100).rounded()))"
            case .saturation:
                return "\(setting.displayName): \(Int(((state.saturation - 1) * 100).rounded()))"
            case .exportPreset:
                return "\(setting.displayName): \(state.exportPreset.pickerLabel)"
            case .background:
                return "\(setting.displayName): \(state.exportBackground.rawValue)"
            case .fitMode:
                return "\(setting.displayName): \(state.exportFitMode.displayTitle)"
            case .watermark:
                if state.willDrawWatermark {
                    return "\(setting.displayName): “\(state.trimmedWatermarkText)”"
                }
                return "\(setting.displayName): off"
            }
        }
    }
}
