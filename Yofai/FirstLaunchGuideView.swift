import SwiftUI

/// Branded welcome + short guided walkthrough after the system launch screen.
/// Skip is always available. Offline. VoiceOver + Dynamic Type friendly.
struct FirstLaunchGuideView: View {
    var onFinished: () -> Void

    @State private var page: FirstLaunchGuidePage = .welcome
    @State private var brandAppeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let pages = FirstLaunchGuidePage.allCases

    var body: some View {
        ZStack {
            DarkroomTheme.screenGradient.ignoresSafeArea()
            DarkroomTheme.softGlow.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer(minLength: 0)
                    Button(FirstLaunchGuideCopy.skip) {
                        finish()
                    }
                    .font(.body.weight(.semibold))
                    .foregroundStyle(DarkroomTheme.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .accessibilityLabel(FirstLaunchGuideCopy.skip)
                    .accessibilityHint("Skips the welcome guide and opens Yofai")
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                TabView(selection: $page) {
                    ForEach(pages) { step in
                        guidePage(step)
                            .tag(step)
                            .accessibilityElement(children: .contain)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(pageAnimation, value: page)

                pageDots
                    .padding(.bottom, 12)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(pageIndicatorLabel)

                Button {
                    advanceOrFinish()
                } label: {
                    DarkroomPrimaryButtonLabel(title: page.primaryButtonTitle)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
                .accessibilityLabel(page.primaryButtonTitle)
                .accessibilityHint(
                    page == .yofaiPro
                        ? "Finishes the welcome guide and opens Yofai"
                        : "Goes to the next welcome step"
                )
            }
        }
        .preferredColorScheme(.dark)
        .tint(DarkroomTheme.accent)
        .onAppear {
            guard page == .welcome else { return }
            if reduceMotion {
                brandAppeared = true
            } else {
                withAnimation(.easeOut(duration: 0.55)) {
                    brandAppeared = true
                }
            }
        }
        .accessibilityAddTraits(.isModal)
    }

    @ViewBuilder
    private func guidePage(_ step: FirstLaunchGuidePage) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                Spacer(minLength: 12)

                ZStack {
                    Circle()
                        .fill(DarkroomTheme.accent.opacity(0.14))
                        .frame(width: 120, height: 120)
                    Image(systemName: step.systemImage)
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(DarkroomTheme.accentGradient)
                        .symbolRenderingMode(.hierarchical)
                }
                .scaleEffect(step.isWelcome ? (brandAppeared ? 1 : 0.86) : 1)
                .opacity(step.isWelcome ? (brandAppeared ? 1 : 0.35) : 1)
                .accessibilityHidden(true)

                Text(step.title)
                    .font(step.isWelcome ? .largeTitle.weight(.bold) : .title2.weight(.bold))
                    .foregroundStyle(DarkroomTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)
                    .lineLimit(3)
                    .accessibilityAddTraits(.isHeader)

                Text(step.bodyText)
                    .font(.body)
                    .foregroundStyle(DarkroomTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 8)

                if step.isWelcome {
                    Text(AppStoreLaunchSupport.freemiumLaunchNote)
                        .font(.subheadline)
                        .foregroundStyle(DarkroomTheme.textTertiary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 4)
                }

                Spacer(minLength: 24)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 28)
            .padding(.vertical, 12)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(step.title). \(step.bodyText)")
    }

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(pages) { step in
                Capsule()
                    .fill(step == page ? DarkroomTheme.accent : DarkroomTheme.strokeBright.opacity(0.55))
                    .frame(width: step == page ? 18 : 7, height: 7)
                    .animation(pageAnimation, value: page)
            }
        }
        .frame(minHeight: 20)
    }

    private var pageIndicatorLabel: String {
        let index = (pages.firstIndex(of: page) ?? 0) + 1
        return String(format: FirstLaunchGuideCopy.pageIndicatorAccessibilityFormat, index, pages.count)
    }

    private var pageAnimation: Animation? {
        reduceMotion ? nil : .easeInOut(duration: 0.28)
    }

    private func advanceOrFinish() {
        guard let index = pages.firstIndex(of: page) else {
            finish()
            return
        }
        let next = index + 1
        if next < pages.count {
            withAnimation(pageAnimation) {
                page = pages[next]
            }
            if pages[next] == .welcome {
                brandAppeared = true
            }
        } else {
            finish()
        }
    }

    private func finish() {
        onFinished()
    }
}

#Preview("First Launch Guide") {
    FirstLaunchGuideView(onFinished: {})
}
