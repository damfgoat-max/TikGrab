import Foundation

struct TikWMResponse: Codable {
    let code: Int?
    let msg: String?
    let data: TikWMData?
}

struct TikWMData: Codable {
    let title: String?
    let cover: String?
    let play: String?
    let wmplay: String?
    let hdplay: String?
    let music: String?
    let duration: Int?
    let size: Int?
    let hdSize: Int?
    let author: TikAuthor?

    enum CodingKeys: String, CodingKey {
        case title, cover, play, wmplay, hdplay, music, duration, size
        case hdSize = "hd_size"
        case author
    }

    var hdURLString: String? {
        if let h = hdplay, !h.isEmpty { return h }
        return play
    }
}

struct TikAuthor: Codable {
    let nickname: String?
    let uniqueId: String?
    let avatar: String?

    enum CodingKeys: String, CodingKey {
        case nickname, avatar
        case uniqueId = "unique_id"
    }
}

struct HistoryItem: Codable, Identifiable, Equatable {
    var id: String
    var title: String
    var author: String
    var cover: String?
    var originalLink: String
    var date: Date
    var playURL: String?
    var hdPlayURL: String?
    var wmPlayURL: String?
    var musicURL: String?
    var duration: Int?
}
