//
//  VerificacionView.swift
//  PiumsArtist
//
//  Verificación de identidad del artista.
//  Flujo: seleccionar tipo de doc → datos personales → fotos (anverso, reverso, selfie)
//  Upload: POST /api/users/documents/upload?folder=front|back|selfie  (multipart, sin auth)
//  Guardar: PATCH /auth/profile  (con auth)
//

import SwiftUI
import PhotosUI
import Combine

// MARK: - ViewModel

@MainActor
final class VerificacionViewModel: ObservableObject {

    // MARK: Document Type

    enum DocumentType: String, CaseIterable {
        case dpi          = "DPI"
        case passport     = "PASSPORT"
        case residenceCard = "RESIDENCE_CARD"

        var displayName: String {
            switch self {
            case .dpi:           return "DPI"
            case .passport:      return "Pasaporte"
            case .residenceCard: return "Cédula de Residencia"
            }
        }
    }

    // MARK: Published state

    @Published var documentType: DocumentType = .dpi
    @Published var documentNumber = ""
    @Published var ciudad = ""
    @Published var birthDate: Date = {
        Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
    }()

    // PhotosPicker items
    @Published var frontPickerItem:  PhotosPickerItem?
    @Published var backPickerItem:   PhotosPickerItem?
    @Published var selfiePickerItem: PhotosPickerItem?

    // Loaded images (for preview)
    @Published var frontImage:  UIImage?
    @Published var backImage:   UIImage?
    @Published var selfieImage: UIImage?

    // Cloudinary URLs after upload
    @Published var frontUrl:  String?
    @Published var backUrl:   String?
    @Published var selfieUrl: String?

    // Upload spinners
    @Published var isUploadingFront  = false
    @Published var isUploadingBack   = false
    @Published var isUploadingSelfie = false

    @Published var isSaving      = false
    @Published var errorMessage: String?
    @Published var isComplete    = false

    // MARK: Validation

    var canSave: Bool {
        !documentNumber.trimmingCharacters(in: .whitespaces).isEmpty &&
        !ciudad.trimmingCharacters(in: .whitespaces).isEmpty &&
        frontUrl  != nil &&
        selfieUrl != nil
    }

    // MARK: Picker loaders

    func loadFrontImage() async {
        guard let item = frontPickerItem,
              let data  = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        frontImage = image
        await uploadFront(image: image)
    }

    func loadBackImage() async {
        guard let item = backPickerItem,
              let data  = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        backImage = image
        await uploadBack(image: image)
    }

    func loadSelfieImage() async {
        guard let item = selfiePickerItem,
              let data  = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        selfieImage = image
        await uploadSelfie(image: image)
    }

    // MARK: Private upload helper

    private func uploadImage(imageData: Data, folder: String) async -> String? {
        let urlString = APIConfig.currentURL + "/users/documents/upload?folder=\(folder)"
        guard let url = URL(string: urlString) else { return nil }

        let boundary = UUID().uuidString
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("multipart/form-data; boundary=\(boundary)",
                     forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"file\"; filename=\"document.jpg\"\r\n")
        body.appendString("Content-Type: image/jpeg\r\n\r\n")
        body.append(imageData)
        body.appendString("\r\n--\(boundary)--\r\n")
        req.httpBody = body

        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            let result = try JSONDecoder().decode(DocumentUploadResponse.self, from: data)
            return result.url
        } catch {
            return nil
        }
    }

    func uploadFront(image: UIImage) async {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        isUploadingFront = true
        frontUrl = await uploadImage(imageData: data, folder: "front")
        isUploadingFront = false
        if frontUrl == nil { errorMessage = "Error al subir el anverso. Intenta de nuevo." }
    }

    func uploadBack(image: UIImage) async {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        isUploadingBack = true
        backUrl = await uploadImage(imageData: data, folder: "back")
        isUploadingBack = false
        if backUrl == nil { errorMessage = "Error al subir el reverso. Intenta de nuevo." }
    }

    func uploadSelfie(image: UIImage) async {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        isUploadingSelfie = true
        selfieUrl = await uploadImage(imageData: data, folder: "selfie")
        isUploadingSelfie = false
        if selfieUrl == nil { errorMessage = "Error al subir la selfie. Intenta de nuevo." }
    }

    // MARK: Save

    func save() async {
        guard canSave else {
            errorMessage = "Completa todos los campos y sube las fotos requeridas."
            return
        }
        isSaving = true
        errorMessage = nil

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let birthStr = formatter.string(from: birthDate)

        struct PatchBody: Codable {
            let ciudad: String
            let birthDate: String
            let documentType: String
            let documentNumber: String
            let documentFrontUrl: String
            let documentBackUrl: String?
            let documentSelfieUrl: String
        }

        guard let safeFront = frontUrl, let safeSelfie = selfieUrl else {
            errorMessage = "Faltan fotos requeridas. Sube el anverso y la selfie."
            isSaving = false
            return
        }

        let body = PatchBody(
            ciudad:          ciudad.trimmingCharacters(in: .whitespaces),
            birthDate:       birthStr,
            documentType:    documentType.rawValue,
            documentNumber:  documentNumber.trimmingCharacters(in: .whitespaces),
            documentFrontUrl:  safeFront,
            documentBackUrl:   backUrl,
            documentSelfieUrl: safeSelfie
        )

        do {
            let _ = try await APIService.shared.patch(
                endpoint: .authProfile,
                body: body,
                responseType: EmptyResponseDTO.self
            )
            isComplete = true
            AuthService.shared.needsVerification = false
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}

// MARK: - Data helper

private extension Data {
    mutating func appendString(_ string: String) {
        if let d = string.data(using: .utf8) { append(d) }
    }
}

// MARK: - Main View

struct VerificacionView: View {
    @StateObject private var vm = VerificacionViewModel()
    @Environment(\.dismiss) private var dismiss
    /// Callback que se ejecuta al completar con éxito la verificación.
    var onComplete: (() -> Void)? = nil

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    documentTypeSection
                    personalInfoSection
                    photosSection
                    if let err = vm.errorMessage { errorBanner(err) }
                    saveButton
                }
                .padding(16)
                .padding(.bottom, 40)
            }
            .background(Color(.secondarySystemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Verificación de Identidad")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Después") { dismiss() }
                        .foregroundColor(.secondary)
                }
            }
            .onChange(of: vm.isComplete) { complete in
                if complete {
                    onComplete?()
                    dismiss()
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.piumsOrange.opacity(0.12))
                    .frame(width: 80, height: 80)
                Image(systemName: "shield.checkered")
                    .font(.system(size: 36))
                    .foregroundColor(.piumsOrange)
            }
            Text("Verifica tu identidad")
                .font(.title3.weight(.bold))
            Text("Para garantizar la seguridad de la plataforma necesitamos verificar tu identidad con un documento oficial vigente.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    // MARK: - Document Type

    private var documentTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Tipo de Documento", systemImage: "doc.badge.clock")
                .font(.headline.weight(.semibold))

            HStack(spacing: 10) {
                ForEach(VerificacionViewModel.DocumentType.allCases, id: \.self) { type in
                    Button { vm.documentType = type } label: {
                        Text(type.displayName)
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(vm.documentType == type ? .white : .primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(
                                vm.documentType == type
                                ? Color.piumsOrange
                                : Color(.systemGray5)
                            )
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    // MARK: - Personal Info

    private var personalInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Información Personal", systemImage: "person.text.rectangle")
                .font(.headline.weight(.semibold))

            field(label: "Número de documento", placeholder: "Ej: 1234 56789 0101") {
                TextField("", text: $vm.documentNumber)
                    .keyboardType(.numbersAndPunctuation)
            }

            field(label: "Ciudad de residencia", placeholder: "Ej: Guatemala City") {
                TextField("", text: $vm.ciudad)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("FECHA DE NACIMIENTO")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
                    .tracking(0.5)
                DatePicker(
                    "",
                    selection: $vm.birthDate,
                    in: ...Calendar.current.date(byAdding: .year, value: -18, to: Date())!,
                    displayedComponents: .date
                )
                .labelsHidden()
                .datePickerStyle(.compact)
                .tint(.piumsOrange)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    private func field<F: View>(label: String, placeholder: String, @ViewBuilder content: () -> F) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
                .tracking(0.5)
            content()
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(10)
        }
    }

    // MARK: - Photos

    private var photosSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Fotografías del Documento", systemImage: "camera.fill")
                .font(.headline.weight(.semibold))

            Text("Asegúrate de que las fotos sean nítidas y el texto legible. Usa un fondo liso y buena iluminación.")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                PhotoPickerTile(
                    label: "Anverso",
                    subtitle: "Frente",
                    icon: "doc.text.fill",
                    image: vm.frontImage,
                    isUploading: vm.isUploadingFront,
                    isUploaded: vm.frontUrl != nil,
                    isRequired: true,
                    pickerItem: $vm.frontPickerItem
                )
                .onChange(of: vm.frontPickerItem) { _ in Task { await vm.loadFrontImage() } }

                PhotoPickerTile(
                    label: "Reverso",
                    subtitle: "Trasera",
                    icon: "doc.fill",
                    image: vm.backImage,
                    isUploading: vm.isUploadingBack,
                    isUploaded: vm.backUrl != nil,
                    isRequired: false,
                    pickerItem: $vm.backPickerItem
                )
                .onChange(of: vm.backPickerItem) { _ in Task { await vm.loadBackImage() } }

                PhotoPickerTile(
                    label: "Selfie",
                    subtitle: "Con el doc.",
                    icon: "person.fill.viewfinder",
                    image: vm.selfieImage,
                    isUploading: vm.isUploadingSelfie,
                    isUploaded: vm.selfieUrl != nil,
                    isRequired: true,
                    pickerItem: $vm.selfiePickerItem
                )
                .onChange(of: vm.selfiePickerItem) { _ in Task { await vm.loadSelfieImage() } }
            }

            HStack(spacing: 4) {
                Image(systemName: "asterisk").font(.caption2).foregroundColor(.piumsError)
                Text("Requerido").font(.caption2).foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    // MARK: - Error Banner

    private func errorBanner(_ msg: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.piumsError)
            Text(msg)
                .font(.subheadline)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.piumsError.opacity(0.10))
        .cornerRadius(12)
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button {
            Task { await vm.save() }
        } label: {
            HStack(spacing: 8) {
                if vm.isSaving {
                    ProgressView().tint(.white).scaleEffect(0.9)
                }
                Text(vm.isSaving ? "Enviando..." : "Enviar Verificación")
                    .font(.body.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(vm.canSave ? Color.piumsOrange : Color.piumsOrange.opacity(0.45))
            .foregroundColor(.white)
            .cornerRadius(14)
        }
        .disabled(!vm.canSave || vm.isSaving)
    }
}

// MARK: - PhotoPickerTile

struct PhotoPickerTile: View {
    let label:      String
    let subtitle:   String
    let icon:       String
    let image:      UIImage?
    let isUploading: Bool
    let isUploaded:  Bool
    let isRequired:  Bool
    @Binding var pickerItem: PhotosPickerItem?

    var body: some View {
        PhotosPicker(selection: $pickerItem,
                     matching: .images,
                     photoLibrary: .shared()) {
            ZStack(alignment: .topTrailing) {
                // Tile background
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .frame(height: 110)
                    .overlay {
                        if let uiImage = image {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity, maxHeight: 110)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            VStack(spacing: 6) {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                                Text(label)
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(.primary)
                                Text(subtitle)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                if isRequired {
                                    Image(systemName: "asterisk")
                                        .font(.caption2)
                                        .foregroundColor(.piumsError)
                                }
                            }
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isUploaded ? Color.piumsSuccess.opacity(0.5) :
                                (isRequired ? Color.piumsOrange.opacity(0.3) : Color.clear),
                                lineWidth: 1.5
                            )
                    )

                // Spinner or checkmark badge
                if isUploading {
                    ProgressView()
                        .scaleEffect(0.75)
                        .padding(5)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .padding(6)
                } else if isUploaded {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.piumsSuccess)
                        .font(.system(size: 18))
                        .background(Circle().fill(Color(.systemBackground)).padding(2))
                        .padding(6)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VerificacionView()
}
