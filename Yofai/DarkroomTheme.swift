import SwiftUI
import UIKit

enum DarkroomTheme {
    static let backgroundTop = Color(red: 0.07, green: 0.06, blue: 0.08)
    static let backgroundBottom = Color(red: 0.02, green: 0.02, blue: 0.03)
    static let background = backgroundBottom
    static let canvas = Color.black
    static let surface = Color.white.opacity(0.07)
    static let surfaceRaised = Color.white.opacity(0.11)
    static let stroke = Color.white.opacity(0.16)
    static let strokeBright = Color.white.opacity(0.28)
    static let accent = Color(red: 0.95, green: 0.74, blue: 0.30)
    static let accentDeep = Color(red: 0.82, green: 0.52, blue: 0.12)
    static let textPrimary = Color.white.opacity(0.96)
    static let textSecondary = Color.white.opacity(0.64)
    static let textTertiary = Color.white.opacity(0.42)
    static let danger = Color(red: 0.95, green: 0.38, blue: 0.34)
    static let success = Color(red: 0.48, green: 0.82, blue: 0.52)

    static let cornerRadius: CGFloat = 16
    static let thumbSize: CGFloat = 72

    static var screenGradient: LinearGradient {
        LinearGradient(
            colors: [
                backgroundTop,
                Color(red: 0.05, green: 0.045, blue: 0.06),
                backgroundBottom
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var accentGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 1.0, green: 0.86, blue: 0.48), accent, accentDeep],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var glassFill: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.14),
                Color.white.opacity(0.05)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var softGlow: RadialGradient {
        RadialGradient(
            colors: [accent.opacity(0.22), Color.clear],
            center: .topTrailing,
            startRadius: 20,
            endRadius: 280
        )
    }
}

struct DarkroomScreen: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    DarkroomTheme.screenGradient.ignoresSafeArea()
                    DarkroomTheme.softGlow.ignoresSafeArea()
                }
            }
            .preferredColorScheme(.dark)
            .tint(DarkroomTheme.accent)
    }
}

extension View {
    func darkroomScreen() -> some View {
        modifier(DarkroomScreen())
    }

    func glassPanel(cornerRadius: CGFloat = DarkroomTheme.cornerRadius) -> some View {
        self
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .opacity(0.55)
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(DarkroomTheme.glassFill)
                    )
            }
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [DarkroomTheme.strokeBright, DarkroomTheme.stroke.opacity(0.35)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.28), radius: 14, y: 8)
    }
}

struct DarkroomCanvas<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: DarkroomTheme.cornerRadius, style: .continuous)
                .fill(DarkroomTheme.canvas)
            RoundedRectangle(cornerRadius: DarkroomTheme.cornerRadius, style: .continuous)
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(0.05), Color.clear],
                        center: .center,
                        startRadius: 10,
                        endRadius: 220
                    )
                )
            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: DarkroomTheme.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DarkroomTheme.cornerRadius, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [DarkroomTheme.strokeBright.opacity(0.7), DarkroomTheme.stroke.opacity(0.25)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.35), radius: 16, y: 10)
    }
}

struct DarkroomSection<Content: View>: View {
    let title: String
    var isCompact = false
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: isCompact ? 6 : 10) {
            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .tracking(isCompact ? 0.9 : 1.1)
                .foregroundStyle(DarkroomTheme.textTertiary)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(isCompact ? 8 : 14)
        .glassPanel(cornerRadius: isCompact ? 12 : DarkroomTheme.cornerRadius)
    }
}

struct DarkroomPrimaryButtonLabel: View {
    let title: String
    var systemImage: String? = nil
    var isLoading = false

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .tint(.black)
            } else if let systemImage {
                Label(title, systemImage: systemImage)
            } else {
                Text(title)
            }
        }
        .font(.headline.weight(.semibold))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .foregroundStyle(Color.black.opacity(0.88))
        .background(
            DarkroomTheme.accentGradient,
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.35), lineWidth: 1)
        )
        .shadow(color: DarkroomTheme.accent.opacity(0.35), radius: 12, y: 6)
    }
}

struct DarkroomSecondaryButtonLabel: View {
    let title: String
    var systemImage: String? = nil
    var isLoading = false
    var isDestructive = false

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .tint(DarkroomTheme.textPrimary)
            } else if let systemImage {
                Label(title, systemImage: systemImage)
            } else {
                Text(title)
            }
        }
        .font(.headline.weight(.semibold))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .foregroundStyle(isDestructive ? DarkroomTheme.danger : DarkroomTheme.textPrimary)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
                .opacity(0.45)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(DarkroomTheme.surfaceRaised)
                )
        }
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(
                    isDestructive ? DarkroomTheme.danger.opacity(0.55) : DarkroomTheme.strokeBright.opacity(0.7),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.22), radius: 10, y: 5)
    }
}

struct DarkroomChipButtonLabel: View {
    let title: String
    let systemImage: String
    var isCompact = false

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .frame(maxWidth: .infinity)
            .frame(minHeight: isCompact ? 36 : 0)
            .padding(.vertical, isCompact ? 7 : 11)
            .foregroundStyle(DarkroomTheme.textPrimary)
            .background {
                RoundedRectangle(cornerRadius: isCompact ? 10 : 12, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .opacity(0.4)
                    .background(
                        RoundedRectangle(cornerRadius: isCompact ? 10 : 12, style: .continuous)
                            .fill(DarkroomTheme.surfaceRaised)
                    )
            }
            .overlay(
                RoundedRectangle(cornerRadius: isCompact ? 10 : 12, style: .continuous)
                    .stroke(DarkroomTheme.stroke, lineWidth: 1)
            )
    }
}

struct DarkroomSelectableChip: View {
    let title: String
    let isSelected: Bool
    var isCompact = false

    var body: some View {
        Text(title)
            .font(.caption.weight(.bold))
            .padding(.horizontal, isCompact ? 12 : 14)
            .padding(.vertical, isCompact ? 7 : 10)
            .frame(minHeight: isCompact ? 34 : 0)
            .foregroundStyle(isSelected ? Color.black.opacity(0.88) : DarkroomTheme.textPrimary)
            .background {
                if isSelected {
                    Capsule().fill(DarkroomTheme.accentGradient)
                } else {
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .opacity(0.45)
                        .background(Capsule().fill(DarkroomTheme.surfaceRaised))
                }
            }
            .overlay(
                Capsule()
                    .stroke(
                        isSelected ? Color.white.opacity(0.35) : DarkroomTheme.stroke,
                        lineWidth: 1
                    )
            )
            .shadow(
                color: isSelected ? DarkroomTheme.accent.opacity(isCompact ? 0.22 : 0.3) : Color.clear,
                radius: isCompact ? 5 : 8,
                y: isCompact ? 2 : 3
            )
            .contentShape(Capsule())
    }
}

struct DarkroomEmptyPanel: View {
    let title: String
    let systemImage: String
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [DarkroomTheme.accent.opacity(0.35), Color.clear],
                            center: .center,
                            startRadius: 2,
                            endRadius: 48
                        )
                    )
                    .frame(width: 96, height: 96)
                Image(systemName: systemImage)
                    .font(.system(size: 34, weight: .light))
                    .foregroundStyle(DarkroomTheme.accent)
            }
            Text(title)
                .font(.title3.weight(.bold))
                .foregroundStyle(DarkroomTheme.textPrimary)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(DarkroomTheme.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.vertical, 40)
        .glassPanel(cornerRadius: 20)
        .padding(.horizontal, 20)
    }
}

struct DarkroomThumbRow: View {
    let thumbnail: UIImage?
    let title: String
    let subtitle: String
    var detail: String? = nil
    var showsChevron = true
    var isCompact = false

    var body: some View {
        HStack(spacing: isCompact ? 12 : 14) {
            Group {
                if let thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "photo")
                        .foregroundStyle(DarkroomTheme.textTertiary)
                }
            }
            .frame(
                width: isCompact ? 60 : DarkroomTheme.thumbSize,
                height: isCompact ? 60 : DarkroomTheme.thumbSize
            )
            .background(DarkroomTheme.canvas)
            .clipShape(RoundedRectangle(cornerRadius: isCompact ? 10 : 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: isCompact ? 10 : 12, style: .continuous)
                    .stroke(DarkroomTheme.strokeBright.opacity(0.55), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.28), radius: isCompact ? 6 : 8, y: isCompact ? 3 : 4)

            VStack(alignment: .leading, spacing: isCompact ? 3 : 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(DarkroomTheme.textPrimary)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(DarkroomTheme.textSecondary)
                    .lineLimit(1)
                if let detail {
                    Text(detail)
                        .font(.caption2)
                        .foregroundStyle(DarkroomTheme.textTertiary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(DarkroomTheme.accent.opacity(0.8))
                    .frame(width: 28, height: 44, alignment: .trailing)
            }
        }
        .padding(isCompact ? 10 : 12)
        .glassPanel(cornerRadius: isCompact ? 14 : DarkroomTheme.cornerRadius)
        .contentShape(RoundedRectangle(cornerRadius: isCompact ? 14 : DarkroomTheme.cornerRadius, style: .continuous))
    }
}
