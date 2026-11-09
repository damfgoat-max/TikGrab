import Foundation

final class HistoryStore: ObservableObject {
    @Published var items: [HistoryItem] = []
    private let key = "tikgrab_history_v1"

    init() { load() }

    func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([HistoryItem].self, from: data) else {
            items = []
            return
        }
        items = decoded
    }

    func save() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func add(_ item: HistoryItem) {
        if let idx = items.firstIndex(where: { $0.originalLink == item.originalLink }) {
            items.remove(at: idx)
        }
        items.insert(item, at: 0)
        if items.count > 100 { items = Array(items.prefix(100)) }
        save()
    }

    func delete(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        save()
    }

    func delete(item: HistoryItem) {
        items.removeAll { $0.id == item.id }
        save()
    }

    func clearAll() {
        items = []
        save()
    }
}
