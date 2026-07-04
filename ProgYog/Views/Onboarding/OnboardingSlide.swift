//
//  OnboardingSlide.swift
//  ProgYog
//

struct OnboardingSlide {
    let index: Int
    let systemImage: String
    let title: String
    let body: String
    let isEmailSlide: Bool

    static let slides: [OnboardingSlide] = [
        OnboardingSlide(
            index: 0,
            systemImage: "figure.yoga",
            title: "Welcome to progYog",
            body: "A progressive yoga tracker where every session builds on the last. The app tracks your range, technique, and exertion — and tells you when you're ready to advance.",
            isEmailSlide: false
        ),
        OnboardingSlide(
            index: 1,
            systemImage: "person.fill",
            title: "Biotensegrity",
            body: "Your body is a tensegrity system — soft tissue (fascia, muscle, ligament) and skeletal compression work together. Mobility comes from rebalancing both systems, not stretching one in isolation.",
            isEmailSlide: false
        ),
        OnboardingSlide(
            index: 2,
            systemImage: "4.circle.fill",
            title: "The 4+1 Method",
            body: "Four rounds of dynamic yoga build the movement pattern. One final isometric round locks it in neurologically. That combination is what produces results — session after session.",
            isEmailSlide: false
        ),
        OnboardingSlide(
            index: 3,
            systemImage: "lungs.fill",
            title: "Base, Posture & Breath",
            body: "Every session: establish your base first, stack posture on top, find structure in the joints, then breathe through discomfort. The order matters.",
            isEmailSlide: false
        ),
        OnboardingSlide(
            index: 4,
            systemImage: "hand.thumbsup",
            title: "Technique",
            body: "Technique is rated 1–10 for every set. The app uses your technique score to track progress and decide when you're ready to advance to the next skill level.",
            isEmailSlide: false
        ),
        OnboardingSlide(
            index: 5,
            systemImage: "bolt.heart",
            title: "Discomfort vs. Pain",
            body: "Discomfort is the goal — lean in with courage. Pain is a signal to stop. Slow is smooth. Smooth is fast. Never force range you haven't earned.",
            isEmailSlide: false
        ),
        OnboardingSlide(
            index: 6,
            systemImage: "calendar.badge.clock",
            title: "Patience",
            body: "Some days certain families won't progress. That's completely normal. The system works over weeks, not single sessions. Show up, follow the protocol, trust the process.",
            isEmailSlide: false
        ),
        OnboardingSlide(
            index: 7,
            systemImage: "envelope",
            title: "Stay Connected",
            body: "Enter your email to receive coaching tips, progression cues, and a structured training sequence delivered to your inbox.",
            isEmailSlide: true
        ),
    ]
}
