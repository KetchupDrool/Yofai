import SwiftUI
import UIKit

/// Phase 38 — drag to pan Fill + Crop within valid overflow bounds. Preview matches export framing.
struct FillCropRepositionView: View {
    let image: UIImage
    let preset: ListingExportPreset
    let background: ListingExportBackground
    let initialOffsetX: Double
    let initialOffsetY: Double
    let onApply: (Double, Double) -> Void
    let onCancel: () -> Void

    @State private var draftX: Double = 0
    @State private var draftY: Double = 0
    @State private var dragStartX: Double = 0
    @State private var dragStartY: Double = 0
    @State private var isDragging = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Text("Drag to reposition. Canvas stays filled.")
                    .font(.caption)
                    .foregroundStyle(DarkroomTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                GeometryReader { geo in
                    let canvas = Self.displayCanvas(for: preset, in: geo.size)
                    let imagePixel = CGSize(
                        width: max(1, image.size.width * image.scale),
                        height: max(1, image.size.height * image.scale)
                    )
                    let draw = ListingExportFillCropPosition.drawRect(
                        imagePixelSize: imagePixel,
                        canvas: canvas,
                        offsetX: draftX,
                        offsetY: draftY
                    ) ?? CGRect(origin: .zero, size: canvas)

                    ZStack {
                        DarkroomTheme.canvas

                        ZStack(alignment: .topLeading) {
                            background.uiColor.swiftUIColor
                            Image(uiImage: image)
                                .resizable()
                                .frame(width: draw.width, height: draw.height)
                                .offset(x: draw.origin.x, y: draw.origin.y)
                        }
                        .frame(width: canvas.width, height: canvas.height)
                        .clipped()
                        .overlay(
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .stroke(DarkroomTheme.accent, lineWidth: 1.5)
                        )
                        .position(x: geo.size.width / 2, y: geo.size.height / 2)
                        .gesture(panGesture(canvas: canvas, imagePixel: imagePixel))
                    }
                }
                .frame(maxHeight: .infinity)

                HStack(spacing: 10) {
                    Button("Reset to Center") {
                        draftX = 0
                        draftY = 0
                    }
                    .buttonStyle(.bordered)
                    .disabled(abs(draftX) < 0.0001 && abs(draftY) < 0.0001)

                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .background(DarkroomTheme.background.ignoresSafeArea())
            .navigationTitle("Reposition")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        let clamped = ListingExportFillCropPosition.clampPair(x: draftX, y: draftY)
                        onApply(clamped.x, clamped.y)
                    }
                }
            }
            .onAppear {
                draftX = ListingExportFillCropPosition.clamp(initialOffsetX)
                draftY = ListingExportFillCropPosition.clamp(initialOffsetY)
            }
        }
    }

    private func panGesture(canvas: CGSize, imagePixel: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                guard let centerRect = ListingExportFillCropPosition.drawRect(
                    imagePixelSize: imagePixel,
                    canvas: canvas,
                    offsetX: 0,
                    offsetY: 0
                ) else { return }

                let overflowX = max(0, centerRect.width - canvas.width)
                let overflowY = max(0, centerRect.height - canvas.height)
                let halfX = max(overflowX / 2, 0.0001)
                let halfY = max(overflowY / 2, 0.0001)

                if !isDragging {
                    isDragging = true
                    dragStartX = draftX
                    dragStartY = draftY
                }

                let nextX = overflowX > 0.5
                    ? dragStartX + Double(value.translation.width / halfX)
                    : 0
                let nextY = overflowY > 0.5
                    ? dragStartY + Double(value.translation.height / halfY)
                    : 0
                let clamped = ListingExportFillCropPosition.clampPair(x: nextX, y: nextY)
                draftX = clamped.x
                draftY = clamped.y
            }
            .onEnded { _ in
                isDragging = false
            }
    }

    static func displayCanvas(for preset: ListingExportPreset, in bounds: CGSize) -> CGSize {
        let target = preset.pixelSize
        let pad: CGFloat = 16
        let maxW = max(1, bounds.width - pad)
        let maxH = max(1, bounds.height - pad)
        let scale = min(maxW / target.width, maxH / target.height)
        return CGSize(
            width: (target.width * scale).rounded(.down),
            height: (target.height * scale).rounded(.down)
        )
    }
}

private extension UIColor {
    var swiftUIColor: Color {
        Color(self)
    }
}
