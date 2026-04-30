import SwiftUI

struct RoomsView: View {
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var hapticsManager: HapticsManager

    @State private var showingAdd        = false
    @State private var editMode: EditMode = .inactive
    @State private var roomToEdit: RoomModel?
    @State private var roomToDelete: RoomModel?
    @State private var showDeleteAlert   = false
    @State private var showResetAlert    = false
    @Namespace private var zoomNS

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                if dataStore.rooms.isEmpty { emptyState } else { roomsList }
            }
            .navigationTitle("Rooms")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showingAdd = true } label: {
                        Image(systemName: "plus")
                            .navCircleButton(color: AppTheme.primary, size: 36)
                    }
                    .buttonStyle(.plain)
                    .matchedTransitionSource(id: "addRoom", in: zoomNS)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if !dataStore.rooms.isEmpty { EditButton() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showResetAlert = true } label: {
                        Image(systemName: "trash")
                            .navCircleButton(color: AppTheme.danger, size: 36)
                    }
                    .buttonStyle(.plain)
                }
            }
            .environment(\.editMode, $editMode)
            .sheet(isPresented: $showingAdd) {
                AddRoomSheet()
                    .navigationTransition(.zoom(sourceID: "addRoom", in: zoomNS))
            }
            .sheet(item: $roomToEdit) { EditRoomSheet(room: $0) }
            .alert("Delete Room", isPresented: $showDeleteAlert, presenting: roomToDelete) { room in
                Button("Cancel", role: .cancel) { roomToDelete = nil }
                Button("Delete", role: .destructive) { performDelete(room) }
            } message: { room in
                let n = dataStore.items(in: room).count
                Text(n > 0 ? "This room has \(n) item(s). They will be reassigned." : "Delete \(room.name)?")
            }
            .alert("Reset All Data", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset",  role: .destructive) { dataStore.resetAll() }
            } message: {
                Text("All rooms and saved locations will be permanently deleted.")
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Rooms", systemImage: "door.left.hand.closed").font(.navTitle2)
        } description: {
            Text("Tap + to create your first room.").font(.navCallout).foregroundStyle(.secondary)
        }
    }

    private var roomsList: some View {
        List {
            ForEach(dataStore.rooms) { room in
                RoomCard(room: room)
                    .contentShape(Rectangle())
                    .onTapGesture { if editMode == .inactive { roomToEdit = room } }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) { roomToDelete = room; showDeleteAlert = true }
                        label: { Label("Delete", systemImage: "trash") }
                        Button { roomToEdit = room }
                        label: { Label("Edit", systemImage: "pencil") }
                        .tint(AppTheme.accent)
                    }
                    .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
            .onMove { dataStore.moveRooms(from: $0, to: $1) }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func performDelete(_ room: RoomModel) {
        if let dest = dataStore.rooms.first(where: { $0.id != room.id }) {
            dataStore.items(in: room).forEach { var i = $0; i.roomID = dest.id; dataStore.updateItem(i) }
        }
        dataStore.deleteRoom(room)
        roomToDelete = nil
    }
}

// MARK: - Room Card
struct RoomCard: View {
    @EnvironmentObject var dataStore: DataStore
    let room: RoomModel
    var count: Int { dataStore.items(in: room).count }

    var body: some View {
        HStack(spacing: AppTheme.md) {
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.radiusSm)
                    .fill(AppTheme.primary.opacity(0.10))
                    .frame(width: 50, height: 50)
                Image(systemName: room.iconName)
                    .font(.system(size: 22))
                    .foregroundStyle(AppTheme.primary)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(room.name).font(.navHeadline)
                Text(count == 0 ? "No items" : "\(count) item\(count == 1 ? "" : "s")")
                    .font(.navCaption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption2.weight(.semibold)).foregroundStyle(.tertiary)
        }
        .navCard()
    }
}

// MARK: - Add Room Sheet
struct AddRoomSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataStore: DataStore
    @State private var name = ""
    @State private var icon = "bed.double.fill"

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") { TextField("e.g. Bedroom", text: $name).font(.navBody) }
                Section("Icon") { iconScroll }
            }
            .navigationTitle("Add Room").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { dataStore.addRoom(RoomModel(name: name, iconName: icon)); dismiss() }
                        .disabled(name.isEmpty).font(.navHeadline)
                }
            }
        }
    }

    private var iconScroll: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(roomIcons, id: \.self) { i in
                    roomIconButton(i, selected: icon == i) {
                        withAnimation(.spring(duration: 0.2)) { icon = i }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }
            }.padding(.vertical, 8)
        }.listRowInsets(EdgeInsets())
    }
}

// MARK: - Edit Room Sheet
struct EditRoomSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataStore: DataStore
    let room: RoomModel
    @State private var name: String
    @State private var icon: String

    init(room: RoomModel) { self.room = room; _name = State(initialValue: room.name); _icon = State(initialValue: room.iconName) }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") { TextField("Room Name", text: $name).font(.navBody) }
                Section("Icon") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(roomIcons, id: \.self) { i in
                                roomIconButton(i, selected: icon == i) {
                                    withAnimation(.spring(duration: 0.2)) { icon = i }
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                }
                            }
                        }.padding(.vertical, 8)
                    }.listRowInsets(EdgeInsets())
                }
            }
            .navigationTitle("Edit Room").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        var r = room; r.name = name; r.iconName = icon
                        dataStore.updateRoom(r); dismiss()
                    }
                    .disabled(name.isEmpty).font(.navHeadline)
                }
            }
        }
    }
}

private func roomIconButton(_ icon: String, selected: Bool, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        Image(systemName: icon).font(.title2)
            .foregroundStyle(selected ? AppTheme.primary : .primary)
            .frame(width: 50, height: 50)
            .background(selected ? AppTheme.primary.opacity(0.15) : AppTheme.surface)
            .clipShape(Circle())
            .overlay(Circle().strokeBorder(AppTheme.primary, lineWidth: selected ? 2 : 0))
            .animation(.spring(duration: 0.2), value: selected)
    }
}

private let roomIcons = [
    "bed.double.fill","fork.knife","sofa.fill","shower.fill",
    "books.vertical.fill","car.fill","storefront.fill","tent.fill",
    "house.fill","building.2.fill","lamp.desk.fill","cabinet.fill"
]

#Preview { RoomsView().environmentObject(DataStore()).environmentObject(HapticsManager()) }
