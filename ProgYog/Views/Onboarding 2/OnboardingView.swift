//
//  OnboardingView.swift
//  ProgYog
//

import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("onboardingEmail") private var storedEmail: String = ""
    @State private var currentPage = 0
    @State private var emailDraft = ""
    @State private var isSubmitting = false
    @State private var submitError: String? = nil
    @State private var submitAttempted = false
    @Environment(\.dismiss) private var dismiss

    private let slides = OnboardingSlide.slides

    var body: some View {
        TabView(selection: $currentPage) {
            ForEach(slides.indices, id: \.self) { i in
                slideView(for: slides[i])
                    .tag(i)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .background(Color(.systemBackground))
        .ignoresSafeArea(edges: .bottom)
        .keyboardDoneToolbar()
        #if DEBUG
        .overlay(alignment: .topTrailing) {
            Button {
                hasSeenOnboarding = true
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .padding(16)
            }
        }
        #endif
    }

    @ViewBuilder
    private func slideView(for slide: OnboardingSlide) -> some View {
        VStack(spacing: 0) {
            Spacer()

            Image(systemName: slide.systemImage)
                .font(.system(size: 64))
                .foregroundStyle(Color.accentColor)
                .padding(.bottom, 28)

            Text(slide.title)
                .font(.title2.bold())
                .multilineTextAlignment(.center)
                .padding(.bottom, 12)

            Text(slide.body)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 40)

            if slide.isEmailSlide {
                emailCTA
            } else {
                nextButton(isLast: slide.index == slides.count - 2)
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    @ViewBuilder
    private var emailCTA: some View {
        VStack(spacing: 14) {
            TextField("your@email.com", text: $emailDraft)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .padding()
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))

            if let err = submitError {
                Text(err)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            Button {
                guard !emailDraft.isEmpty, emailDraft.contains("@") else { return }
                isSubmitting = true
                submitError = nil
                Task {
                    do {
                        let result = try await EmailOptInService.submit(email: emailDraft)
                        storedEmail = emailDraft
                        if !result.success { submitError = result.message }
                    } catch {
                        storedEmail = emailDraft
                        submitError = "Couldn't reach the server. Your email was saved locally."
                    }
                    isSubmitting = false
                    submitAttempted = true
                }
            } label: {
                Group {
                    if isSubmitting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Join")
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(emailDraft.isEmpty || !emailDraft.contains("@") || isSubmitting)

            if submitAttempted {
                Button("Get Started") {
                    hasSeenOnboarding = true
                    dismiss()
                }
                .buttonStyle(.bordered)
                .disabled(isSubmitting)
            }

            Button("Skip for now") {
                hasSeenOnboarding = true
                dismiss()
            }
            .foregroundStyle(.secondary)
            .font(.callout)
        }
    }

    @ViewBuilder
    private func nextButton(isLast: Bool) -> some View {
        Button(isLast ? "Almost there →" : "Next") {
            withAnimation {
                currentPage += 1
            }
        }
        .buttonStyle(.borderedProminent)
        .frame(maxWidth: .infinity)
    }
}

#if DEBUG
#Preview {
    OnboardingView()
}
#endif
