import SwiftUI
import UIKit

enum CropAspectPreset: String, CaseIterable, Identifiable {
    case free = "Free"
    case oneOne = "1:1"
    case fourFive = "4:5"
    case threeFour = "3:4"
    case sixteenNine = "16:9"

    var id: String { rawValue }

    /// Width ÷ height. `nil` means freeform.
    var aspectRatio: CGFloat? {
        switch self {
        case .free: return nil
        case .oneOne: return 1
        case .fourFive: return 4 / 5
        case .threeFour: return 3 / 4
        case .sixteenNine: return 16 / 9
        }
    }
}

struct FreeformCropView: View {
    let image: UIImage
    let initialNormalizedCrop: CGRect?
    let onApply: (CGRect) -> Void
    let onCancel: () -> Void

    @State private var cropRect = CGRect.zero
    @State private var imageFrame = CGRect.zero
    @State private var didLayout = false
    @State private var errorMessage: String?
    @State private var moveStartCrop = CGRect.zero
    @State private var isMoving = false
    @State private var selectedPreset: CropAspectPreset = .free

    private let minSide: CGFloat = 48
    private let handleSize: CGFloat = 28

    var body: some View {
        NavigationStack {
            VStack(spacing: 10) {
                GeometryReader { geo in
                    let frame = Self.aspectFitFrame(imageSize: image.size, in: geo.size)

                    ZStack {
                        DarkroomTheme.canvas

                        Image(uiImage: image)
                            .resizable()
                            .frame(width: frame.width, height: frame.height)
                            .position(x: frame.midX, y: frame.midY)

                        CropDimOverlay(cropRect: cropRect, bounds: geo.size)
                            .allowsHitTesting(false)

                        Rectangle()
                            .stroke(DarkroomTheme.accent, lineWidth: 1.5)
                            .frame(width: max(cropRect.width, 1), height: max(cropRect.height, 1))
                            .position(x: cropRect.midX, y: cropRect.midY)
                            .gesture(moveGesture)

                        cornerHandle(.topLeft)
                        cornerHandle(.topRight)
                        cornerHandle(.bottomLeft)
                        cornerHandle(.bottomRight)
                    }
                    .onAppear {
                        syncLayout(frame: frame)
                    }
                    .onChange(of: geo.size) { _, newSize in
                        let newFrame = Self.aspectFitFrame(imageSize: image.size, in: newSize)
                        let normalized = normalizedCrop(from: cropRect, imageFrame: imageFrame)
                        imageFrame = newFrame
                        cropRect = displayCrop(from: normalized, imageFrame: newFrame)
                        if let ratio = selectedPreset.aspectRatio {
                            cropRect = clamped(cropRect, in: newFrame, lockingAspect: ratio)
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: DarkroomTheme.cornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: DarkroomTheme.cornerRadius, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [DarkroomTheme.strokeBright, DarkroomTheme.stroke.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.black.opacity(0.35), radius: 14, y: 8)
                .padding(.horizontal, 10)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(CropAspectPreset.allCases) { preset in
                            Button {
                                applyPreset(preset)
                            } label: {
                                DarkroomSelectableChip(
                                    title: preset.rawValue,
                                    isSelected: selectedPreset == preset
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 12)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundStyle(DarkroomTheme.danger)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }

                Text("Drag to move. Corners resize. Ratio locks aspect.")
                    .font(.caption)
                    .foregroundStyle(DarkroomTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 6)
            }
            .darkroomScreen()
            .navigationTitle("Crop")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onCancel() }
                        .foregroundStyle(DarkroomTheme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply Crop") { applyCrop() }
                        .fontWeight(.bold)
                        .foregroundStyle(DarkroomTheme.accent)
                }
            }
        }
    }

    private enum Corner {
        case topLeft, topRight, bottomLeft, bottomRight
    }

    private var moveGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if !isMoving {
                    moveStartCrop = cropRect
                    isMoving = true
                }
                var next = moveStartCrop
                next.origin.x += value.translation.width
                next.origin.y += value.translation.height
                cropRect = clamped(next, in: imageFrame, lockingAspect: selectedPreset.aspectRatio)
                errorMessage = nil
            }
            .onEnded { _ in
                isMoving = false
            }
    }

    private func cornerHandle(_ corner: Corner) -> some View {
        let point: CGPoint = {
            switch corner {
            case .topLeft: return CGPoint(x: cropRect.minX, y: cropRect.minY)
            case .topRight: return CGPoint(x: cropRect.maxX, y: cropRect.minY)
            case .bottomLeft: return CGPoint(x: cropRect.minX, y: cropRect.maxY)
            case .bottomRight: return CGPoint(x: cropRect.maxX, y: cropRect.maxY)
            }
        }()

        return Circle()
            .fill(DarkroomTheme.accent)
            .overlay(Circle().stroke(Color.black.opacity(0.35), lineWidth: 1))
            .frame(width: handleSize, height: handleSize)
            .shadow(color: .black.opacity(0.35), radius: 2, y: 1)
            .position(point)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        resize(corner: corner, to: value.location)
                        errorMessage = nil
                    }
            )
    }

    private func syncLayout(frame: CGRect) {
        imageFrame = frame
        guard !didLayout else { return }
        if let initialNormalizedCrop {
            cropRect = displayCrop(from: ImageEditing.clampNormalizedCrop(initialNormalizedCrop), imageFrame: frame)
            selectedPreset = .free
        } else {
            cropRect = startingCrop(in: frame)
        }
        didLayout = true
    }

    private func startingCrop(in frame: CGRect) -> CGRect {
        let insetX = frame.width * 0.1
        let insetY = frame.height * 0.1
        return CGRect(
            x: frame.minX + insetX,
            y: frame.minY + insetY,
            width: max(minSide, frame.width - insetX * 2),
            height: max(minSide, frame.height - insetY * 2)
        )
    }

    private func applyPreset(_ preset: CropAspectPreset) {
        selectedPreset = preset
        errorMessage = nil
        guard imageFrame.width > 1, imageFrame.height > 1 else {
            errorMessage = PhotoSaveError.cropFailed.localizedDescription
            return
        }

        if let ratio = preset.aspectRatio {
            let fitted = maxAspectRect(ratio: ratio, in: imageFrame, centeredAt: CGPoint(x: cropRect.midX, y: cropRect.midY))
            guard fitted.width >= minSide, fitted.height >= minSide else {
                errorMessage = PhotoSaveError.cropFailed.localizedDescription
                return
            }
            cropRect = fitted
        }
        // Free keeps current box as-is.
    }

    private func resize(corner: Corner, to location: CGPoint) {
        if let ratio = selectedPreset.aspectRatio {
            resizeLocked(corner: corner, to: location, ratio: ratio)
        } else {
            resizeFree(corner: corner, to: location)
        }
    }

    private func resizeFree(corner: Corner, to location: CGPoint) {
        var minX = cropRect.minX
        var minY = cropRect.minY
        var maxX = cropRect.maxX
        var maxY = cropRect.maxY

        switch corner {
        case .topLeft:
            minX = location.x
            minY = location.y
        case .topRight:
            maxX = location.x
            minY = location.y
        case .bottomLeft:
            minX = location.x
            maxY = location.y
        case .bottomRight:
            maxX = location.x
            maxY = location.y
        }

        if maxX - minX < minSide {
            if corner == .topLeft || corner == .bottomLeft {
                minX = maxX - minSide
            } else {
                maxX = minX + minSide
            }
        }
        if maxY - minY < minSide {
            if corner == .topLeft || corner == .topRight {
                minY = maxY - minSide
            } else {
                maxY = minY + minSide
            }
        }

        let next = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        cropRect = clamped(next, in: imageFrame, lockingAspect: nil)
    }

    private func resizeLocked(corner: Corner, to location: CGPoint, ratio: CGFloat) {
        let anchor: CGPoint
        switch corner {
        case .topLeft: anchor = CGPoint(x: cropRect.maxX, y: cropRect.maxY)
        case .topRight: anchor = CGPoint(x: cropRect.minX, y: cropRect.maxY)
        case .bottomLeft: anchor = CGPoint(x: cropRect.maxX, y: cropRect.minY)
        case .bottomRight: anchor = CGPoint(x: cropRect.minX, y: cropRect.minY)
        }

        let dx = abs(location.x - anchor.x)
        let dy = abs(location.y - anchor.y)
        var widthFromX = max(dx, minSide)
        var heightFromX = widthFromX / ratio
        var heightFromY = max(dy, minSide)
        var widthFromY = heightFromY * ratio

        // Prefer the candidate whose free corner is closer to the finger.
        let candidateA = CGSize(width: widthFromX, height: heightFromX)
        let candidateB = CGSize(width: widthFromY, height: heightFromY)
        let size: CGSize
        let distA = hypot(candidateA.width - dx, candidateA.height - dy)
        let distB = hypot(candidateB.width - dx, candidateB.height - dy)
        size = distA <= distB ? candidateA : candidateB

        var width = max(size.width, minSide)
        var height = width / ratio
        if height < minSide {
            height = minSide
            width = height * ratio
        }

        var next: CGRect
        switch corner {
        case .topLeft:
            next = CGRect(x: anchor.x - width, y: anchor.y - height, width: width, height: height)
        case .topRight:
            next = CGRect(x: anchor.x, y: anchor.y - height, width: width, height: height)
        case .bottomLeft:
            next = CGRect(x: anchor.x - width, y: anchor.y, width: width, height: height)
        case .bottomRight:
            next = CGRect(x: anchor.x, y: anchor.y, width: width, height: height)
        }

        cropRect = clamped(next, in: imageFrame, lockingAspect: ratio)
    }

    private func maxAspectRect(ratio: CGFloat, in bounds: CGRect, centeredAt center: CGPoint) -> CGRect {
        let boundsRatio = bounds.width / max(bounds.height, 1)
        var width: CGFloat
        var height: CGFloat
        if ratio >= boundsRatio {
            width = bounds.width
            height = width / ratio
        } else {
            height = bounds.height
            width = height * ratio
        }

        // Slight inset so handles stay visible.
        let scale = min(1, min((bounds.width - 8) / width, (bounds.height - 8) / height))
        width *= scale
        height *= scale

        var rect = CGRect(x: center.x - width / 2, y: center.y - height / 2, width: width, height: height)
        rect = clamped(rect, in: bounds, lockingAspect: ratio)
        return rect
    }

    private func clamped(_ rect: CGRect, in bounds: CGRect, lockingAspect ratio: CGFloat?) -> CGRect {
        var r = rect

        if let ratio {
            // Fit size into bounds while keeping aspect.
            var width = min(max(r.width, minSide), bounds.width)
            var height = width / ratio
            if height > bounds.height {
                height = bounds.height
                width = height * ratio
            }
            if width < minSide || height < minSide {
                if ratio >= 1 {
                    width = max(minSide, min(bounds.width, minSide * ratio))
                    height = width / ratio
                    if height > bounds.height {
                        height = bounds.height
                        width = height * ratio
                    }
                } else {
                    height = max(minSide, min(bounds.height, minSide / ratio))
                    width = height * ratio
                    if width > bounds.width {
                        width = bounds.width
                        height = width / ratio
                    }
                }
            }
            r.size = CGSize(width: width, height: height)
        } else {
            r.size.width = min(max(r.size.width, minSide), bounds.width)
            r.size.height = min(max(r.size.height, minSide), bounds.height)
        }

        r.origin.x = min(max(r.origin.x, bounds.minX), bounds.maxX - r.size.width)
        r.origin.y = min(max(r.origin.y, bounds.minY), bounds.maxY - r.size.height)
        return r
    }

    private func applyCrop() {
        guard imageFrame.width > 1, imageFrame.height > 1, cropRect.width >= minSide, cropRect.height >= minSide else {
            errorMessage = PhotoSaveError.cropFailed.localizedDescription
            return
        }
        let normalized = ImageEditing.clampNormalizedCrop(
            normalizedCrop(from: cropRect, imageFrame: imageFrame)
        )
        guard normalized.width >= 0.05, normalized.height >= 0.05 else {
            errorMessage = PhotoSaveError.cropFailed.localizedDescription
            return
        }
        onApply(normalized)
    }

    private func normalizedCrop(from display: CGRect, imageFrame: CGRect) -> CGRect {
        guard imageFrame.width > 0, imageFrame.height > 0 else {
            return CGRect(x: 0, y: 0, width: 1, height: 1)
        }
        return CGRect(
            x: (display.minX - imageFrame.minX) / imageFrame.width,
            y: (display.minY - imageFrame.minY) / imageFrame.height,
            width: display.width / imageFrame.width,
            height: display.height / imageFrame.height
        )
    }

    private func displayCrop(from normalized: CGRect, imageFrame: CGRect) -> CGRect {
        CGRect(
            x: imageFrame.minX + normalized.minX * imageFrame.width,
            y: imageFrame.minY + normalized.minY * imageFrame.height,
            width: normalized.width * imageFrame.width,
            height: normalized.height * imageFrame.height
        )
    }

    static func aspectFitFrame(imageSize: CGSize, in container: CGSize) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0, container.width > 0, container.height > 0 else {
            return .zero
        }
        let scale = min(container.width / imageSize.width, container.height / imageSize.height)
        let width = imageSize.width * scale
        let height = imageSize.height * scale
        return CGRect(
            x: (container.width - width) / 2,
            y: (container.height - height) / 2,
            width: width,
            height: height
        )
    }
}

private struct CropDimOverlay: View {
    let cropRect: CGRect
    let bounds: CGSize

    var body: some View {
        Canvas { context, size in
            var path = Path(CGRect(origin: .zero, size: size))
            path.addRect(cropRect)
            context.fill(path, with: .color(.black.opacity(0.45)), style: FillStyle(eoFill: true))
        }
        .frame(width: bounds.width, height: bounds.height)
    }
}

#Preview {
    FreeformCropView(
        image: UIImage(systemName: "photo") ?? UIImage(),
        initialNormalizedCrop: nil,
        onApply: { _ in },
        onCancel: {}
    )
}
