//
//  EmailOptInService.swift
//  ProgYog
//

import Foundation

enum EmailOptInService {
    // Replace these with your ConvertKit / Mailchimp / etc. endpoint and key.
    private static let endpointURL = URL(string: "https://api.example.com/v3/subscribe")!
    private static let apiKey = "REPLACE_ME"

    static func submit(email: String) async throws -> (success: Bool, message: String) {
        var request = URLRequest(url: endpointURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["api_key": apiKey, "email": email]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        let success = (200..<300).contains(status)
        let message = (try? JSONDecoder().decode([String: String].self, from: data))?["message"]
            ?? (success ? "You're on the list!" : "Something went wrong. Try again later.")
        return (success, message)
    }
}
