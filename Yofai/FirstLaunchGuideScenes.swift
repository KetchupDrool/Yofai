import SwiftUI

/// Staged SwiftUI mini-scenes for the first-launch guide.
/// Decorative only (`accessibilityHidden`). Offline. No AI / Direct Upload / fake Pro success.
struct FirstLaunchGuideDemoStage: View {
    let page: FirstLaunchGuidePage
    let reduceMotion: Bool

    @State private var phase: FirstLaunchGuideScenePhase = .idle
    @State private var runToken = 0

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(DarkroomTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(DarkroomTheme.stroke, lineWidth: 1)
                )

            sceneContent
                .padding(16)
        }
        .frame(height: FirstLaunchGuideMotion.demoStageHeight)
        .accessibilityHidden(true)
        .onAppear { restartTimeline() }
        .onChange(of: page) { _, _ in
            restartTimeline()
        }
        .onChange(of: reduceMotion) { _, _ in
            restartTimeline()
        }
    }

    @ViewBuilder
    private var sceneContent: some View {
        switch FirstLaunchGuideSceneKind.kind(for: page) {
        case .welcomeBrand:
            WelcomeBrandScene(phase: phase)
        case .startProduct:
            StartProductScene(phase: phase)
        case .addPhotos:
            AddPhotosScene(phase: phase)
        case .photoCheck:
            PhotoCheckScene(phase: phase)
        case .crop:
            CropScene(phase: phase)
        case .fitModes:
            FitModesScene(phase: phase)
        case .reposition:
            RepositionScene(phase: phase)
        case .exportSize:
            ExportSizeScene(phase: phase)
        case .marketplaceTarget:
            MarketplaceTargetScene(phase: phase)
        case .exportLocal:
            ExportLocalScene(phase: phase)
        case .exportHistory:
            ExportHistoryScene(phase: phase)
        case .yofaiPro:
            YofaiProScene(phase: phase)
        }
    }

    private func restartTimeline() {
        runToken += 1
        let token = runToken

        if reduceMotion {
            phase = .settle
            return
        }

        phase = .idle
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: FirstLaunchGuideMotion.sceneEnterDelayNanoseconds)
            guard token == runToken else { return }
            withAnimation(FirstLaunchGuideMotion.sceneEnterAnimation(reduceMotion: false)) {
                phase = .enter
            }

            try? await Task.sleep(nanoseconds: FirstLaunchGuideMotion.sceneActDelayNanoseconds)
            guard token == runToken else { return }
            withAnimation(FirstLaunchGuideMotion.sceneActAnimation(reduceMotion: false)) {
                phase = .act
            }

            try? await Task.sleep(nanoseconds: FirstLaunchGuideMotion.sceneSettleDelayNanoseconds)
            guard token == runToken else { return }
            withAnimation(FirstLaunchGuideMotion.sceneSettleAnimation(reduceMotion: false)) {
                phase = .settle
            }
        }
    }
}

// MARK: - Shared pieces

private struct DemoPhotoTile: View {
    var tint: Color
    var systemImage: String = "photo"

    var body: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(tint.opacity(0.35))
            .overlay(
                Image(systemName: systemImage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DarkroomTheme.textPrimary.opacity(0.9))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(DarkroomTheme.strokeBright.opacity(0.5), lineWidth: 1)
            )
    }
}

private struct DemoCard: View {
    var title: String
    var subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(DarkroomTheme.textPrimary)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(DarkroomTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(DarkroomTheme.surfaceRaised)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(DarkroomTheme.strokeBright.opacity(0.55), lineWidth: 1)
        )
    }
}

// MARK: - Welcome

private struct WelcomeBrandScene: View {
    let phase: FirstLaunchGuideScenePhase

    var body: some View {
        ZStack {
            Circle()
                .fill(DarkroomTheme.accent.opacity(phase.hasEntered ? 0.22 : 0.05))
                .frame(width: phase.hasSettled ? 150 : 90, height: phase.hasSettled ? 150 : 90)
                .blur(radius: phase.hasEntered ? 2 : 8)

            Image(systemName: "camera.aperture")
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(DarkroomTheme.accentGradient)
                .offset(
                    x: phase.hasEntered ? 0 : -110,
                    y: phase.hasEntered ? 0 : -70
                )
                .rotationEffect(.degrees(phase.hasEntered ? 0 : -28))
                .opacity(phase.hasEntered ? 1 : 0)

            Text("Yofai")
                .font(.title.weight(.bold))
                .foregroundStyle(DarkroomTheme.textPrimary)
                .offset(
                    x: phase.hasActed ? 0 : 120,
                    y: phase.hasActed ? 58 : 90
                )
                .opacity(phase.hasActed ? 1 : 0)

            Text("Local JPEGs")
                .font(.caption.weight(.semibold))
                .foregroundStyle(DarkroomTheme.textTertiary)
                .offset(y: 92)
                .opacity(phase.hasSettled ? 1 : 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Start Product

private struct StartProductScene: View {
    let phase: FirstLaunchGuideScenePhase

    var body: some View {
        ZStack {
            // Empty slot
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
                .foregroundStyle(DarkroomTheme.strokeBright.opacity(0.7))
                .frame(height: 88)
                .opacity(phase.hasActed ? 0.15 : 0.9)
                .offset(y: phase.hasEntered ? 0 : 40)

            // New Product chip from trailing
            HStack(spacing: 6) {
                Image(systemName: "plus.circle.fill")
                Text("New Product")
                    .fontWeight(.semibold)
            }
            .font(.caption)
            .foregroundStyle(Color.black.opacity(0.85))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(DarkroomTheme.accentGradient, in: Capsule())
            .offset(
                x: phase.hasEntered ? (phase.hasActed ? -20 : 70) : 140,
                y: phase.hasEntered ? (phase.hasActed ? -48 : -20) : -20
            )
            .opacity(phase.hasEntered ? (phase.hasActed ? 0 : 1) : 0)

            // Filled product card from top
            DemoCard(title: "Vintage Lamp", subtitle: "Product ready")
                .frame(width: 220)
                .offset(y: phase.hasActed ? 10 : -160)
                .rotationEffect(.degrees(phase.hasActed ? 0 : -8))
                .opacity(phase.hasActed ? 1 : 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Add Photos

private struct AddPhotosScene: View {
    let phase: FirstLaunchGuideScenePhase

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(DarkroomTheme.accent.opacity(0.2))
                    .frame(width: 64, height: 64)
                Image(systemName: "camera.fill")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(DarkroomTheme.accent)
            }
            .offset(x: phase.hasEntered ? 0 : -130, y: phase.hasEntered ? 0 : 20)
            .rotationEffect(.degrees(phase.hasEntered ? 0 : -35))
            .opacity(phase.hasEntered ? 1 : 0)

            HStack(spacing: 8) {
                DemoPhotoTile(tint: .orange, systemImage: "tshirt")
                    .frame(width: 56, height: 72)
                    .offset(
                        x: phase.hasActed ? 0 : 90,
                        y: phase.hasActed ? 0 : 50
                    )
                    .rotationEffect(.degrees(phase.hasActed ? -4 : 18))
                    .opacity(phase.hasActed ? 1 : 0)

                DemoPhotoTile(tint: .teal, systemImage: "shippingbox")
                    .frame(width: 56, height: 72)
                    .offset(
                        x: phase.hasActed ? 0 : 120,
                        y: phase.hasSettled ? 0 : 70
                    )
                    .rotationEffect(.degrees(phase.hasSettled ? 3 : -22))
                    .opacity(phase.hasSettled ? 1 : (phase.hasActed ? 0.35 : 0))

                DemoPhotoTile(tint: .purple, systemImage: "gift")
                    .frame(width: 56, height: 72)
                    .offset(
                        x: phase.hasSettled ? 0 : 150,
                        y: phase.hasSettled ? 0 : -40
                    )
                    .rotationEffect(.degrees(phase.hasSettled ? -2 : 25))
                    .opacity(phase.hasSettled ? 1 : 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Photo Check

private struct PhotoCheckScene: View {
    let phase: FirstLaunchGuideScenePhase

    private let rows = ["Framing", "Clarity", "Export size"]

    var body: some View {
        HStack(spacing: 14) {
            DemoPhotoTile(tint: DarkroomTheme.accent, systemImage: "photo")
                .frame(width: 78, height: 100)
                .offset(y: phase.hasEntered ? 0 : -90)
                .opacity(phase.hasEntered ? 1 : 0)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(rows.enumerated()), id: \.offset) { index, title in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(DarkroomTheme.success)
                            .scaleEffect(rowVisible(index) ? 1 : 0.4)
                        Text(title)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(DarkroomTheme.textPrimary)
                    }
                    .offset(x: rowVisible(index) ? 0 : 80)
                    .opacity(rowVisible(index) ? 1 : 0)
                }

                Image(systemName: "checkmark.seal.fill")
                    .font(.title2)
                    .foregroundStyle(DarkroomTheme.accent)
                    .scaleEffect(phase.hasSettled ? 1 : 0.2)
                    .opacity(phase.hasSettled ? 1 : 0)
                    .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func rowVisible(_ index: Int) -> Bool {
        if phase.hasSettled { return true }
        if phase.hasActed { return index <= 1 }
        if phase.hasEntered { return index == 0 }
        return false
    }
}

// MARK: - Crop

private struct CropScene: View {
    let phase: FirstLaunchGuideScenePhase

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(DarkroomTheme.strokeBright, lineWidth: 1)
                .frame(width: 170, height: 140)

            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.orange.opacity(0.55), Color.pink.opacity(0.35)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(
                    width: phase.hasActed ? 110 : 150,
                    height: phase.hasActed ? 110 : 130
                )
                .offset(y: phase.hasEntered ? 0 : 50)
                .opacity(phase.hasEntered ? 1 : 0)

            ForEach(0..<4, id: \.self) { corner in
                Circle()
                    .fill(DarkroomTheme.accent)
                    .frame(width: 10, height: 10)
                    .offset(cropHandleOffset(corner))
                    .opacity(phase.hasActed ? 1 : 0)
                    .scaleEffect(phase.hasActed ? 1 : 0.3)
            }

            Text("Crop")
                .font(.caption.weight(.bold))
                .foregroundStyle(DarkroomTheme.textTertiary)
                .offset(y: 72)
                .opacity(phase.hasSettled ? 1 : 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func cropHandleOffset(_ corner: Int) -> CGSize {
        let x: CGFloat = (corner == 0 || corner == 3) ? -58 : 58
        let y: CGFloat = (corner == 0 || corner == 1) ? -58 : 58
        return CGSize(width: x, height: y)
    }
}

// MARK: - Fit modes

private struct FitModesScene: View {
    let phase: FirstLaunchGuideScenePhase

    var body: some View {
        HStack(spacing: 16) {
            fitCard(
                title: "Contain + Pad",
                imageSize: CGSize(width: 54, height: 40),
                showPad: true,
                visible: phase.hasEntered
            )
            fitCard(
                title: "Fill + Crop",
                imageSize: CGSize(width: 78, height: 78),
                showPad: false,
                visible: phase.hasActed
            )
        }
        .opacity(phase.hasSettled || phase.hasActed || phase.hasEntered ? 1 : 0)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func fitCard(title: String, imageSize: CGSize, showPad: Bool, visible: Bool) -> some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(DarkroomTheme.strokeBright, lineWidth: 1)
                    .frame(width: 88, height: 88)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(showPad ? DarkroomTheme.surfaceRaised : Color.clear)
                    )

                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.teal.opacity(0.55), Color.blue.opacity(0.35)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: imageSize.width, height: imageSize.height)
                    .clipped()
            }
            .scaleEffect(visible ? 1 : 0.85)
            .opacity(visible ? 1 : 0)

            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(DarkroomTheme.textSecondary)
                .opacity(phase.hasSettled ? 1 : (visible ? 0.7 : 0))
        }
    }
}

// MARK: - Reposition

private struct RepositionScene: View {
    let phase: FirstLaunchGuideScenePhase

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(DarkroomTheme.accent, lineWidth: 2)
                .frame(width: 120, height: 120)

            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.orange.opacity(0.6), Color.pink.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 160, height: 160)
                .offset(
                    x: phase.hasActed ? (phase.hasSettled ? 0 : 18) : -28,
                    y: phase.hasActed ? (phase.hasSettled ? 0 : -12) : 22
                )
                .opacity(phase.hasEntered ? 1 : 0)

            Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(DarkroomTheme.textPrimary)
                .padding(8)
                .background(.ultraThinMaterial, in: Circle())
                .offset(x: 52, y: 48)
                .opacity(phase.hasSettled ? 1 : 0)
                .scaleEffect(phase.hasSettled ? 1 : 0.4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }
}

// MARK: - Export size

private struct ExportSizeScene: View {
    let phase: FirstLaunchGuideScenePhase

    private let sizes = ["2000×2000", "1600×1600", "1000×1000"]

    var body: some View {
        VStack(spacing: 10) {
            ForEach(Array(sizes.enumerated()), id: \.offset) { index, label in
                HStack {
                    Image(systemName: "square.dashed")
                        .foregroundStyle(DarkroomTheme.accent)
                    Text(label)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DarkroomTheme.textPrimary)
                    Spacer(minLength: 0)
                    if index == 0 {
                        Text("Selected")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(DarkroomTheme.accent)
                            .opacity(phase.hasSettled ? 1 : 0)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(DarkroomTheme.surfaceRaised)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(
                            index == 0 && phase.hasActed ? DarkroomTheme.accent.opacity(0.8) : DarkroomTheme.stroke,
                            lineWidth: 1
                        )
                )
                .offset(x: rowVisible(index) ? 0 : 80)
                .opacity(rowVisible(index) ? 1 : 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func rowVisible(_ index: Int) -> Bool {
        if phase.hasSettled { return true }
        if phase.hasActed { return index <= 1 }
        if phase.hasEntered { return index == 0 }
        return false
    }
}

// MARK: - Marketplace target

private struct MarketplaceTargetScene: View {
    let phase: FirstLaunchGuideScenePhase

    private let markets = ["Etsy", "eBay", "Poshmark"]

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                ForEach(Array(markets.enumerated()), id: \.offset) { index, name in
                    Text(name)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(index == 0 && phase.hasActed ? Color.black.opacity(0.85) : DarkroomTheme.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background {
                            if index == 0 && phase.hasActed {
                                Capsule().fill(DarkroomTheme.accentGradient)
                            } else {
                                Capsule().fill(DarkroomTheme.surfaceRaised)
                            }
                        }
                        .offset(y: phase.hasEntered ? 0 : 40)
                        .opacity(phase.hasEntered ? 1 : 0)
                }
            }

            Text("Label only · no upload")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(DarkroomTheme.textTertiary)
                .opacity(phase.hasSettled ? 1 : 0)
                .offset(y: phase.hasSettled ? 0 : 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Export Local JPEGs

private struct ExportLocalScene: View {
    let phase: FirstLaunchGuideScenePhase

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                ForEach(0..<3, id: \.self) { index in
                    DemoPhotoTile(tint: index == 0 ? .orange : (index == 1 ? .mint : .indigo))
                        .frame(width: 48, height: 60)
                        .scaleEffect(phase.hasActed ? 0.55 : 1)
                        .offset(y: phase.hasEntered ? (phase.hasActed ? -8 : 0) : 70)
                        .opacity(phase.hasEntered ? (phase.hasActed ? 0.25 : 1) : 0)
                        .rotationEffect(.degrees(phase.hasEntered ? Double(index - 1) * 4 : Double(index) * 12))
                }
            }

            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    VStack(spacing: 4) {
                        Image(systemName: "doc.fill")
                            .foregroundStyle(DarkroomTheme.accent)
                        Text("JPEG")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(DarkroomTheme.textSecondary)
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(DarkroomTheme.surfaceRaised)
                    )
                    .offset(
                        x: phase.hasActed ? 0 : CGFloat(index - 1) * 30,
                        y: phase.hasActed ? 0 : 40
                    )
                    .opacity(phase.hasActed ? 1 : 0)
                    .rotationEffect(.degrees(phase.hasActed ? 0 : Double(index - 1) * 10))
                }
            }

            Text("\(LocalExportShareSupport.localJPEGsLabel) · \(LocalExportShareSupport.manualUploadLabel)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(DarkroomTheme.textTertiary)
                .opacity(phase.hasSettled ? 1 : 0)
                .offset(y: phase.hasSettled ? 0 : 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Export History

private struct ExportHistoryScene: View {
    let phase: FirstLaunchGuideScenePhase

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                DemoPhotoTile(tint: .cyan)
                    .frame(width: 44, height: 56)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Exported for Etsy")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DarkroomTheme.textPrimary)
                    Text("3 Local JPEGs · 2000×2000")
                        .font(.caption2)
                        .foregroundStyle(DarkroomTheme.textSecondary)
                }
                Spacer(minLength: 0)

                Image(systemName: "square.and.arrow.up")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(DarkroomTheme.accent)
                    .scaleEffect(phase.hasSettled ? 1.08 : 0.7)
                    .opacity(phase.hasActed ? 1 : 0)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(DarkroomTheme.surfaceRaised)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(DarkroomTheme.strokeBright.opacity(0.5), lineWidth: 1)
            )
            .offset(y: phase.hasEntered ? 0 : 100)
            .opacity(phase.hasEntered ? 1 : 0)
            .rotationEffect(.degrees(phase.hasEntered ? 0 : 6))

            Text("View / Share on device")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(DarkroomTheme.textTertiary)
                .opacity(phase.hasSettled ? 1 : 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Yofai Pro

private struct YofaiProScene: View {
    let phase: FirstLaunchGuideScenePhase

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                labelChip("Free", filled: true)
                    .offset(x: phase.hasEntered ? 0 : -100)
                    .opacity(phase.hasEntered ? 1 : 0)

                Image(systemName: "arrow.right")
                    .foregroundStyle(DarkroomTheme.textTertiary)
                    .opacity(phase.hasActed ? 1 : 0)

                labelChip("Yofai Pro", filled: false)
                    .overlay(
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(DarkroomTheme.accent)
                            .offset(x: 38, y: -16)
                            .opacity(phase.hasActed ? 1 : 0)
                            .offset(y: phase.hasActed ? 0 : -40)
                    )
                    .offset(x: phase.hasActed ? 0 : 110, y: phase.hasActed ? 0 : -30)
                    .opacity(phase.hasActed ? 1 : 0)
            }

            HStack(spacing: 8) {
                miniChip("Unlimited products")
                miniChip("Additive extras")
            }
            .opacity(phase.hasSettled ? 1 : 0)
            .offset(y: phase.hasSettled ? 0 : 16)

            Text("Optional · Free keeps local export")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(DarkroomTheme.textTertiary)
                .opacity(phase.hasSettled ? 1 : 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func labelChip(_ title: String, filled: Bool) -> some View {
        Text(title)
            .font(.caption.weight(.bold))
            .foregroundStyle(filled ? Color.black.opacity(0.85) : DarkroomTheme.textPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background {
                if filled {
                    Capsule().fill(DarkroomTheme.accentGradient)
                } else {
                    Capsule().stroke(DarkroomTheme.accent, lineWidth: 1.5)
                }
            }
    }

    private func miniChip(_ title: String) -> some View {
        Text(title)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(DarkroomTheme.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(DarkroomTheme.surfaceRaised))
    }
}
