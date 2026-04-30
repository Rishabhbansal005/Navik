import Foundation
import Combine

final class DataStore: ObservableObject, @unchecked Sendable {
    @Published var rooms: [RoomModel] = []
    @Published var items: [ItemModel] = []

    private let roomsKey = "navik_rooms_v4"
    private let itemsKey = "navik_items_v4"

    init() { load(); seedDefaultRoomsIfNeeded() }

    // MARK: - Persistence
    private func load() {
        if let d = UserDefaults.standard.data(forKey: roomsKey),
           let r = try? JSONDecoder().decode([RoomModel].self, from: d) { rooms = r }
        if let d = UserDefaults.standard.data(forKey: itemsKey),
           let i = try? JSONDecoder().decode([ItemModel].self, from: d) { items = i }
    }

    private func save() {
        if let d = try? JSONEncoder().encode(rooms) { UserDefaults.standard.set(d, forKey: roomsKey) }
        if let d = try? JSONEncoder().encode(items)  { UserDefaults.standard.set(d, forKey: itemsKey) }
    }

    func seedDefaultRoomsIfNeeded() {
        if rooms.isEmpty { rooms = RoomModel.defaultRooms; save() }
    }

    // MARK: - Rooms CRUD
    func addRoom(_ r: RoomModel)    { rooms.append(r); save() }
    func updateRoom(_ r: RoomModel) { if let i = rooms.firstIndex(where: { $0.id == r.id }) { rooms[i] = r; save() } }
    func deleteRoom(_ r: RoomModel) { rooms.removeAll { $0.id == r.id }; save() }
    func moveRooms(from: IndexSet, to: Int) { rooms.move(fromOffsets: from, toOffset: to); save() }

    // MARK: - Items CRUD
    func addItem(_ i: ItemModel)    { items.append(i); save() }
    func updateItem(_ i: ItemModel) { if let idx = items.firstIndex(where: { $0.id == i.id }) { items[idx] = i; save() } }
    func deleteItem(_ i: ItemModel) { items.removeAll { $0.id == i.id }; save() }

    // MARK: - Queries
    func items(in room: RoomModel) -> [ItemModel]  { items.filter { $0.roomID == room.id } }
    func room(for item: ItemModel) -> RoomModel?   { rooms.first { $0.id == item.roomID } }
    func search(_ q: String) -> [ItemModel] {
        guard !q.isEmpty else { return items }
        return items.filter {
            $0.name.localizedCaseInsensitiveContains(q) ||
            $0.locationDescription.localizedCaseInsensitiveContains(q)
        }
    }

    func resetAll() { rooms.removeAll(); items.removeAll(); seedDefaultRoomsIfNeeded() }
}
