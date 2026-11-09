import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case badResponse
    case apiMessage(String)
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "That link doesn't look valid. Paste a full TikTok link."
        case .badResponse: return "Couldn't reach the download server. Check your connection and try again."
        case .apiMessage(let m): return m
        case .noData: return "No video found. The link may be private, deleted, or invalid."
        }
    }
}

final class APIService {
    static func fetch(urlString: String) async throws -> TikWMData {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.contains("tiktok.com") else { throw APIError.invalidURL }
        guard let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://www.tikwm.com/api/?url=\(encoded)&hd=1") else {
            throw APIError.invalidURL
        }
        var req = URLRequest(url: url)
        req.setValue("TikGrab/1.0", forHTTPHeaderField: "User-Agent")
        req.timeoutInterval = 30
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.badResponse
        }
        let decoded = try JSONDecoder().decode(TikWMResponse.self, from: data)
        if let code = decoded.code, code != 0 {
            throw APIError.apiMessage(decoded.msg ?? "This video couldn't be fetched. It may be private.")
        }
        guard let d = decoded.data, (d.play != nil || d.hdplay != nil) else {
            throw APIError.noData
        }
        return d
    }
}
