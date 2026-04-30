import SwiftUI
import PhotosUI

struct AddItemView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataStore: DataStore

    @State private var itemName      = ""
    @State private var selectedRoom: RoomModel?
    @State private var locationDesc  = ""
    @State private var showingAR     = false

    @State private var iconType: IconType   = .symbol
    @State private var selectedSymbol       = "cube.box.fill"
    @State private var selectedEmoji        = "📦"
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedPhotoData: Data?

    enum IconType: CaseIterable { case symbol, emoji, photo }

    var canProceed: Bool { !itemName.trimmingCharacters(in: .whitespaces).isEmpty && selectedRoom != nil }

    var body: some View {
        NavigationStack {
            Form {
                detailsSection
                roomSection
                iconSection
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Next →") { showingAR = true }
                        .disabled(!canProceed)
                        .font(.navHeadline)
                }
            }
            .fullScreenCover(isPresented: $showingAR) {
                if let room = selectedRoom {
                    ARSaveView(
                        itemName:            itemName.trimmingCharacters(in: .whitespaces),
                        roomID:              room.id,
                        iconName:            selectedSymbol,
                        emoji:               iconType == .emoji  ? selectedEmoji     : nil,
                        photoData:           iconType == .photo  ? selectedPhotoData : nil,
                        locationDescription: locationDesc
                    )
                }
            }
        }
    }

    // MARK: - Sections
    private var detailsSection: some View {
        Section {
            TextField("Item Name", text: $itemName)
                .font(.navBody)
            TextField("Location hint (e.g. top drawer)", text: $locationDesc)
                .font(.navCallout)
        } header: {
            Text("Details")
        }
    }

    private var roomSection: some View {
        Section("Room") {
            Picker("Select Room", selection: $selectedRoom) {
                Text("Choose a room").tag(nil as RoomModel?)
                ForEach(dataStore.rooms) { room in
                    Label(room.name, systemImage: room.iconName).tag(room as RoomModel?)
                }
            }
        }
    }

    private var iconSection: some View {
        Section("Icon") {
            Picker("Type", selection: $iconType) {
                Label("Symbol", systemImage: "square.grid.3x3.fill").tag(IconType.symbol)
                Label("Emoji",  systemImage: "face.smiling").tag(IconType.emoji)
                Label("Photo",  systemImage: "photo").tag(IconType.photo)
            }
            .pickerStyle(.segmented)
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)

            // Preview
            HStack { Spacer(); iconPreview; Spacer() }
                .listRowBackground(Color.clear).padding(.vertical, 6)

            // Picker content
            switch iconType {
            case .symbol: symbolPicker
            case .emoji:  emojiPicker
            case .photo:  photoPicker
            }
        }
    }

    @ViewBuilder
    private var iconPreview: some View {
        ZStack {
            Circle().fill(AppTheme.primary.opacity(0.12)).frame(width: 88, height: 88)
            switch iconType {
            case .symbol:
                Image(systemName: selectedSymbol).font(.system(size: 44)).foregroundStyle(AppTheme.primary)
            case .emoji:
                Text(selectedEmoji).font(.system(size: 52))
            case .photo:
                if let data = selectedPhotoData, let img = UIImage(data: data) {
                    Image(uiImage: img).resizable().scaledToFill()
                        .frame(width: 88, height: 88).clipShape(Circle())
                } else {
                    Image(systemName: "photo").font(.system(size: 44)).foregroundStyle(AppTheme.primary)
                }
            }
        }
        .animation(.spring(duration: 0.3), value: iconType)
        .animation(.spring(duration: 0.2), value: selectedSymbol)
    }

    private var symbolPicker: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(SymbolCategory.allCases, id: \.self) { cat in
                VStack(alignment: .leading, spacing: 8) {
                    Text(cat.title).font(.navCaption).foregroundStyle(.secondary).padding(.leading, 2)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(cat.symbols, id: \.self) { sym in
                                symbolButton(sym)
                            }
                        }.padding(.horizontal, 2)
                    }
                }
            }
        }
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
    }

    private func symbolButton(_ symbol: String) -> some View {
        Button {
            withAnimation(.spring(duration: 0.2)) { selectedSymbol = symbol }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(selectedSymbol == symbol ? AppTheme.primary : .primary)
                .frame(width: 50, height: 50)
                .background(selectedSymbol == symbol ? AppTheme.primary.opacity(0.15) : AppTheme.surface)
                .clipShape(Circle())
                .overlay(Circle().strokeBorder(AppTheme.primary, lineWidth: selectedSymbol == symbol ? 2 : 0))
                .animation(.spring(duration: 0.2), value: selectedSymbol)
        }
    }

    private var emojiPicker: some View {
        VStack(spacing: 10) {
            TextField("Paste emoji", text: $selectedEmoji)
                .font(.system(size: 44)).multilineTextAlignment(.center)
                .onChange(of: selectedEmoji) { _, v in
                    selectedEmoji = String(v.filter { $0.isEmoji }.prefix(1))
                }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(commonEmojis, id: \.self) { e in
                        Button { withAnimation { selectedEmoji = e } } label: {
                            Text(e).font(.system(size: 38))
                                .frame(width: 56, height: 56)
                                .background(selectedEmoji == e ? AppTheme.accent.opacity(0.2) : AppTheme.surface)
                                .clipShape(Circle())
                        }
                    }
                }
            }
        }
        .listRowInsets(EdgeInsets()).listRowBackground(Color.clear)
    }

    private var photoPicker: some View {
        VStack(spacing: 10) {
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Label("Choose Photo", systemImage: "photo.on.rectangle.angled")
                    .font(.navHeadline).foregroundStyle(.white).frame(maxWidth: .infinity)
                    .padding().background(AppTheme.primary, in: RoundedRectangle(cornerRadius: AppTheme.radiusSm))
            }
            .onChange(of: selectedPhoto) { _, item in
                Task { if let d = try? await item?.loadTransferable(type: Data.self) { selectedPhotoData = d } }
            }
            if selectedPhotoData != nil {
                Button(role: .destructive) { selectedPhotoData = nil; selectedPhoto = nil } label: {
                    Label("Remove", systemImage: "trash").font(.navCallout)
                }
            }
        }
        .listRowInsets(EdgeInsets()).listRowBackground(Color.clear)
    }

    private let commonEmojis = ["📦","🔑","📄","💳","💊","👓","📱","🎮","🎧","📚","🎒","💼","🏠","🚗","🔧"]
}

enum SymbolCategory: CaseIterable {
    case keys, documents, electronics, health, accessories, misc
    var title: String {
        switch self {
        case .keys:        return "Keys & Access"
        case .documents:   return "Documents"
        case .electronics: return "Electronics"
        case .health:      return "Health"
        case .accessories: return "Accessories"
        case .misc:        return "Misc"
        }
    }
    var symbols: [String] {
        switch self {
        case .keys:        return ["key.fill","lock.fill","door.left.hand.open","car.fill","house.fill"]
        case .documents:   return ["doc.fill","folder.fill","newspaper.fill","book.fill","bookmark.fill","envelope.fill"]
        case .electronics: return ["phone.fill","headphones","keyboard.fill","gamecontroller.fill","laptopcomputer","applewatch"]
        case .health:      return ["pills.fill","cross.case.fill","heart.fill","bandage.fill","syringe.fill"]
        case .accessories: return ["eyeglasses","sunglasses.fill","backpack.fill","briefcase.fill","wallet.pass.fill","creditcard.fill"]
        case .misc:        return ["cube.box.fill","cart.fill","bag.fill","gift.fill","camera.fill","wrench.fill","scissors"]
        }
    }
}

extension Character {
    var isEmoji: Bool {
        guard let scalar = unicodeScalars.first else { return false }
        return scalar.properties.isEmoji && (scalar.value > 0x238C || unicodeScalars.count > 1)
    }
}

#Preview { AddItemView().environmentObject(DataStore()).environmentObject(HapticsManager()) }
