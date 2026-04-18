import Foundation

class FeedbackService {
    static let shared = FeedbackService()

    private let endpointURL = URL(string: AppConstants.feedbackEndpoint)!

    private init() {}

    func submitFeedback(
        name: String,
        email: String,
        subject: String,
        message: String,
        completion: @escaping (Result<Int, Error>) -> Void
    ) {
        let body: [String: String] = [
            "name": name,
            "email": email,
            "subject": subject,
            "message": message,
            "app_name": AppConstants.feedbackAppName
        ]

        guard let httpBody = try? JSONSerialization.data(withJSONObject: body) else {
            completion(.failure(FeedbackError.invalidData))
            return
        }

        var request = URLRequest(url: endpointURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = httpBody
        request.timeoutInterval = 30

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    completion(.failure(FeedbackError.invalidResponse))
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(FeedbackError.noData))
                }
                return
            }

            if httpResponse.statusCode == 200 {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = json["success"] as? Bool, success {
                    DispatchQueue.main.async {
                        completion(.success(json["id"] as? Int ?? 0))
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(.failure(FeedbackError.serverError))
                    }
                }
            } else {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let errorMessage = json["error"] as? String {
                    DispatchQueue.main.async {
                        completion(.failure(FeedbackError.custom(errorMessage)))
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(.failure(FeedbackError.httpError(httpResponse.statusCode)))
                    }
                }
            }
        }.resume()
    }
}

enum FeedbackError: LocalizedError {
    case invalidData
    case invalidResponse
    case noData
    case serverError
    case httpError(Int)
    case custom(String)

    var errorDescription: String? {
        switch self {
        case .invalidData:
            return "Invalid data format"
        case .invalidResponse:
            return "Invalid server response"
        case .noData:
            return "No data received"
        case .serverError:
            return "Server returned an error"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .custom(let message):
            return message
        }
    }
}
