import SwiftUI

// MARK: MODEL KATMANI
enum EventType: String, CaseIterable, Identifiable {
    case birthday = "Doğum Günü"
    case meeting = "Toplantı"
    case holiday = "Tatil"
    case sport = "Spor"
    case other = "Diğer"

    var id: String { self.rawValue }
}
struct Event: Identifiable, Hashable {
    let id: UUID = UUID()
    var title: String
    var date: Date
    var type: EventType
    var hasReminder: Bool
}



// MARK: VIEWMODEL KATMANI
class EventViewModel: ObservableObject {
    @Published var events: [Event] = []

    init() {
        loadSampleEvents()
    }

    func addEvent(title: String, date: Date, type: EventType, hasReminder: Bool) {
        let newEvent = Event(title: title, date: date, type: type, hasReminder:hasReminder)
        events.append(newEvent)
    }

    func deleteEvent(event: Event) {
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            events.remove(at: index)
        }
    }
    
    private func loadSampleEvents() {
        self.events = [
            Event(title: "SwiftUI Sunumu", date: Date().addingTimeInterval(86400), type: .meeting, hasReminder: true),
            Event(title: "Sabah Koşusu", date: Date().addingTimeInterval(172800), type: .sport, hasReminder: true),
            Event(title: "Ayşe'nin Doğum Günü", date: Date().addingTimeInterval(300000), type: .birthday, hasReminder: false)
        ]
    }
}


// MARK: VIEW KATMANI

struct EventListView: View {
    @StateObject private var viewModel = EventViewModel()
    @State private var isShowingAddEventSheet = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.events) { event in
                    NavigationLink(value: event) {
                        HStack {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(event.title)
                                    .fontWeight(.semibold)
                                Text(event.type.rawValue)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text(event.date, style: .date)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .navigationTitle("Etkinlikler")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isShowingAddEventSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .navigationDestination(for: Event.self) { event in
                EventDetailView(event: event, viewModel: viewModel)
            }
        }
        .sheet(isPresented: $isShowingAddEventSheet) {
            AddEventView(viewModel: viewModel)
        }
    }
}

// Modal Form
struct AddEventView: View {
    @ObservedObject var viewModel: EventViewModel
    @Environment(\.dismiss) var dismiss
    @State private var title: String = ""
    @State private var date: Date = Date()
    @State private var type: EventType = .other
    @State private var hasReminder: Bool = true
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Etkinlik Detayları")) {
                    TextField("Etkinlik Adı", text: $title)
                    DatePicker("Tarih", selection: $date, displayedComponents: .date)
                    Picker("Tür", selection: $type) {
                        ForEach(EventType.allCases) { eventType in
                            Text(eventType.rawValue).tag(eventType)
                        }
                    }
                }

                Section {
                    Toggle("Hatırlatıcı Olsun mu?", isOn: $hasReminder)
                }
            }
            .navigationTitle("Yeni Etkinlik")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kaydet") {
                        viewModel.addEvent(
                            title: title,
                            date: date,
                            type: type,
                            hasReminder: hasReminder
                        )
                        dismiss()
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}



struct EventDetailView: View {
    let event: Event
    @ObservedObject var viewModel: EventViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        Form {
            Section(header: Text("Etkinlik Bilgileri")) {
                LabeledContent("Başlık", value: event.title)
                LabeledContent("Tarih", value: event.date.formatted(date: .long, time: .omitted))
                LabeledContent("Tür", value: event.type.rawValue)
                LabeledContent("Hatırlatıcı") {
                    Image(systemName: event.hasReminder ? "bell.fill" : "bell.slash.fill")
                        .foregroundColor(event.hasReminder ? .blue : .gray)
                }
            }
            
            Section {
                Button("Bu Etkinliği Sil", role: .destructive) {
                    viewModel.deleteEvent(event: event)
                    dismiss()
            }
        }
        .navigationTitle("Etkinlik Detayı")
        .navigationBarTitleDisplayMode(.inline)
    }
}


// MARK: - PREVIEW
#Preview {
    EventListView()
}