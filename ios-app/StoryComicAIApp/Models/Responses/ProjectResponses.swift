import Foundation

struct ProjectResponseDTO: Codable, Identifiable {
    let id: UUID
    let title: String
    let storyText: String
    let style: StoryStyle
    let targetPages: Int
    let freePreviewPages: Int
    let status: String
    let isUnlocked: Bool
    let createdAtUTC: Date
    let updatedAtUTC: Date

    init(
        id: UUID,
        title: String,
        storyText: String,
        style: StoryStyle,
        targetPages: Int,
        freePreviewPages: Int,
        status: String,
        isUnlocked: Bool,
        createdAtUTC: Date,
        updatedAtUTC: Date
    ) {
        self.id = id
        self.title = title
        self.storyText = storyText
        self.style = style
        self.targetPages = targetPages
        self.freePreviewPages = freePreviewPages
        self.status = status
        self.isUnlocked = isUnlocked
        self.createdAtUTC = createdAtUTC
        self.updatedAtUTC = updatedAtUTC
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        id = try container.decode(UUID.self, forAnyKey: ["id"])
        title = try container.decode(String.self, forAnyKey: ["title"])
        storyText = try container.decodeIfPresent(String.self, forAnyKey: ["storyText", "story_text"]) ?? ""
        style = try container.decode(StoryStyle.self, forAnyKey: ["style"])
        targetPages = try container.decode(Int.self, forAnyKey: ["targetPages", "target_pages"])
        freePreviewPages = try container.decodeIfPresent(Int.self, forAnyKey: ["freePreviewPages", "free_preview_pages"]) ?? 3
        status = try container.decodeIfPresent(String.self, forAnyKey: ["status"]) ?? "draft"
        isUnlocked = try container.decodeIfPresent(Bool.self, forAnyKey: ["isUnlocked", "is_unlocked"]) ?? false
        createdAtUTC = try container.decode(Date.self, forAnyKey: ["createdAtUtc", "created_at_utc"])
        updatedAtUTC = try container.decode(Date.self, forAnyKey: ["updatedAtUtc", "updated_at_utc"])
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: AnyCodingKey.self)
        try container.encode(id, forKey: AnyCodingKey("id"))
        try container.encode(title, forKey: AnyCodingKey("title"))
        try container.encode(storyText, forKey: AnyCodingKey("storyText"))
        try container.encode(style, forKey: AnyCodingKey("style"))
        try container.encode(targetPages, forKey: AnyCodingKey("targetPages"))
        try container.encode(freePreviewPages, forKey: AnyCodingKey("freePreviewPages"))
        try container.encode(status, forKey: AnyCodingKey("status"))
        try container.encode(isUnlocked, forKey: AnyCodingKey("isUnlocked"))
        try container.encode(createdAtUTC, forKey: AnyCodingKey("createdAtUtc"))
        try container.encode(updatedAtUTC, forKey: AnyCodingKey("updatedAtUtc"))
    }
}

struct ProjectListResponseDTO: Codable {
    let items: [ProjectResponseDTO]
    let nextCursor: String?
}
