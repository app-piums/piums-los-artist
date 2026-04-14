//
//  ArtistOnboardingView.swift
//  PiumsArtist
//
//  Onboarding de 3 pasos para artistas, mismo flujo que la app cliente.
//  Paso 1: Bienvenida  |  Paso 2: Especialidad  |  Paso 3: Afinar tags
//

import SwiftUI

// MARK: - Step enum

enum ArtistOnboardingStep { case welcome, specialty, refine }

// MARK: - ViewModel

@Observable
@MainActor
final class ArtistOnboardingViewModel {
    var step: ArtistOnboardingStep = .welcome
    var selectedCategories: Set<String> = []
    var selectedTags: [String: Set<String>] = [:]
    var isFinishing = false
    var onFinished: (() -> Void)?

    // Category helpers
    func toggleCategory(_ id: String) {
        if selectedCategories.contains(id) { selectedCategories.remove(id) }
        else { selectedCategories.insert(id) }
    }
    func isSelected(_ id: String) -> Bool { selectedCategories.contains(id) }
    var canContinueFromSpecialty: Bool { !selectedCategories.isEmpty }

    // Tag helpers
    func toggleTag(catId: String, tag: String) {
        var set = selectedTags[catId] ?? []
        if set.contains(tag) { set.remove(tag) } else { set.insert(tag) }
        selectedTags[catId] = set
    }
    func tagCount(catId: String) -> Int { selectedTags[catId]?.count ?? 0 }

    var categoriesToRefine: [ArtistCategory] {
        let ids = selectedCategories.isEmpty ? ArtistCategory.all.map(\.id) : Array(selectedCategories)
        return ArtistCategory.all.filter { ids.contains($0.id) }
    }

    // Navigation
    func goToSpecialty() { withAnimation(.easeInOut(duration: 0.3)) { step = .specialty } }
    func goToRefine()    { withAnimation(.easeInOut(duration: 0.3)) { step = .refine    } }
    func goBack() {
        withAnimation(.easeInOut(duration: 0.3)) {
            switch step {
            case .refine:    step = .specialty
            case .specialty: step = .welcome
            case .welcome:   break
            }
        }
    }

    func finish() async { await complete(skip: false) }
    func skip()   async { await complete(skip: true)  }

    private func complete(skip: Bool) async {
        isFinishing = true
        defer { isFinishing = false }
        if !skip {
            let prefs = ArtistOnboardingPrefs(
                categories: Array(selectedCategories),
                tags: selectedTags.mapValues { Array($0) }
            )
            prefs.save()
        }
        UserDefaults.standard.set(true, forKey: "hasSeenArtistOnboarding")
        onFinished?()
    }
}

// MARK: - Root container

struct ArtistOnboardingView: View {
    var onFinish: () -> Void
    @State private var vm = ArtistOnboardingViewModel()

    var body: some View {
        ZStack {
            switch vm.step {
            case .welcome:
                ArtistOnboardingWelcome(vm: vm)
                    .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .leading)))
            case .specialty:
                ArtistOnboardingSpecialty(vm: vm)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            case .refine:
                ArtistOnboardingRefine(vm: vm)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .trailing)))
            }
        }
        .animation(.easeInOut(duration: 0.35), value: vm.step)
        .onAppear { vm.onFinished = onFinish }
    }
}

// MARK: - Step 1: Bienvenida

private struct ArtistOnboardingWelcome: View {
    @Bindable var vm: ArtistOnboardingViewModel
    @State private var animateIn = false

    var body: some View {
        ZStack {
            // Fondo gradiente oscuro artístico (igual que LoginView)
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.08, blue: 0.12),
                    Color(red: 0.12, green: 0.10, blue: 0.08)
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Auras de color
            Circle().fill(Color.piumsOrange.opacity(0.15)).frame(width: 300, height: 300)
                .blur(radius: 70).offset(x: -80, y: -120)
            Circle().fill(Color.piumsAccent.opacity(0.10)).frame(width: 220, height: 220)
                .blur(radius: 55).offset(x: 110, y: 30)

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Text("Piuma")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(LinearGradient(colors: [.piumsOrange, .piumsAccent], startPoint: .leading, endPoint: .trailing))
                    Spacer()
                    Button("Omitir") { Task { await vm.skip() } }
                        .font(.subheadline).foregroundColor(.white.opacity(0.6))
                }
                .padding(.horizontal, 28).padding(.top, 20)

                Spacer()

                // Hero content (blanco)
                VStack(alignment: .leading, spacing: 0) {
                    Text("Paso 1 de 3")
                        .font(.caption.bold()).tracking(2)
                        .foregroundColor(Color.piumsOrange)
                        .padding(.bottom, 12)

                    Text("Bienvenido a\n**tu panel de artista**")
                        .font(.system(size: 34, weight: .heavy))
                        .foregroundColor(.white)
                        .lineSpacing(2)
                        .padding(.bottom, 16)

                    Text("Gestiona tu carrera creativa, reservas y clientes desde un solo lugar. Vamos a configurar tu perfil.")
                        .font(.body).foregroundColor(.white.opacity(0.65)).lineSpacing(4)
                        .padding(.bottom, 36)

                    // Stats row
                    HStack(spacing: 20) {
                        onboardingStat(value: "10K+", label: "Artistas")
                        Divider().frame(height: 30).background(Color.white.opacity(0.2))
                        onboardingStat(value: "50K+", label: "Reservas")
                        Divider().frame(height: 30).background(Color.white.opacity(0.2))
                        onboardingStat(value: "5⭐", label: "Promedio")
                    }
                    .padding(.bottom, 36)

                    HStack(spacing: 16) {
                        Button {
                            withAnimation { vm.goToSpecialty() }
                        } label: {
                            HStack(spacing: 8) {
                                Text("Comenzar").fontWeight(.semibold)
                                Image(systemName: "arrow.right").font(.subheadline.bold())
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 28).padding(.vertical, 14)
                            .background(Color.piumsOrange)
                            .clipShape(Capsule())
                            .shadow(color: Color.piumsOrange.opacity(0.4), radius: 12, y: 6)
                        }

                        Button("Omitir") { Task { await vm.skip() } }
                            .font(.subheadline).foregroundColor(.white.opacity(0.55))
                    }
                }
                .padding(.horizontal, 28)
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 20)

                Spacer()

                // Feature card floating
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(LinearGradient(colors: [Color.piumsOrange, Color.piumsAccent], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 52, height: 52)
                        Image(systemName: "music.microphone").font(.title3).foregroundColor(.white)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Panel de Artista Pro").font(.subheadline.bold()).foregroundColor(.white)
                        Text("Gestiona todo desde aquí").font(.caption).foregroundColor(.white.opacity(0.6))
                        HStack(spacing: 3) {
                            Image(systemName: "checkmark.seal.fill").font(.caption2).foregroundColor(.piumsOrange)
                            Text("Verificado").font(.caption2).foregroundColor(.piumsOrange)
                        }
                    }
                    Spacer()
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.08)))
                .padding(.horizontal, 28)
                .padding(.bottom, 12)

                ArtistOnboardingDots(current: 0, total: 3).padding(.bottom, 48)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.7).delay(0.15)) { animateIn = true }
        }
    }

    private func onboardingStat(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.headline.bold()).foregroundColor(.white)
            Text(label).font(.caption2).foregroundColor(.white.opacity(0.55))
        }
    }
}

// MARK: - Step 2: Especialidad

private struct ArtistOnboardingSpecialty: View {
    @Bindable var vm: ArtistOnboardingViewModel
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(spacing: 0) {
            ArtistOnboardingTopBar(step: "Paso 2 de 3", onBack: { vm.goBack() }, onSkip: { Task { await vm.skip() } })

            ArtistProgressBar(value: 0.66)
                .padding(.horizontal, 24).padding(.top, 4).padding(.bottom, 20)

            VStack(alignment: .leading, spacing: 6) {
                Text("¿Cuál es tu especialidad?").font(.title2.bold())
                Text("Selecciona las disciplinas que ofreces.\nEsto ayuda a los clientes a encontrarte.")
                    .font(.subheadline).foregroundStyle(.secondary).lineSpacing(3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24).padding(.bottom, 20)

            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(ArtistCategory.all) { cat in
                        ArtistCategoryCard(category: cat, isSelected: vm.isSelected(cat.id)) {
                            vm.toggleCategory(cat.id)
                        }
                    }
                }
                .padding(.horizontal, 24).padding(.bottom, 100)
            }
            .scrollIndicators(.hidden)
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 10) {
                Button { vm.goToRefine() } label: {
                    Text("Continuar →").font(.headline).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(vm.canContinueFromSpecialty ? Color.piumsOrange : Color(.systemGray4))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: vm.canContinueFromSpecialty ? Color.piumsOrange.opacity(0.3) : .clear, radius: 8, y: 4)
                }
                .disabled(!vm.canContinueFromSpecialty)
                .animation(.easeInOut(duration: 0.2), value: vm.canContinueFromSpecialty)

                Button("Omitir por ahora") { Task { await vm.skip() } }
                    .font(.subheadline).foregroundStyle(.secondary)

                ArtistOnboardingDots(current: 1, total: 3).padding(.top, 4)
            }
            .padding(.horizontal, 24).padding(.vertical, 16).background(.bar)
        }
    }
}

// MARK: - Step 3: Afinar

private struct ArtistOnboardingRefine: View {
    @Bindable var vm: ArtistOnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            ArtistOnboardingTopBar(step: "Paso 3 de 3", onBack: { vm.goBack() }, onSkip: { Task { await vm.skip() } })

            ArtistProgressBar(value: 1.0)
                .padding(.horizontal, 24).padding(.top, 4).padding(.bottom, 20)

            VStack(alignment: .leading, spacing: 6) {
                Text("Afina tu oferta").font(.title2.bold())
                Text("Elige los estilos y servicios específicos\nque defines tu trabajo.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24).padding(.bottom, 16)

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(vm.categoriesToRefine) { cat in
                        if let sub = ArtistSubcategory.all[cat.id] {
                            ArtistSubcategorySection(
                                category: cat, subcategory: sub,
                                selectedTags: vm.selectedTags[cat.id] ?? [],
                                tagCount: vm.tagCount(catId: cat.id)
                            ) { tag in vm.toggleTag(catId: cat.id, tag: tag) }
                        }
                    }
                    Color.clear.frame(height: 80)
                }
                .padding(.horizontal, 24)
            }
            .scrollIndicators(.hidden)
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 10) {
                Button { Task { await vm.finish() } } label: {
                    HStack(spacing: 8) {
                        if vm.isFinishing {
                            ProgressView().tint(.white).scaleEffect(0.85)
                        } else {
                            Text("Ir a la app →").font(.headline)
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                    .background(Color.piumsOrange)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Color.piumsOrange.opacity(0.3), radius: 8, y: 4)
                }
                .disabled(vm.isFinishing)

                Button("Omitir por ahora") { Task { await vm.skip() } }
                    .font(.subheadline).foregroundStyle(.secondary)

                Text("Puedes actualizar tu especialidad en cualquier momento desde Configuración.")
                    .font(.caption).foregroundStyle(.tertiary).multilineTextAlignment(.center)

                ArtistOnboardingDots(current: 2, total: 3).padding(.top, 2)
            }
            .padding(.horizontal, 24).padding(.vertical, 16).background(.bar)
        }
    }
}

// MARK: - Shared components

private struct ArtistOnboardingDots: View {
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

private struct ArtistProgressBar: View {
    let value: Double
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color(.systemGray6))
                Capsule().fill(Color.piumsOrange)
                    .frame(width: geo.size.width * value)
                    .animation(.easeInOut(duration: 0.4), value: value)
            }
        }.frame(height: 5)
    }
}

private struct ArtistOnboardingTopBar: View {
    let step: String; let onBack: () -> Void; let onSkip: () -> Void
    var body: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left").font(.title3.bold()).foregroundStyle(.primary)
                    .padding(10).background(Color(.secondarySystemBackground)).clipShape(Circle())
            }
            Spacer()
            Text(step).font(.subheadline.weight(.medium)).foregroundStyle(.secondary)
            Spacer()
            Button("Omitir", action: onSkip).font(.subheadline).foregroundStyle(.secondary)
        }
        .padding(.horizontal, 20).padding(.vertical, 14)
    }
}

private struct ArtistCategoryCard: View {
    let category: ArtistCategory; let isSelected: Bool; let onTap: () -> Void
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isSelected ? Color.piumsOrange : Color(.secondarySystemBackground))
                            .frame(width: 40, height: 40)
                        Image(systemName: category.systemImage).font(.system(size: 18))
                            .foregroundStyle(isSelected ? .white : .secondary)
                    }
                    Spacer()
                    if isSelected {
                        ZStack {
                            Circle().fill(Color.piumsOrange).frame(width: 22, height: 22)
                            Image(systemName: "checkmark").font(.system(size: 11, weight: .bold)).foregroundStyle(.white)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.bottom, 10)
                Text(category.label).font(.subheadline.bold()).foregroundStyle(.primary).lineLimit(2)
                Text(category.subtitle).font(.caption).foregroundStyle(.secondary).lineLimit(2).padding(.top, 2)
            }
            .padding(14).frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.piumsOrange.opacity(0.08) : Color(.secondarySystemBackground))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(isSelected ? Color.piumsOrange : Color.clear, lineWidth: 2))
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.18), value: isSelected)
    }
}

private struct ArtistSubcategorySection: View {
    let category: ArtistCategory; let subcategory: ArtistSubcategory
    let selectedTags: Set<String>; let tagCount: Int
    let onToggle: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8).fill(Color.piumsOrange.opacity(0.12)).frame(width: 34, height: 34)
                        Image(systemName: category.systemImage).font(.system(size: 16)).foregroundStyle(Color.piumsOrange)
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text(category.label).font(.caption).foregroundStyle(.secondary)
                        Text(subcategory.sectionLabel).font(.subheadline.bold())
                    }
                }
                Spacer()
                if tagCount > 0 {
                    Text("\(tagCount)").font(.caption.bold()).foregroundStyle(.white)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Color.piumsOrange).clipShape(Capsule())
                        .transition(.scale.combined(with: .opacity))
                }
            }
            ArtistFlowLayout(spacing: 8) {
                ForEach(subcategory.tags, id: \.self) { tag in
                    let active = selectedTags.contains(tag)
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) { onToggle(tag) }
                    } label: {
                        Text(tag).font(.subheadline.weight(.medium))
                            .foregroundStyle(active ? .white : .primary)
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(Capsule().fill(active ? Color.piumsOrange : Color(.secondarySystemBackground)))
                            .overlay(Capsule().stroke(active ? Color.clear : Color(.systemGray4), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground).opacity(0.5))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(.systemGray5), lineWidth: 1))
        )
        .animation(.easeInOut(duration: 0.18), value: tagCount)
    }
}

// MARK: - FlowLayout

private struct ArtistFlowLayout: Layout {
    var spacing: CGFloat = 8
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > width && x > 0 { y += rowH + spacing; x = 0; rowH = 0 }
            rowH = max(rowH, size.height); x += size.width + spacing
        }
        return CGSize(width: width, height: y + rowH)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowH: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX { y += rowH + spacing; x = bounds.minX; rowH = 0 }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            rowH = max(rowH, size.height); x += size.width + spacing
        }
    }
}

// MARK: - Models

struct ArtistCategory: Identifiable, Hashable {
    let id: String; let label: String; let subtitle: String; let systemImage: String
}

struct ArtistSubcategory {
    let sectionLabel: String; let tags: [String]
}

struct ArtistOnboardingPrefs: Codable {
    var categories: [String]
    var tags: [String: [String]]
    static let storageKey = "piums_artist_onboarding_prefs"
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }
}

extension ArtistCategory {
    static let all: [ArtistCategory] = [
        .init(id: "live-music",       label: "Música en Vivo",          subtitle: "Bandas, solistas, acústico",          systemImage: "music.microphone"),
        .init(id: "dj",               label: "DJs & Electrónica",       subtitle: "Fiestas, clubs, bodas",               systemImage: "hifispeaker.fill"),
        .init(id: "photography",      label: "Fotografía",              subtitle: "Eventos, retratos, bodas",            systemImage: "camera.fill"),
        .init(id: "video",            label: "Video & Contenido",       subtitle: "Clips, documentales, redes",          systemImage: "video.fill"),
        .init(id: "graphic-design",   label: "Diseño & Branding",       subtitle: "Flyers, logos, portadas",             systemImage: "pencil.and.ruler.fill"),
        .init(id: "music-production", label: "Producción Musical",      subtitle: "Beats, mezcla, grabación",            systemImage: "waveform"),
        .init(id: "dance",            label: "Danza & Performance",     subtitle: "Urbano, clásico, shows",              systemImage: "figure.dance"),
        .init(id: "tattoo",           label: "Tatuaje & Body Art",      subtitle: "Tattoo, piercing, body paint",        systemImage: "paintbrush.pointed.fill"),
        .init(id: "magic",            label: "Magia & Entretenimiento", subtitle: "Ilusionistas, malabaristas, circo",   systemImage: "sparkles"),
        .init(id: "visual-art",       label: "Arte Visual",             subtitle: "Pintura, ilustración, escultura",     systemImage: "paintpalette.fill"),
        .init(id: "writing",          label: "Escritura & Letras",      subtitle: "Letristas, guionistas, contenidos",   systemImage: "text.quote"),
        .init(id: "makeup",           label: "Maquillaje & Estilismo",  subtitle: "Bodas, cine, teatro, pasarela",       systemImage: "sparkle"),
    ]
}

extension ArtistSubcategory {
    static let all: [String: ArtistSubcategory] = [
        "live-music":       .init(sectionLabel: "Estilo Musical",        tags: ["Banda de Rock", "Jazz & Blues", "Pop Acústico", "Cantautor", "Clásica", "Folklore"]),
        "dj":               .init(sectionLabel: "Géneros & Ocasiones",   tags: ["House & Tech", "Reggaeton", "Pop & Comercial", "Hip-Hop", "DJ Bodas", "Festival"]),
        "photography":      .init(sectionLabel: "Especialidad",          tags: ["Eventos", "Retratos", "Editorial", "Bodas", "Producto", "Street"]),
        "video":            .init(sectionLabel: "Tipo de Video",         tags: ["Clips Musicales", "Bodas", "Redes Sociales", "Documental", "Comercial", "Cortometraje"]),
        "graphic-design":   .init(sectionLabel: "Servicios",             tags: ["Logo & Identidad", "Flyers", "Portadas de Álbum", "Redes Sociales", "Merch", "Cartelería"]),
        "music-production": .init(sectionLabel: "Servicios de Estudio",  tags: ["Beat Making", "Mezcla & Mastering", "Grabación", "Composición", "Arreglos", "Jingle"]),
        "dance":            .init(sectionLabel: "Estilos",               tags: ["Urbano & Hip-Hop", "Ballet", "Contemporáneo", "Salsa", "Folklore", "Show"]),
        "tattoo":           .init(sectionLabel: "Estilos de Tattoo",     tags: ["Realismo", "Geométrico", "Minimalista", "Neo-Tradicional", "Line Art", "Acuarela"]),
        "magic":            .init(sectionLabel: "Tipo de Show",          tags: ["Magia de Cerca", "Gran Ilusionismo", "Malabares", "Acrobacia", "Circo", "Fuego"]),
        "visual-art":       .init(sectionLabel: "Tipo de Arte",          tags: ["Pintura al Óleo", "Acuarela", "Ilustración Digital", "Mural", "Escultura", "Arte Urbano"]),
        "writing":          .init(sectionLabel: "Especialidad",          tags: ["Letras de Canción", "Guiones", "Copywriting", "Poesía", "Contenidos Web", "Narrativa"]),
        "makeup":           .init(sectionLabel: "Especialidad",          tags: ["Bodas", "Cine & Teatro", "Efectos FX", "Pasarela", "Caracterización", "Nail Art"]),
    ]
}

#Preview { ArtistOnboardingView { } }
