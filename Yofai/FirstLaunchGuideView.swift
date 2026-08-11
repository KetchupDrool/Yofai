import SwiftUI

/// Branded welcome + guided walkthrough after the system launch screen.
/// Skip always available. Offline. VoiceOver + Dynamic Type friendly.
/// Rich SwiftUI demo scenes per step — not a video. Honors Reduce Motion.
struct FirstLaunchGuideView: View {
    var onFinished: () -> Void

    @State private var page: FirstLaunchGuidePage = .welcome
    @State private var copyVisible = false
    @State private var animatesForward = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let pages = FirstLaunchGuidePage.allCases

    var body: some View {
        ZStack {
            DarkroomTheme.screenGradient.ignoresSafeArea()
            DarkroomTheme.softGlow
                .opacity(copyVisible ? 1 : 0.25)
                .ignoresSafeArea()

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

                ZStack {
                    guidePage(page)
                        .id(page)
                        .transition(pageTransition)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .gesture(pageSwipeGesture)

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
            revealCopy(animated: !reduceMotion)
        }
        .accessibilityAddTraits(.isModal)
    }

    @ViewBuilder
    private func guidePage(_ step: FirstLaunchGuidePage) -> some View {
        ScrollView {
            VStack(spacing: 18) {
                FirstLaunchGuideDemoStage(page: step, reduceMotion: reduceMotion)
                    .padding(.top, 8)

                Text(step.title)
                    .font(step.isWelcome ? .largeTitle.weight(.bold) : .title2.weight(.bold))
                    .foregroundStyle(DarkroomTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)
                    .lineLimit(3)
                    .opacity(copyVisible ? 1 : 0)
                    .offset(y: copyVisible ? 0 : 16)
                    .accessibilityAddTraits(.isHeader)

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(step.bullets.enumerated()), id: \.offset) { _, bullet in
                        HStack(alignment: .top, spacing: 10) {
                            Text("•")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(DarkroomTheme.accent)
                            Text(bullet)
                                .font(.body)
                                .foregroundStyle(DarkroomTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding(.horizontal, 8)
                .opacity(copyVisible ? 1 : 0)
                .offset(y: copyVisible ? 0 : 12)

                if step.isWelcome {
                    Text(AppStoreLaunchSupport.freemiumLaunchNote)
                        .font(.subheadline)
                        .foregroundStyle(DarkroomTheme.textTertiary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 2)
                        .opacity(copyVisible ? 1 : 0)
                }

                Spacer(minLength: 12)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            .padding(.vertical, 8)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(step.title). \(step.bodyText)")
    }

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(pages) { step in
                Capsule()
                    .fill(step == page ? DarkroomTheme.accent : DarkroomTheme.strokeBright.opacity(0.55))
                    .frame(width: step == page ? 20 : 7, height: 7)
            }
        }
        .frame(minHeight: 20)
        .animation(pageAnimation, value: page)
    }

    private var pageIndicatorLabel: String {
        let index = (pages.firstIndex(of: page) ?? 0) + 1
        return String(format: FirstLaunchGuideCopy.pageIndicatorAccessibilityFormat, index, pages.count)
    }

    private var pageTransition: AnyTransition {
        if reduceMotion {
            return .opacity
        }
        return .asymmetric(
            insertion: .move(edge: animatesForward ? .trailing : .leading)
                .combined(with: .opacity),
            removal: .move(edge: animatesForward ? .leading : .trailing)
                .combined(with: .opacity)
        )
    }

    private var pageAnimation: Animation? {
        FirstLaunchGuideMotion.pageAnimation(reduceMotion: reduceMotion)
    }

    private var pageSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 40, coordinateSpace: .local)
            .onEnded { value in
                let horizontal = value.translation.width
                let vertical = value.translation.height
                guard abs(horizontal) > abs(vertical), abs(horizontal) > 50 else { return }
                if horizontal < 0 {
                    advanceOrFinish()
                } else {
                    goBack()
                }
            }
    }

    private func revealCopy(animated: Bool) {
        if !animated || reduceMotion {
            copyVisible = true
            return
        }
        copyVisible = false
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: FirstLaunchGuideMotion.frameDelayNanoseconds)
            withAnimation(FirstLaunchGuideMotion.stepContentAnimation(reduceMotion: false)) {
                copyVisible = true
            }
        }
    }

    private func animateToPage(_ newPage: FirstLaunchGuidePage, forward: Bool) {
        guard newPage != page else { return }
        animatesForward = forward

        if reduceMotion {
            page = newPage
            copyVisible = true
            return
        }

        withAnimation(FirstLaunchGuideMotion.pageAnimation(reduceMotion: false)) {
            page = newPage
            copyVisible = false
        }

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: FirstLaunchGuideMotion.frameDelayNanoseconds)
            withAnimation(FirstLaunchGuideMotion.stepContentAnimation(reduceMotion: false)) {
                copyVisible = true
            }
        }
    }

    private func advanceOrFinish() {
        guard let index = pages.firstIndex(of: page) else {
            finish()
            return
        }
        let next = index + 1
        if next < pages.count {
            animateToPage(pages[next], forward: true)
        } else {
            finish()
        }
    }

    private func goBack() {
        guard let index = pages.firstIndex(of: page), index > 0 else { return }
        animateToPage(pages[index - 1], forward: false)
    }

    private func finish() {
        onFinished()
    }
}

#Preview("First Launch Guide") {
    FirstLaunchGuideView(onFinished: {})
}
