import SwiftUI

struct ItemsView: View {
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var hapticsManager: HapticsManager

    @State private var searchText      = ""
    @State private var showingAdd      = false
    @State private var selectedItem: ItemModel?
    @State private var selectedRoomID: UUID? = nil
    @Namespace private var zoomNS

    var filtered: [ItemModel] {
        var base = selectedRoomID == nil ? dataStore.items : dataStore.items.filter { $0.roomID == selectedRoomID }
        if !searchText.isEmpty {
            base = base.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.locationDescription.localizedCaseInsensitiveContains(searchText)
            }
        }
        return base.sorted { $0.timestamp > $1.timestamp }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                VStack(spacing: 0) {
                    filterChips
                    Divider().opacity(0.3)
                    if filtered.isEmpty { emptyState } else { itemsList }
                }
            }
            .navigationTitle("Items")
            .searchable(text: $searchText,
                        placement: .navigationBarDrawer(displayMode: .always),
                        prompt: "Search items…")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true } label: {
                        Image(systemName: "plus")
                            .navCircleButton(color: AppTheme.primary, size: 36)
                    }
                    .buttonStyle(.plain)
                    .matchedTransitionSource(id: "addItem", in: zoomNS)
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddItemView()
                    .navigationTransition(.zoom(sourceID: "addItem", in: zoomNS))
            }
            .fullScreenCover(item: $selectedItem) { item in
                ARFindView(item: item)
            }
        }
    }

    // MARK: - Filter Chips
    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(
                    label: "All", icon: "square.grid.2x2.fill",
                    count: dataStore.items.count, isSelected: selectedRoomID == nil
                ) {
                    withAnimation(.spring(duration: 0.3)) { selectedRoomID = nil }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
                ForEach(dataStore.rooms) { room in
                    FilterChip(
                        label: room.name, icon: room.iconName,
                        count: dataStore.items(in: room).count,
                        isSelected: selectedRoomID == room.id
                    ) {
                        withAnimation(.spring(duration: 0.3)) { selectedRoomID = room.id }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }
            }
            .padding(.horizontal, AppTheme.md)
            .padding(.vertical, 10)
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        ContentUnavailableView {
            Label(selectedRoomID != nil ? "No Items in Room" : "No Items Yet",
                  systemImage: "cube.box")
                .font(.navTitle2)
        } description: {
            Text(selectedRoomID != nil
                 ? "Tap + to save an item's location in this room."
                 : "Tap + to save your first item's location using AR.")
            .font(.navCallout).foregroundStyle(.secondary)
        }
    }

    // MARK: - Items List
    private var itemsList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(filtered) { item in
                    ItemCard(item: item)
                        .onTapGesture { selectedItem = item }
                        .contextMenu {
                            Button(role: .destructive) { dataStore.deleteItem(item) }
                            label: { Label("Delete Item", systemImage: "trash") }
                        }
                }
            }
            .padding(AppTheme.md)
        }
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let label: String
    let icon: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(label)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                if count > 0 {
                    Text("\(count)")
                        .font(.system(.caption2, design: .rounded).weight(.bold))
                        .padding(.horizontal, 5).padding(.vertical, 2)
                        .background(isSelected ? Color.white.opacity(0.3) : AppTheme.primary.opacity(0.15), in: Capsule())
                }
            }
            .foregroundStyle(isSelected ? .white : AppTheme.primary)
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(isSelected ? AppTheme.primary : AppTheme.surface, in: Capsule())
            .shadow(color: isSelected ? AppTheme.primary.opacity(0.3) : .clear, radius: 6, y: 3)
        }
        .animation(.spring(duration: 0.3), value: isSelected)
    }
}

// MARK: - Item Card
struct ItemCard: View {
    @EnvironmentObject var dataStore: DataStore
    let item: ItemModel
    var room: RoomModel? { dataStore.room(for: item) }

    var body: some View {
        HStack(spacing: AppTheme.md) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.radiusSm)
                    .fill(AppTheme.primary.opacity(0.10))
                    .frame(width: 54, height: 54)
                if let emoji = item.emoji {
                    Text(emoji).font(.system(size: 30))
                } else if let data = item.imageData, let img = UIImage(data: data) {
                    Image(uiImage: img).resizable().scaledToFill()
                        .frame(width: 54, height: 54)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusSm))
                } else {
                    Image(systemName: item.iconName)
                        .font(.system(size: 24))
                        .foregroundStyle(AppTheme.primary)
                }
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name).font(.navHeadline).lineLimit(1)
                if let room {
                    Label(room.name, systemImage: room.iconName)
                        .font(.navCaption).foregroundStyle(.secondary)
                }
                if !item.locationDescription.isEmpty {
                    Text(item.locationDescription)
                        .font(.navCaption2).foregroundStyle(.tertiary).lineLimit(1)
                }
            }

            Spacer()

            // Quality indicator + chevron
            VStack(alignment: .trailing, spacing: 6) {
                qualityDot
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .navCard()
    }

    private var qualityDot: some View {
        let q = item.saveQuality
        let color: Color = q > 0.7 ? AppTheme.success : q > 0.4 ? AppTheme.warning : AppTheme.danger
        return Circle().fill(color).frame(width: 8, height: 8)
            .overlay(Circle().stroke(color.opacity(0.3), lineWidth: 2).frame(width: 14, height: 14))
    }
}

#Preview("Items Empty") {
    ItemsView().environmentObject(DataStore()).environmentObject(HapticsManager())
}
