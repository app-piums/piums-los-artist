//
//  ArtistOnboardingView.swift
//  PiumsArtist
//
//  Onboarding 7 pasos — espejo de la versión web del artista.
//  Paso 1: Bienvenida
//  Paso 2: Disciplina creativa
//  Paso 3: Equipo
//  Paso 4: Portfolio & Perfil
//  Paso 5: Primer Servicio
//  Paso 6: Tarifa Base
//  Paso 7: Disponibilidad Semanal
//

import SwiftUI
import Combine

// MARK: - Step enum

enum ArtistOnboardingStep: Int, CaseIterable {
    case welcome = 1, discipline, equipment, portfolio, service, rate, availability
}

// MARK: - Data models

struct DisciplineOption: Identifiable {
    let id: String; let name: String; let subtitle: String; let emoji: String; let systemImage: String
    static let all: [DisciplineOption] = [
        .init(id:"musician",         name:"Músico",               subtitle:"Cantante, Compositor, Banda",    emoji:"🎵", systemImage:"music.microphone"),
        .init(id:"dj",               name:"DJ / Productor",       subtitle:"Electrónica, Beat Maker",        emoji:"🎧", systemImage:"hifispeaker.fill"),
        .init(id:"photographer",     name:"Fotógrafo",            subtitle:"Eventos, Retratos, Producto",    emoji:"📷", systemImage:"camera.fill"),
        .init(id:"filmmaker",        name:"Videógrafo",           subtitle:"Clips, Eventos, Comerciales",    emoji:"🎬", systemImage:"video.fill"),
        .init(id:"graphic-designer", name:"Diseñador Gráfico",    subtitle:"Marca, Flyers, Portadas",        emoji:"🎨", systemImage:"pencil.and.ruler.fill"),
        .init(id:"illustrator",      name:"Ilustrador",           subtitle:"Arte digital, Portadas",         emoji:"✏️", systemImage:"paintbrush.pointed.fill"),
        .init(id:"dancer",           name:"Bailarín / Coreógrafo",subtitle:"Urbano, Clásico, Show",          emoji:"💃", systemImage:"figure.dance"),
        .init(id:"mc",               name:"Animador / MC",        subtitle:"Bodas, Eventos, Conciertos",     emoji:"🎤", systemImage:"person.wave.2.fill"),
        .init(id:"writer",           name:"Escritor / Letrista",  subtitle:"Letras, Guiones, Contenidos",    emoji:"📝", systemImage:"text.quote"),
        .init(id:"tattooist",        name:"Tatuador",             subtitle:"Tattoo, Body Art, Piercing",     emoji:"🖋️", systemImage:"paintbrush.fill"),
        .init(id:"makeup",           name:"Maquillador",          subtitle:"Bodas, Cine, FX, Pasarela",      emoji:"💄", systemImage:"sparkle"),
        .init(id:"painter",          name:"Pintor / Artista",     subtitle:"Lienzo, Mural, Acuarela",        emoji:"🖌️", systemImage:"paintpalette.fill"),
        .init(id:"sculptor",         name:"Escultor",             subtitle:"Cerámica, Madera, Metal",        emoji:"🏺", systemImage:"cube.fill"),
        .init(id:"magician",         name:"Mago / Ilusionista",   subtitle:"Close-up, Shows, Escenario",     emoji:"🪄", systemImage:"sparkles"),
        .init(id:"acrobat",          name:"Acróbata / Circo",     subtitle:"Malabares, Aéreos, Fuego",       emoji:"🎪", systemImage:"figure.gymnastics"),
        .init(id:"other",            name:"Otro",                 subtitle:"Otro talento creativo",          emoji:"⚡", systemImage:"star.fill"),
    ]
    // Category mapping → backend enum
    var category: String {
        let map: [String:String] = [
            "musician":"MUSICO","dj":"DJ","photographer":"FOTOGRAFO","filmmaker":"VIDEOGRAFO",
            "graphic-designer":"DISENADOR","illustrator":"PINTOR","dancer":"BAILARIN","mc":"ANIMADOR",
            "writer":"ESCRITOR","tattooist":"TATUADOR","makeup":"MAQUILLADOR","painter":"PINTOR",
            "sculptor":"ESCULTOR","magician":"MAGO","acrobat":"ACROBATA","other":"OTRO"
        ]
        return map[id] ?? "OTRO"
    }
}

struct WeekDay: Identifiable {
    let id: String; var active: Bool; var startTime: String; var endTime: String
    static let defaults: [WeekDay] = [
        .init(id:"Lunes",     active:false, startTime:"09:00", endTime:"18:00"),
        .init(id:"Martes",    active:false, startTime:"09:00", endTime:"18:00"),
        .init(id:"Miércoles", active:false, startTime:"09:00", endTime:"18:00"),
        .init(id:"Jueves",    active:false, startTime:"09:00", endTime:"18:00"),
        .init(id:"Viernes",   active:false, startTime:"09:00", endTime:"18:00"),
        .init(id:"Sábado",    active:false, startTime:"10:00", endTime:"16:00"),
        .init(id:"Domingo",   active:false, startTime:"10:00", endTime:"16:00"),
    ]
}

// Equipment per discipline (same as web)
private let equipmentByDiscipline: [String: [(section: String, items: [String])]] = [
    "musician": [
        ("Audio", ["Sistema de sonido propio","Micrófono vocal","Micrófono inalámbrico","Mixer / consola","Monitor de escenario"]),
        ("Instrumentos", ["Guitarra eléctrica","Guitarra acústica","Bajo","Teclado / Piano","Batería"]),
        ("Producción", ["Iluminación propia","Efectos de escenario","Laptop + software"])
    ],
    "dj": [
        ("Equipo DJ", ["Controlador DJ","CDJ / Platos","Mixer DJ","Laptop + software","Auriculares profesionales"]),
        ("Audio", ["Sistema de sonido propio","Monitor de escenario","Subwoofer"]),
        ("Efectos", ["Luces LED / PAR","Máquina de humo","Laser","Proyector"])
    ],
    "photographer": [
        ("Cámara", ["Cámara DSLR / Mirrorless","Lentes adicionales","Cámara de respaldo","Drone"]),
        ("Iluminación", ["Flash externo","Softbox","Reflector"]),
        ("Accesorios", ["Trípode","Gimbal","Fondo portátil"])
    ],
    "filmmaker": [
        ("Video", ["Cámara 4K","Cámara DSLR / Mirrorless","Drone","Cámara 360°"]),
        ("Estabilización", ["Gimbal","Trípode","Slider / dolly"]),
        ("Audio/Post", ["Micrófono de cañón","Grabadora de audio","Software de edición"])
    ],
]
private func equipment(for id: String) -> [(section: String, items: [String])] {
    equipmentByDiscipline[id] ?? [
        ("General", ["Computadora / Laptop","Software especializado","Transporte propio"])
    ]
}

// MARK: - ViewModel

@MainActor
final class ArtistOnboardingViewModel: ObservableObject {
    // Navigation
    @Published var step: ArtistOnboardingStep = .welcome
    @Published var isLoading = false
    @Published var errorMessage: String?
    var onFinished: (() -> Void)?

    // Step 2
    @Published var selectedDiscipline: DisciplineOption? = nil
    @Published var searchQuery = ""

    // Step 3
    @Published var selectedEquipment: Set<String> = []

    // Step 4
    @Published var shortBio = ""
    @Published var instagramHandle = ""
    @Published var portfolioUrl = ""

    // Step 5
    @Published var serviceName = ""
    @Published var serviceCategory = ""
    @Published var serviceDescription = ""
    @Published var basePrice = ""

    // Step 6
    @Published var hourlyRateMin: Double = 0
    @Published var hourlyRateMax: Double = 0
    @Published var currency = "GTQ"
    @Published var requiresDeposit = false
    @Published var depositPercentage: Double = 30

    // Step 7
    @Published var weeklyAvailability = WeekDay.defaults

    let totalSteps = 7

    var progressValue: Double { Double(step.rawValue) / Double(totalSteps) }

    var filteredDisciplines: [DisciplineOption] {
        guard !searchQuery.isEmpty else { return DisciplineOption.all }
        return DisciplineOption.all.filter {
            $0.name.localizedCaseInsensitiveContains(searchQuery) ||
            $0.subtitle.localizedCaseInsensitiveContains(searchQuery)
        }
    }

    var canContinueStep2: Bool { selectedDiscipline != nil }
    var canContinueStep5: Bool { !shortBio.trimmingCharacters(in: .whitespaces).isEmpty }
    var canContinueStep6: Bool { !serviceName.trimmingCharacters(in: .whitespaces).isEmpty && !serviceDescription.isEmpty }

    // Navigation
    func next() {
        guard let next = ArtistOnboardingStep(rawValue: step.rawValue + 1) else { return }
        withAnimation(.easeInOut(duration: 0.3)) { step = next }
    }
    func back() {
        guard let prev = ArtistOnboardingStep(rawValue: step.rawValue - 1) else { return }
        withAnimation(.easeInOut(duration: 0.3)) { step = prev }
    }

    func skip() async { await complete(skip: true) }
    func finish() async { await complete(skip: false) }

    private func complete(skip: Bool) async {
        isLoading = true
        errorMessage = nil
        do {
            // 1. Create artist profile
            let category = selectedDiscipline?.category ?? "OTRO"
            let profileBody = CreateArtistProfileBody(
                category: category,
                specialties: [category],
                equipment: Array(selectedEquipment),
                bio: shortBio.isEmpty ? nil : shortBio,
                instagram: instagramHandle.isEmpty ? nil : instagramHandle,
                website: portfolioUrl.isEmpty ? nil : portfolioUrl,
                hourlyRateMin: hourlyRateMin > 0 ? hourlyRateMin : nil,
                hourlyRateMax: hourlyRateMax > 0 ? hourlyRateMax : nil,
                currency: currency,
                requiresDeposit: requiresDeposit,
                depositPercentage: requiresDeposit ? depositPercentage : nil
            )
            let _ = try? await APIService.shared.post(
                endpoint: .createArtistProfile,
                body: profileBody,
                responseType: EmptyResponseDTO.self
            )

            // 2. Save weekly availability (only active days)
            let activeDays = weeklyAvailability.filter { $0.active }
            if !activeDays.isEmpty {
                let slots = activeDays.map { AvailabilitySlot(dayOfWeek: $0.id, startTime: $0.startTime, endTime: $0.endTime) }
                let availBody = SetAvailabilityBody(availability: slots)
                let _ = try? await APIService.shared.post(
                    endpoint: .setArtistAvailability,
                    body: availBody,
                    responseType: EmptyResponseDTO.self
                )
            }

            // 3. Create first service if provided
            if !serviceName.isEmpty && !serviceDescription.isEmpty {
                struct SvcBody: Codable {
                    let name: String; let description: String
                    let category: String?; let priceDecimal: Double
                    let durationMin: Int; let status: String
                }
                let price = Double(basePrice) ?? 0
                let svcBody = SvcBody(name: serviceName, description: serviceDescription,
                                      category: serviceCategory.isEmpty ? nil : serviceCategory,
                                      priceDecimal: price, durationMin: 60, status: "ACTIVE")
                let _ = try? await APIService.shared.post(
                    endpoint: .createService,
                    body: svcBody,
                    responseType: EmptyResponseDTO.self
                )
            }

        }
        // Mark onboarding done regardless of errors
        UserDefaults.standard.set(true, forKey: "hasSeenArtistOnboarding")
        isLoading = false
        onFinished?()
    }
}

// MARK: - DTOs

private struct CreateArtistProfileBody: Codable {
    let category: String; let specialties: [String]; let equipment: [String]
    let bio: String?; let instagram: String?; let website: String?
    let hourlyRateMin: Double?; let hourlyRateMax: Double?; let currency: String
    let requiresDeposit: Bool; let depositPercentage: Double?
}

private struct AvailabilitySlot: Codable {
    let dayOfWeek: String; let startTime: String; let endTime: String
}

private struct SetAvailabilityBody: Codable {
    let availability: [AvailabilitySlot]
}

// MARK: - Root View

struct ArtistOnboardingView: View {
    var onFinish: () -> Void
    @StateObject private var vm = ArtistOnboardingViewModel()

    var body: some View {
        ZStack {
            switch vm.step {
            case .welcome:
                OnbWelcomeStep(vm: vm)
                    .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .leading)))
            case .discipline:
                OnbDisciplineStep(vm: vm)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            case .equipment:
                OnbEquipmentStep(vm: vm)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            case .portfolio:
                OnbPortfolioStep(vm: vm)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            case .service:
                OnbServiceStep(vm: vm)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            case .rate:
                OnbRateStep(vm: vm)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            case .availability:
                OnbAvailabilityStep(vm: vm)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .trailing)))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: vm.step)
        .onAppear { vm.onFinished = onFinish }
    }
}

// MARK: - Shared components

private struct OnbTopBar: View {
    let vm: ArtistOnboardingViewModel
    var body: some View {
        HStack {
            Button(action: vm.back) {
                Image(systemName: "chevron.left").font(.title3.bold())
                    .padding(10).background(Color(.secondarySystemBackground)).clipShape(Circle())
            }
            Spacer()
            Text("Paso \(vm.step.rawValue) de \(vm.totalSteps)")
                .font(.subheadline.weight(.medium)).foregroundStyle(.secondary)
            Spacer()
            Button("Omitir") { Task { await vm.skip() } }
                .font(.subheadline).foregroundStyle(.secondary)
        }
        .padding(.horizontal, 20).padding(.vertical, 14)
    }
}

private struct OnbProgressBar: View {
    let value: Double
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color(.systemGray6))
                Capsule().fill(Color.piumsOrange).frame(width: geo.size.width * value)
                    .animation(.easeInOut(duration: 0.35), value: value)
            }
        }.frame(height: 5)
    }
}

private struct OnbDots: View {
    let current: Int; let total: Int
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { i in
                Capsule()
                    .fill(i == current ? Color.piumsOrange : Color(.systemGray5))
                    .frame(width: i == current ? 22 : 8, height: 8)
                    .animation(.spring(response: 0.4), value: current)
            }
        }
    }
}

private struct OnbContinueBar: View {
    let label: String; let canContinue: Bool; let isLoading: Bool
    let action: () -> Void; let skip: () -> Void
    var body: some View {
        VStack(spacing: 10) {
            Button(action: action) {
                HStack(spacing: 8) {
                    if isLoading { ProgressView().tint(.white).scaleEffect(0.85) }
                    else { Text(label).font(.headline) }
                }
                .foregroundStyle(.white).frame(maxWidth: .infinity).padding(.vertical, 16)
                .background(canContinue ? Color.piumsOrange : Color(.systemGray4))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: canContinue ? Color.piumsOrange.opacity(0.3) : .clear, radius: 8, y: 4)
            }
            .disabled(!canContinue || isLoading)
            .animation(.easeInOut(duration: 0.2), value: canContinue)
            Button("Omitir por ahora", action: skip).font(.subheadline).foregroundStyle(.secondary)
        }
        .padding(.horizontal, 24).padding(.vertical, 16).background(.bar)
    }
}

// MARK: - Step 1: Bienvenida

private struct OnbWelcomeStep: View {
    @ObservedObject var vm: ArtistOnboardingViewModel
    @State private var appeared = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red:0.08,green:0.08,blue:0.12), Color(red:0.12,green:0.10,blue:0.08)],
                           startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
            Circle().fill(Color.piumsOrange.opacity(0.15)).frame(width:300,height:300)
                .blur(radius:70).offset(x:-80,y:-120)
            Circle().fill(Color.piumsAccent.opacity(0.10)).frame(width:220,height:220)
                .blur(radius:55).offset(x:110,y:30)

            VStack(spacing: 0) {
                HStack {
                    Text("Piuma").font(.system(size:22,weight:.heavy,design:.rounded))
                        .foregroundStyle(LinearGradient(colors:[.piumsOrange,.piumsAccent],startPoint:.leading,endPoint:.trailing))
                    Spacer()
                    Button("Omitir") { Task { await vm.skip() } }
                        .font(.subheadline).foregroundColor(.white.opacity(0.55))
                }
                .padding(.horizontal,28).padding(.top,20)

                Spacer()

                VStack(alignment:.leading, spacing:0) {
                    Text("Paso 1 de \(vm.totalSteps)")
                        .font(.caption.bold()).tracking(2).foregroundColor(.piumsOrange).padding(.bottom,12)

                    Text("Bienvenido a\n**tu panel de artista**")
                        .font(.system(size:34,weight:.heavy)).foregroundColor(.white).lineSpacing(2).padding(.bottom,16)

                    Text("Configura tu perfil en minutos y empieza a recibir reservas de clientes.")
                        .font(.body).foregroundColor(.white.opacity(0.65)).lineSpacing(4).padding(.bottom,32)

                    // Stats
                    HStack(spacing:20) {
                        wStat("10K+","Artistas"); Divider().frame(height:30).background(Color.white.opacity(0.2))
                        wStat("50K+","Reservas"); Divider().frame(height:30).background(Color.white.opacity(0.2))
                        wStat("5⭐","Promedio")
                    }.padding(.bottom,32)

                    // Steps preview
                    VStack(alignment:.leading, spacing:8) {
                        ForEach(["⚡ Elige tu superpoder creativo","🛠 Define tu equipo","👤 Agrega tu bio y portafolio","💼 Crea tu primer servicio","💰 Establece tus tarifas","📅 Configura disponibilidad"], id:\.self) { item in
                            HStack(spacing:8) {
                                Text(item).font(.caption).foregroundColor(.white.opacity(0.7))
                            }
                        }
                    }.padding(.bottom,32)

                    Button { vm.next() } label: {
                        HStack(spacing:8) {
                            Text("Comenzar").fontWeight(.semibold)
                            Image(systemName:"arrow.right").font(.subheadline.bold())
                        }
                        .foregroundColor(.white).padding(.horizontal,28).padding(.vertical,14)
                        .background(Color.piumsOrange).clipShape(Capsule())
                        .shadow(color:Color.piumsOrange.opacity(0.4),radius:12,y:6)
                    }
                }
                .padding(.horizontal,28)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)

                Spacer()

                OnbDots(current:0, total:vm.totalSteps).padding(.bottom,48)
            }
        }
        .onAppear { withAnimation(.easeOut(duration:0.7).delay(0.1)) { appeared = true } }
    }

    private func wStat(_ val: String, _ lbl: String) -> some View {
        VStack(spacing:2) {
            Text(val).font(.headline.bold()).foregroundColor(.white)
            Text(lbl).font(.caption2).foregroundColor(.white.opacity(0.55))
        }
    }
}

// MARK: - Step 2: Disciplina

private struct OnbDisciplineStep: View {
    @ObservedObject var vm: ArtistOnboardingViewModel
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(spacing:0) {
            OnbTopBar(vm:vm)
            OnbProgressBar(value: vm.progressValue).padding(.horizontal,24).padding(.top,4).padding(.bottom,20)

            VStack(alignment:.leading, spacing:6) {
                Text("¿Cuál es tu superpoder creativo?").font(.title2.bold())
                Text("Selecciona el rol que mejor te describe. Personalizaremos tu perfil y tus servicios.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            .frame(maxWidth:.infinity, alignment:.leading).padding(.horizontal,24).padding(.bottom,12)

            // Search
            HStack(spacing:8) {
                Image(systemName:"magnifyingglass").foregroundColor(.secondary)
                TextField("Buscar disciplina…", text: $vm.searchQuery)
                    .textInputAutocapitalization(.never).autocorrectionDisabled()
            }
            .padding(.horizontal,14).padding(.vertical,10)
            .background(Color(.systemGray6)).cornerRadius(10)
            .padding(.horizontal,24).padding(.bottom,12)

            ScrollView {
                LazyVGrid(columns:columns, spacing:12) {
                    ForEach(vm.filteredDisciplines) { disc in
                        DisciplineCard(disc:disc, isSelected: vm.selectedDiscipline?.id == disc.id) {
                            vm.selectedDiscipline = disc
                        }
                    }
                }
                .padding(.horizontal,24).padding(.bottom,100)
            }
            .scrollIndicators(.hidden)
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .safeAreaInset(edge:.bottom) {
            OnbContinueBar(label:"Continuar →", canContinue:vm.canContinueStep2, isLoading:false,
                           action:vm.next, skip:{ Task { await vm.skip() } })
        }
    }
}

private struct DisciplineCard: View {
    let disc: DisciplineOption; let isSelected: Bool; let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Icon row
                HStack(alignment: .top) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isSelected ? Color.piumsOrange : Color.piumsOrange.opacity(0.1))
                            .frame(width: 48, height: 48)
                        VStack(spacing: 1) {
                            Text(disc.emoji)
                                .font(.system(size: 22))
                        }
                    }
                    Spacer()
                    if isSelected {
                        ZStack {
                            Circle().fill(Color.piumsOrange).frame(width: 22, height: 22)
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.bottom, 10)

                Text(disc.name)
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                Text(disc.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .padding(.top, 2)

                // SF Symbol badge at bottom
                HStack(spacing: 4) {
                    Image(systemName: disc.systemImage)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(isSelected ? Color.piumsOrange : .secondary)
                }
                .padding(.top, 6)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.piumsOrange.opacity(0.08) : Color(.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color.piumsOrange : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.18), value: isSelected)
    }
}

// MARK: - Step 3: Equipo

private struct OnbEquipmentStep: View {
    @ObservedObject var vm: ArtistOnboardingViewModel

    var body: some View {
        VStack(spacing:0) {
            OnbTopBar(vm:vm)
            OnbProgressBar(value:vm.progressValue).padding(.horizontal,24).padding(.top,4).padding(.bottom,20)

            VStack(alignment:.leading, spacing:6) {
                Text("¿Con qué equipo cuentas?").font(.title2.bold())
                Text("Los clientes verán qué llevas tú. Selecciona lo que tienes disponible.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            .frame(maxWidth:.infinity, alignment:.leading).padding(.horizontal,24).padding(.bottom,16)

            let sections = equipment(for: vm.selectedDiscipline?.id ?? "other")

            ScrollView {
                VStack(spacing:16) {
                    ForEach(sections, id:\.section) { sec in
                        VStack(alignment:.leading, spacing:10) {
                            Text(sec.section).font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
                            FlexWrap(spacing:8) {
                                ForEach(sec.items, id:\.self) { item in
                                    let active = vm.selectedEquipment.contains(item)
                                    Button {
                                        withAnimation(.easeInOut(duration:0.15)) {
                                            if active { vm.selectedEquipment.remove(item) }
                                            else { vm.selectedEquipment.insert(item) }
                                        }
                                    } label: {
                                        HStack(spacing:6) {
                                            if active { Image(systemName:"checkmark").font(.caption2.bold()) }
                                            Text(item).font(.subheadline.weight(.medium))
                                        }
                                        .foregroundStyle(active ? .white : .primary)
                                        .padding(.horizontal,14).padding(.vertical,8)
                                        .background(Capsule().fill(active ? Color.piumsOrange : Color(.secondarySystemBackground)))
                                        .overlay(Capsule().stroke(active ? Color.clear : Color(.systemGray4), lineWidth:1))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(14).background(Color(.secondarySystemBackground).opacity(0.6)).cornerRadius(14)
                    }
                    Color.clear.frame(height:80)
                }
                .padding(.horizontal,24)
            }
            .scrollIndicators(.hidden)
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .safeAreaInset(edge:.bottom) {
            OnbContinueBar(label:"Continuar →", canContinue:true, isLoading:false,
                           action:vm.next, skip:{ Task { await vm.skip() } })
        }
    }
}

// MARK: - Step 4: Portfolio & Perfil

private struct OnbPortfolioStep: View {
    @ObservedObject var vm: ArtistOnboardingViewModel
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing:0) {
            OnbTopBar(vm:vm)
            OnbProgressBar(value:vm.progressValue).padding(.horizontal,24).padding(.top,4).padding(.bottom,20)

            ScrollView {
                VStack(alignment:.leading, spacing:20) {
                    VStack(alignment:.leading, spacing:6) {
                        Text("Tu portafolio y perfil").font(.title2.bold())
                        Text("Esta información aparece en tu perfil público.")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }

                    // Bio
                    VStack(alignment:.leading, spacing:6) {
                        HStack {
                            Text("BIOGRAFÍA CORTA").font(.caption.weight(.semibold)).foregroundStyle(.secondary).tracking(0.5)
                            Spacer()
                            Text("\(vm.shortBio.count)/300").font(.caption2).foregroundStyle(.secondary)
                        }
                        TextEditor(text:$vm.shortBio)
                            .frame(height:90)
                            .padding(10)
                            .background(Color(.systemGray6)).cornerRadius(10)
                            .focused($focused)
                            .onChange(of:vm.shortBio) { _, new in if new.count > 300 { vm.shortBio = String(new.prefix(300)) } }
                    }

                    // Instagram
                    VStack(alignment:.leading, spacing:6) {
                        Text("INSTAGRAM").font(.caption.weight(.semibold)).foregroundStyle(.secondary).tracking(0.5)
                        HStack {
                            Text("@").foregroundStyle(.secondary)
                            TextField("tu_usuario", text:$vm.instagramHandle)
                                .textInputAutocapitalization(.never).autocorrectionDisabled()
                        }
                        .padding(.horizontal,14).padding(.vertical,12)
                        .background(Color(.systemGray6)).cornerRadius(10)
                    }

                    // Portfolio URL
                    VStack(alignment:.leading, spacing:6) {
                        Text("PORTAFOLIO / WEB").font(.caption.weight(.semibold)).foregroundStyle(.secondary).tracking(0.5)
                        TextField("https://tu-portfolio.com", text:$vm.portfolioUrl)
                            .keyboardType(.URL).textInputAutocapitalization(.never).autocorrectionDisabled()
                            .padding(.horizontal,14).padding(.vertical,12)
                            .background(Color(.systemGray6)).cornerRadius(10)
                    }

                    Color.clear.frame(height:80)
                }
                .padding(.horizontal,24)
            }
            .scrollIndicators(.hidden)
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .safeAreaInset(edge:.bottom) {
            OnbContinueBar(label:"Continuar →", canContinue:vm.canContinueStep5, isLoading:false,
                           action:vm.next, skip:{ Task { await vm.skip() } })
        }
    }
}

// MARK: - Step 5: Primer Servicio

private let serviceCategories = [
    "Música en Vivo","DJ & Electrónica","Fotografía","Video","Diseño Gráfico",
    "Producción Musical","Danza","Tatuaje","Magia","Arte Visual","Escritura","Maquillaje","Otro"
]

private struct OnbServiceStep: View {
    @ObservedObject var vm: ArtistOnboardingViewModel

    var body: some View {
        VStack(spacing:0) {
            OnbTopBar(vm:vm)
            OnbProgressBar(value:vm.progressValue).padding(.horizontal,24).padding(.top,4).padding(.bottom,20)

            ScrollView {
                VStack(alignment:.leading, spacing:20) {
                    VStack(alignment:.leading, spacing:6) {
                        Text("Tu primer servicio").font(.title2.bold())
                        Text("Crea el servicio principal que ofrecerás a tus clientes.")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }

                    // Service name
                    labeledField("NOMBRE DEL SERVICIO") {
                        TextField("Ej: Sesión fotográfica para bodas", text:$vm.serviceName)
                            .padding(.horizontal,14).padding(.vertical,12)
                            .background(Color(.systemGray6)).cornerRadius(10)
                    }

                    // Category picker
                    labeledField("CATEGORÍA") {
                        Picker("Categoría", selection:$vm.serviceCategory) {
                            Text("Seleccionar…").tag("")
                            ForEach(serviceCategories, id:\.self) { cat in
                                Text(cat).tag(cat)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(.horizontal,14).padding(.vertical,8)
                        .background(Color(.systemGray6)).cornerRadius(10)
                        .frame(maxWidth:.infinity, alignment:.leading)
                    }

                    // Description
                    labeledField("DESCRIPCIÓN") {
                        TextEditor(text:$vm.serviceDescription)
                            .frame(height:80).padding(10)
                            .background(Color(.systemGray6)).cornerRadius(10)
                    }

                    // Price
                    labeledField("PRECIO BASE (Q)") {
                        TextField("0.00", text:$vm.basePrice)
                            .keyboardType(.decimalPad)
                            .padding(.horizontal,14).padding(.vertical,12)
                            .background(Color(.systemGray6)).cornerRadius(10)
                    }

                    Color.clear.frame(height:80)
                }
                .padding(.horizontal,24)
            }
            .scrollIndicators(.hidden)
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .safeAreaInset(edge:.bottom) {
            OnbContinueBar(label:"Continuar →", canContinue:vm.canContinueStep6, isLoading:false,
                           action:vm.next, skip:{ Task { await vm.skip() } })
        }
    }

    @ViewBuilder
    private func labeledField<Content:View>(_ title:String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment:.leading, spacing:6) {
            Text(title).font(.caption.weight(.semibold)).foregroundStyle(.secondary).tracking(0.5)
            content()
        }
    }
}

// MARK: - Step 6: Tarifa Base

private struct OnbRateStep: View {
    @ObservedObject var vm: ArtistOnboardingViewModel

    var body: some View {
        VStack(spacing:0) {
            OnbTopBar(vm:vm)
            OnbProgressBar(value:vm.progressValue).padding(.horizontal,24).padding(.top,4).padding(.bottom,20)

            ScrollView {
                VStack(alignment:.leading, spacing:20) {
                    VStack(alignment:.leading, spacing:6) {
                        Text("Tu tarifa base").font(.title2.bold())
                        Text("Establece tu rango de tarifas. Podrás ajustar los precios desde el dashboard.")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }

                    // Currency
                    VStack(alignment:.leading, spacing:6) {
                        Text("MONEDA").font(.caption.weight(.semibold)).foregroundStyle(.secondary).tracking(0.5)
                        Picker("Moneda", selection:$vm.currency) {
                            Text("GTQ — Quetzal").tag("GTQ")
                            Text("USD — Dólar").tag("USD")
                            Text("MXN — Peso MX").tag("MXN")
                        }
                        .pickerStyle(.segmented)
                    }

                    // Rate range
                    HStack(spacing:16) {
                        VStack(alignment:.leading, spacing:6) {
                            Text("MÍNIMO").font(.caption.weight(.semibold)).foregroundStyle(.secondary).tracking(0.5)
                            HStack {
                                Text(vm.currency).font(.caption).foregroundStyle(.secondary)
                                TextField("0", value:$vm.hourlyRateMin, format:.number)
                                    .keyboardType(.numberPad)
                            }
                            .padding(.horizontal,12).padding(.vertical,12)
                            .background(Color(.systemGray6)).cornerRadius(10)
                        }
                        VStack(alignment:.leading, spacing:6) {
                            Text("MÁXIMO").font(.caption.weight(.semibold)).foregroundStyle(.secondary).tracking(0.5)
                            HStack {
                                Text(vm.currency).font(.caption).foregroundStyle(.secondary)
                                TextField("0", value:$vm.hourlyRateMax, format:.number)
                                    .keyboardType(.numberPad)
                            }
                            .padding(.horizontal,12).padding(.vertical,12)
                            .background(Color(.systemGray6)).cornerRadius(10)
                        }
                    }

                    // Deposit toggle
                    VStack(alignment:.leading, spacing:12) {
                        Toggle(isOn:$vm.requiresDeposit) {
                            VStack(alignment:.leading, spacing:2) {
                                Text("Requerir anticipo").font(.subheadline.weight(.semibold))
                                Text("Los clientes deberán pagar un porcentaje para confirmar la reserva.")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .tint(.piumsOrange)

                        if vm.requiresDeposit {
                            VStack(alignment:.leading, spacing:6) {
                                HStack {
                                    Text("PORCENTAJE DE ANTICIPO").font(.caption.weight(.semibold)).foregroundStyle(.secondary).tracking(0.5)
                                    Spacer()
                                    Text("\(Int(vm.depositPercentage))%").font(.caption.bold()).foregroundColor(.piumsOrange)
                                }
                                Slider(value:$vm.depositPercentage, in:10...50, step:5).tint(.piumsOrange)
                            }
                            .transition(.move(edge:.top).combined(with:.opacity))
                        }
                    }
                    .padding(16).background(Color(.secondarySystemBackground)).cornerRadius(14)

                    Color.clear.frame(height:80)
                }
                .padding(.horizontal,24)
            }
            .scrollIndicators(.hidden)
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .safeAreaInset(edge:.bottom) {
            OnbContinueBar(label:"Continuar →", canContinue:true, isLoading:false,
                           action:vm.next, skip:{ Task { await vm.skip() } })
        }
    }
}

// MARK: - Step 7: Disponibilidad

private struct OnbAvailabilityStep: View {
    @ObservedObject var vm: ArtistOnboardingViewModel

    var body: some View {
        VStack(spacing:0) {
            OnbTopBar(vm:vm)
            OnbProgressBar(value:vm.progressValue).padding(.horizontal,24).padding(.top,4).padding(.bottom,20)

            VStack(alignment:.leading, spacing:6) {
                Text("Tu disponibilidad semanal").font(.title2.bold())
                Text("Activa los días en que estás disponible. Los clientes lo verán al reservarte.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            .frame(maxWidth:.infinity, alignment:.leading).padding(.horizontal,24).padding(.bottom,16)

            ScrollView {
                VStack(spacing:8) {
                    ForEach($vm.weeklyAvailability) { $day in
                        AvailabilityRow(day:$day)
                    }
                    Color.clear.frame(height:80)
                }
                .padding(.horizontal,24)
            }
            .scrollIndicators(.hidden)
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .safeAreaInset(edge:.bottom) {
            VStack(spacing:10) {
                Button { Task { await vm.finish() } } label: {
                    HStack(spacing:8) {
                        if vm.isLoading { ProgressView().tint(.white).scaleEffect(0.85) }
                        else { Text("Ir a la app →").font(.headline) }
                    }
                    .foregroundStyle(.white).frame(maxWidth:.infinity).padding(.vertical,16)
                    .background(Color.piumsOrange).clipShape(RoundedRectangle(cornerRadius:16))
                    .shadow(color:Color.piumsOrange.opacity(0.3), radius:8, y:4)
                }
                .disabled(vm.isLoading)
                Button("Configurar después") { Task { await vm.skip() } }
                    .font(.subheadline).foregroundStyle(.secondary)
                Text("Podrás ajustar tu disponibilidad en cualquier momento desde la Agenda.")
                    .font(.caption).foregroundStyle(.tertiary).multilineTextAlignment(.center)
                OnbDots(current:6, total:vm.totalSteps).padding(.top,4)
            }
            .padding(.horizontal,24).padding(.vertical,16).background(.bar)
        }
    }
}

private struct AvailabilityRow: View {
    @Binding var day: WeekDay
    var body: some View {
        VStack(spacing:8) {
            HStack {
                Toggle(isOn:$day.active) {
                    Text(day.id).font(.subheadline.weight(.semibold))
                }
                .tint(.piumsOrange)
            }
            if day.active {
                HStack(spacing:12) {
                    timeField("Inicio", time:$day.startTime)
                    Text("—").foregroundStyle(.secondary)
                    timeField("Fin", time:$day.endTime)
                }
                .transition(.move(edge:.top).combined(with:.opacity))
            }
        }
        .padding(14).background(Color(.secondarySystemBackground)).cornerRadius(12)
        .animation(.easeInOut(duration:0.2), value:day.active)
    }

    @ViewBuilder
    private func timeField(_ label:String, time:Binding<String>) -> some View {
        VStack(alignment:.leading, spacing:3) {
            Text(label).font(.caption2).foregroundStyle(.secondary)
            TextField("09:00", text:time)
                .font(.subheadline.weight(.medium)).multilineTextAlignment(.center)
                .frame(width:70).padding(.vertical,8).padding(.horizontal,6)
                .background(Color(.systemGray6)).cornerRadius(8)
                .keyboardType(.numbersAndPunctuation)
        }
    }
}

// MARK: - FlexWrap Layout

private struct FlexWrap: Layout {
    var spacing: CGFloat = 8
    func sizeThatFits(proposal:ProposedViewSize, subviews:Subviews, cache:inout ()) -> CGSize {
        let w = proposal.width ?? 0
        var x:CGFloat=0, y:CGFloat=0, rh:CGFloat=0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x+s.width > w && x>0 { y+=rh+spacing; x=0; rh=0 }
            rh=max(rh,s.height); x+=s.width+spacing
        }
        return CGSize(width:w, height:y+rh)
    }
    func placeSubviews(in bounds:CGRect, proposal:ProposedViewSize, subviews:Subviews, cache:inout ()) {
        var x=bounds.minX, y=bounds.minY, rh:CGFloat=0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x+s.width > bounds.maxX && x>bounds.minX { y+=rh+spacing; x=bounds.minX; rh=0 }
            v.place(at:CGPoint(x:x,y:y), proposal:ProposedViewSize(width:s.width, height:s.height))
            rh=max(rh,s.height); x+=s.width+spacing
        }
    }
}

// MARK: - Prefs model (kept for UserDefaults storage)

struct ArtistOnboardingPrefs: Codable {
    var categories: [String]; var tags: [String:[String]]
    static let storageKey = "piums_artist_onboarding_prefs"
    func save() {
        if let data = try? JSONEncoder().encode(self) { UserDefaults.standard.set(data, forKey:Self.storageKey) }
    }
}

#Preview { ArtistOnboardingView { } }
