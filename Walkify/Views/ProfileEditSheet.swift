//
//  ProfileEditSheet.swift
//  Walkify
//
//  Created by Yiğit on 25.02.2026.
//

import SwiftUI
import SwiftData
import PhotosUI
import UIKit

struct ProfileEditSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    var profile: UserProfile?
    let onDismiss: () -> Void

    @State private var name: String = ""
    @State private var email: String = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var avatarImageData: Data?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(spacing: 20) {
                        // Profil fotoğrafı alanı
                        PhotosPicker(
                            selection: $selectedPhotoItem,
                            matching: .images,
                            photoLibrary: .shared()
                        ) {
                            ZStack(alignment: .bottomTrailing) {
                                if let data = avatarImageData, let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 120, height: 120)
                                        .clipShape(Circle())
                                } else {
                                    Circle()
                                        .fill(AppTheme.cardBackgroundSecondary(for: colorScheme))
                                        .frame(width: 120, height: 120)
                                        .overlay(
                                            Image(systemName: "camera.fill")
                                                .font(.system(size: 36))
                                                .foregroundStyle(AppTheme.accentOrange)
                                        )
                                }
                                Circle()
                                    .fill(AppTheme.accentOrange)
                                    .frame(width: 36, height: 36)
                                    .overlay(Image(systemName: "pencil").font(.system(size: 16, weight: .semibold)).foregroundStyle(.white))
                                    .overlay(Circle().stroke(AppTheme.background(for: colorScheme), lineWidth: 2))
                                    .offset(x: 4, y: 4)
                            }
                        }
                        .onChange(of: selectedPhotoItem) { _, newItem in
                            Task {
                                await loadPhoto(from: newItem)
                            }
                        }

                        if avatarImageData != nil {
                            Button(role: .destructive) {
                                avatarImageData = nil
                                selectedPhotoItem = nil
                                profile?.avatarImageData = nil
                                try? modelContext.save()
                            } label: {
                                Label("Fotoğrafı Kaldır", systemImage: "trash")
                                    .font(.system(size: 15))
                            }
                            .listRowBackground(AppTheme.cardBackground(for: colorScheme))
                        }

                        Text("Dokunarak fotoğraf seç veya değiştir")
                            .font(.system(size: 13))
                            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .listRowBackground(AppTheme.background(for: colorScheme))
                    .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
                }

                Section {
                    TextField("Ad Soyad", text: $name)
                        .listRowBackground(AppTheme.cardBackground(for: colorScheme))
                    TextField("E-posta", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .listRowBackground(AppTheme.cardBackground(for: colorScheme))
                } header: {
                    Text("Kişisel Bilgiler")
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.background(for: colorScheme))
            .onAppear {
                name = profile?.name ?? ""
                email = profile?.email ?? ""
                avatarImageData = profile?.avatarImageData
            }
            .navigationTitle("Profili Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        onDismiss()
                    }
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kaydet") {
                        saveProfile()
                        onDismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.accentOrange)
                }
            }
            .toolbarBackground(AppTheme.background(for: colorScheme), for: .navigationBar)
        }
    }

    private func loadPhoto(from item: PhotosPickerItem?) async {
        guard let item else { return }
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                let compressed = compressImageForAvatar(data)
                await MainActor.run {
                    avatarImageData = compressed
                }
            }
        } catch {
            #if DEBUG
            print("Profile photo load error: \(error)")
            #endif
        }
    }

    private func compressImageForAvatar(_ data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let maxSide: CGFloat = 400
        let scale = min(maxSide / image.size.width, maxSide / image.size.height, 1)
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        return resized.jpegData(compressionQuality: 0.75)
    }

    private func saveProfile() {
        profile?.name = name
        profile?.email = email
        profile?.avatarImageData = avatarImageData
        try? modelContext.save()
    }
}
