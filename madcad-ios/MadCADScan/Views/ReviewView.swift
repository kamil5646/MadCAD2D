import SwiftUI

private struct ReviewStepDefinition: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let symbolName: String
}

struct ReviewView: View {
    @EnvironmentObject private var store: MadCADScanStore
    @State private var isReferenceExpanded = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let draft = store.measurementDraft {
                        let steps = reviewSteps(for: draft.mode)
                        let currentIndex = min(store.reviewStepIndex, max(steps.count - 1, 0))
                        let currentStep = steps[currentIndex]

                        headerCard(draft)
                        progressCard(steps: steps, currentIndex: currentIndex)
                        currentStepCard(draft: draft, step: currentStep)

                        if currentStep.id == "summary" {
                            completionCard(draft)
                            if let preview = store.reviewPreview {
                                referenceCard(preview)
                            }
                        }

                        navigationRow(steps: steps, currentIndex: currentIndex)
                    } else {
                        ContentUnavailableView("Brak danych pomiaru", systemImage: "exclamationmark.triangle")
                    }
                }
                .padding(20)
            }
            .navigationTitle("Potwierdź pomiar")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(store.reviewStepIndex > 0 ? "Wstecz" : "Start") {
                        if store.reviewStepIndex > 0 {
                            store.goToPreviousReviewStep()
                        } else {
                            store.route = .start
                        }
                    }
                }
            }
        }
    }

    private func headerCard(_ draft: ProductMeasurementDraft) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Label(draft.mode.title, systemImage: draft.mode.symbolName)
                        .font(.headline)
                    Text("Krok 2 z 3: wybierz interpretację pomiaru i potwierdź wymiary")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 12)
                Text("Wizard")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.cyan.opacity(0.14))
                    .clipShape(Capsule())
            }

            TextField("Nazwa projektu", text: $store.projectName)
                .textFieldStyle(.roundedBorder)

            Picker("Użyj jako", selection: modeBinding) {
                ForEach(ProductMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            Text(reviewIntroText(for: draft.mode))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func progressCard(steps: [ReviewStepDefinition], currentIndex: Int) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Etapy pomiaru")
                    .font(.headline)
                Spacer(minLength: 12)
                Text("\(currentIndex + 1) / \(steps.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: Double(currentIndex + 1), total: Double(max(steps.count, 1)))
                .tint(.cyan)

            ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                HStack(spacing: 10) {
                    Image(systemName: index < currentIndex ? "checkmark.circle.fill" : (index == currentIndex ? step.symbolName : "circle"))
                        .foregroundStyle(index <= currentIndex ? .cyan : .secondary)
                        .frame(width: 20)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(step.title)
                            .font(.subheadline.weight(index == currentIndex ? .semibold : .regular))
                        Text(step.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 8)
                }
            }
        }
        .padding(18)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func currentStepCard(draft: ProductMeasurementDraft, step: ReviewStepDefinition) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(step.title)
                        .font(.headline)
                    Text(step.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 12)
                Image(systemName: step.symbolName)
                    .font(.title3)
                    .foregroundStyle(.cyan)
            }

            stepFields(draft: draft, stepID: step.id)
        }
        .padding(18)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    @ViewBuilder
    private func stepFields(draft: ProductMeasurementDraft, stepID: String) -> some View {
        switch stepID {
        case "span":
            measurementSection("Podstawowy wymiar") {
                MeasurementDoubleRow(title: draft.mode == .balcony ? "Długość [mm]" : "Szerokość [mm]", field: numericDoubleBinding(\.widthMm), step: 10)
                MeasurementIntRow(title: "Liczba pól / sekcji", field: numericIntBinding(\.sectionCount), step: 1)
                MeasurementIntRow(title: draft.mode == .gate ? "Liczba przęseł / paneli" : "Liczba paneli", field: numericIntBinding(\.panelCount), step: 1)
                if draft.mode == .gate {
                    MeasurementIntRow(title: "Liczba skrzydeł", field: numericIntBinding(\.gateLeafCount), step: 1)
                }
            }
        case "height":
            measurementSection("Wysokość i przekroje") {
                MeasurementDoubleRow(title: "Wysokość [mm]", field: numericDoubleBinding(\.heightMm), step: 10)
                MeasurementDoubleRow(title: "Profil ramy [mm]", field: numericDoubleBinding(\.frameProfileMm), step: 5)
                MeasurementDoubleRow(title: "Profil wypełnienia [mm]", field: numericDoubleBinding(\.barWidthMm), step: 1)
                Picker("Typ wypełnienia", selection: stringBinding(\.infillPattern)) {
                    Text("Pionowe").tag("vertical")
                    Text("Poziome").tag("horizontal")
                    Text("Siatka").tag("grid")
                    Text("Krzyżowe X").tag("cross")
                }
                .pickerStyle(.segmented)
            }
        case "supports":
            measurementSection("Słupki i podparcie") {
                switch draft.mode {
                case .gate:
                    MeasurementDoubleRow(title: "Prześwit od dołu [mm]", field: numericDoubleBinding(\.groundClearanceMm), step: 5)
                    MeasurementDoubleRow(title: "Długość słupka [mm]", field: numericDoubleBinding(\.postLengthMm), step: 10)
                case .balcony:
                    MeasurementDoubleRow(title: "Szerokość słupka [mm]", field: numericDoubleBinding(\.postWidthMm), step: 5)
                    MeasurementDoubleRow(title: "Profil ramy [mm]", field: numericDoubleBinding(\.frameProfileMm), step: 5)
                case .fence:
                    MeasurementDoubleRow(title: "Szerokość słupka [mm]", field: numericDoubleBinding(\.postWidthMm), step: 5)
                    MeasurementDoubleRow(title: "Długość słupka [mm]", field: numericDoubleBinding(\.postLengthMm), step: 10)
                    MeasurementDoubleRow(title: "Wysokość podmurówki [mm]", field: numericDoubleBinding(\.basePlateHeightMm), step: 5)
                }
            }
        case "mounting":
            measurementSection("Montaż i wypełnienie") {
                switch draft.mode {
                case .gate:
                    Toggle("Rama wewnętrzna", isOn: boolBinding(\.innerFrame))
                    Toggle("Zastrzał ukośny", isOn: boolBinding(\.diagonal))
                    Toggle("Panel górny", isOn: boolBinding(\.topPanel))
                    MeasurementDoubleRow(title: "Rozmiar panelu górnego [mm]", field: numericDoubleBinding(\.topPanelThicknessMm), step: 1)
                    Toggle("Panel dolny", isOn: boolBinding(\.bottomPanel))
                    MeasurementDoubleRow(title: "Rozmiar panelu dolnego [mm]", field: numericDoubleBinding(\.bottomPanelThicknessMm), step: 1)
                case .balcony:
                    Toggle("Panel górny", isOn: boolBinding(\.topPanel))
                    MeasurementDoubleRow(title: "Rozmiar panelu górnego [mm]", field: numericDoubleBinding(\.topPanelThicknessMm), step: 1)
                    Toggle("Panel dolny", isOn: boolBinding(\.bottomPanel))
                    MeasurementDoubleRow(title: "Rozmiar panelu dolnego [mm]", field: numericDoubleBinding(\.bottomPanelThicknessMm), step: 1)
                case .fence:
                    MeasurementDoubleRow(title: "Prześwit od dołu [mm]", field: numericDoubleBinding(\.groundClearanceMm), step: 5)
                    Toggle("Panel górny", isOn: boolBinding(\.topPanel))
                    MeasurementDoubleRow(title: "Rozmiar panelu górnego [mm]", field: numericDoubleBinding(\.topPanelThicknessMm), step: 1)
                    Toggle("Panel dolny", isOn: boolBinding(\.bottomPanel))
                    MeasurementDoubleRow(title: "Rozmiar panelu dolnego [mm]", field: numericDoubleBinding(\.bottomPanelThicknessMm), step: 1)
                }
            }
        case "summary":
            summarySection(draft)
        default:
            EmptyView()
        }
    }

    private func summarySection(_ draft: ProductMeasurementDraft) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Podsumowanie eksportu")
                .font(.headline)

            HStack {
                summaryMetric(title: draft.mode == .balcony ? "Długość" : "Szerokość", value: "\(Int(draft.widthMm.rounded())) mm")
                summaryMetric(title: "Wysokość", value: "\(Int(draft.heightMm.rounded())) mm")
            }

            HStack {
                summaryMetric(title: "Sekcje", value: "\(draft.sectionCount)")
                summaryMetric(title: "Panele", value: "\(draft.panelCount)")
            }

            Text("Eksport zapisze przede wszystkim potwierdzone wymiary produktu. Na desktopie MadCAD wybierzesz, czy tylko zasilić formularz `Stal`, czy od razu wygenerować geometrię.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private func summaryMetric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func completionCard(_ draft: ProductMeasurementDraft) -> some View {
        let issues = reviewIssues(for: draft)
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Status pomiaru")
                    .font(.headline)
                Spacer(minLength: 12)
                Text(issues.isEmpty ? "Gotowe do eksportu" : "Wymaga sprawdzenia")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background((issues.isEmpty ? Color.green : Color.orange).opacity(0.14))
                    .clipShape(Capsule())
            }

            if issues.isEmpty {
                Label("Najważniejsze wymiary są uzupełnione. Możesz przejść do eksportu albo jeszcze je skorygować.", systemImage: "checkmark.circle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(issues, id: \.self) { issue in
                        Label(issue, systemImage: "exclamationmark.triangle")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(18)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func referenceCard(_ preview: ExportPreview) -> some View {
        DisclosureGroup(isExpanded: $isReferenceExpanded) {
            VStack(alignment: .leading, spacing: 12) {
                PlanPreviewCanvas(preview: preview)
                    .frame(height: 260)
                    .background(Color(red: 0.06, green: 0.08, blue: 0.11))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                if let summary = store.reviewSummary {
                    Text("Referencja pomocnicza ze skanu: \(summary.wallCount) ścian i \(summary.openingCount) otworów. Nie jest to główny produkt eksportu.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    Text("To jest tylko techniczna referencja pomocnicza. Eksport opiera się na wymiarach produktu.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 8)
        } label: {
            HStack {
                Text("Pokaż referencję pomocniczą")
                    .font(.headline)
                Spacer(minLength: 8)
                Text("opcjonalne")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func navigationRow(steps: [ReviewStepDefinition], currentIndex: Int) -> some View {
        HStack(spacing: 12) {
            Button("Wstecz") {
                store.goToPreviousReviewStep()
            }
            .buttonStyle(.bordered)
            .disabled(currentIndex == 0)

            if currentIndex < steps.count - 1 {
                Button {
                    store.goToNextReviewStep(total: steps.count)
                } label: {
                    Label("Dalej", systemImage: "arrow.right")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.cyan)
            } else {
                Button {
                    store.openExport()
                } label: {
                    Label("Przejdź do eksportu", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.cyan)
            }
        }
    }

    private var modeBinding: Binding<ProductMode> {
        Binding(
            get: { store.measurementDraft?.mode ?? store.selectedProductMode },
            set: { newMode in
                store.applyProductMode(newMode)
            }
        )
    }

    private func reviewSteps(for mode: ProductMode) -> [ReviewStepDefinition] {
        switch mode {
        case .gate:
            return [
                ReviewStepDefinition(id: "span", title: "Światło", subtitle: "Szerokość, sekcje i skrzydła", symbolName: "ruler"),
                ReviewStepDefinition(id: "height", title: "Wysokość", subtitle: "Wysokość i profile", symbolName: "arrow.up.and.down"),
                ReviewStepDefinition(id: "supports", title: "Podparcie", subtitle: "Prześwit i długość słupka", symbolName: "rectangle.portrait"),
                ReviewStepDefinition(id: "mounting", title: "Montaż", subtitle: "Rama, zastrzał i panele", symbolName: "slider.horizontal.3"),
                ReviewStepDefinition(id: "summary", title: "Podsumowanie", subtitle: "Ostatni przegląd przed eksportem", symbolName: "checkmark.circle")
            ]
        case .balcony:
            return [
                ReviewStepDefinition(id: "span", title: "Długość", subtitle: "Długość i podziały sekcji", symbolName: "ruler"),
                ReviewStepDefinition(id: "height", title: "Wysokość", subtitle: "Wysokość balustrady i profile", symbolName: "arrow.up.and.down"),
                ReviewStepDefinition(id: "supports", title: "Słupki", subtitle: "Szerokość słupka i podparcie", symbolName: "rectangle.portrait"),
                ReviewStepDefinition(id: "mounting", title: "Panele", subtitle: "Wypełnienie i panele", symbolName: "slider.horizontal.3"),
                ReviewStepDefinition(id: "summary", title: "Podsumowanie", subtitle: "Ostatni przegląd przed eksportem", symbolName: "checkmark.circle")
            ]
        case .fence:
            return [
                ReviewStepDefinition(id: "span", title: "Przęsło", subtitle: "Długość i podział sekcji", symbolName: "ruler"),
                ReviewStepDefinition(id: "height", title: "Wysokość", subtitle: "Wysokość i profile", symbolName: "arrow.up.and.down"),
                ReviewStepDefinition(id: "supports", title: "Słupki", subtitle: "Słupki i podmurówka", symbolName: "rectangle.portrait"),
                ReviewStepDefinition(id: "mounting", title: "Montaż", subtitle: "Prześwit i panele", symbolName: "slider.horizontal.3"),
                ReviewStepDefinition(id: "summary", title: "Podsumowanie", subtitle: "Ostatni przegląd przed eksportem", symbolName: "checkmark.circle")
            ]
        }
    }

    private func measurementSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            content()
        }
        .padding(14)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func reviewIntroText(for mode: ProductMode) -> String {
        switch mode {
        case .gate:
            return "To nie jest plan pokoju. Tu krok po kroku potwierdzasz światło, wysokość i parametry montażowe bramy, które trafią do MadCAD jako pomiar produktu."
        case .balcony:
            return "Tu krok po kroku potwierdzasz długość balustrady, wysokość i podziały sekcji. Referencja LiDAR jest tylko pomocą, nie głównym rezultatem."
        case .fence:
            return "Tu krok po kroku potwierdzasz długość odcinka, wysokość, słupki i podmurówkę. Do desktopu trafi zestaw wymiarów pod ogrodzenie."
        }
    }

    private func reviewIssues(for draft: ProductMeasurementDraft) -> [String] {
        var issues: [String] = []
        if draft.widthMm < 400 {
            issues.append(draft.mode == .balcony ? "Długość wygląda podejrzanie mało." : "Szerokość wygląda podejrzanie mało.")
        }
        if draft.heightMm < 400 {
            issues.append("Wysokość wygląda podejrzanie mało.")
        }
        if draft.sectionCount < 1 {
            issues.append("Liczba sekcji musi być większa od zera.")
        }
        switch draft.mode {
        case .gate:
            if draft.gateLeafCount < 1 {
                issues.append("Brama musi mieć co najmniej jedno skrzydło.")
            }
        case .balcony:
            if draft.postWidthMm < 20 {
                issues.append("Szerokość słupka balkonu wymaga sprawdzenia.")
            }
        case .fence:
            if draft.postLengthMm < draft.heightMm {
                issues.append("Długość słupka ogrodzenia jest mniejsza niż wysokość konstrukcji.")
            }
        }
        return issues
    }

    private func numericDoubleBinding(_ keyPath: WritableKeyPath<ProductMeasurementDraft, Double>) -> Binding<Double> {
        Binding(
            get: { store.measurementDraft?[keyPath: keyPath] ?? 0 },
            set: { value in
                store.updateMeasurements { draft in
                    draft[keyPath: keyPath] = value
                }
            }
        )
    }

    private func numericIntBinding(_ keyPath: WritableKeyPath<ProductMeasurementDraft, Int>) -> Binding<Int> {
        Binding(
            get: { store.measurementDraft?[keyPath: keyPath] ?? 0 },
            set: { value in
                store.updateMeasurements { draft in
                    draft[keyPath: keyPath] = value
                }
            }
        )
    }

    private func boolBinding(_ keyPath: WritableKeyPath<ProductMeasurementDraft, Bool>) -> Binding<Bool> {
        Binding(
            get: { store.measurementDraft?[keyPath: keyPath] ?? false },
            set: { value in
                store.updateMeasurements { draft in
                    draft[keyPath: keyPath] = value
                }
            }
        )
    }

    private func stringBinding(_ keyPath: WritableKeyPath<ProductMeasurementDraft, String>) -> Binding<String> {
        Binding(
            get: { store.measurementDraft?[keyPath: keyPath] ?? "vertical" },
            set: { value in
                store.updateMeasurements { draft in
                    draft[keyPath: keyPath] = value
                }
            }
        )
    }
}

private struct MeasurementIntRow: View {
    let title: String
    let field: Binding<Int>
    let step: Int

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
            Spacer(minLength: 12)
            Stepper(value: field, step: step) {
                Text("\(field.wrappedValue)")
                    .font(.system(.body, design: .monospaced))
            }
            .frame(maxWidth: 220, alignment: .trailing)
        }
    }
}

private struct MeasurementDoubleRow: View {
    let title: String
    let field: Binding<Double>
    let step: Double

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
            Spacer(minLength: 12)
            Stepper(value: field, step: step) {
                Text("\(Int(field.wrappedValue.rounded()))")
                    .font(.system(.body, design: .monospaced))
            }
            .frame(maxWidth: 220, alignment: .trailing)
        }
    }
}
