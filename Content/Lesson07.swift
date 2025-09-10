import Foundation

struct Note: Identifiable, Codable {
    var id = UUID()
    var title: String
    var content: String
    var date: Date 
}



import Combine

class NotesViewModel: ObservableObject {
    @Published var notes: [Note] = []
    private let userDefaultsKey = "savedNotes"
    
    init() {
        loadNotes()
    }
    
    func addNote(title: String, content: String) {
        let newNote = Note(title: title, content: content, date: Date())
        notes.append(newNote)
        saveNotes()
    }
    
    func deleteNote(at offsets: IndexSet) {
        notes.remove(atOffsets: offsets)
        saveNotes()
    }
    
    private func saveNotes() {
        let encoder = JSONEncoder()
        if let encodedData = try? encoder.encode(notes) {
            UserDefaults.standard.set(encodedData, forKey: userDefaultsKey)
        }
    }
    
    private func loadNotes() {
        if let savedData = UserDefaults.standard.data(forKey: userDefaultsKey) {
            let decoder = JSONDecoder()
            if let decodedNotes = try? decoder.decode([Note].self, from: savedData) {
                self.notes = decodedNotes
            }
        }
    }
}






import SwiftUI

struct NotesListView: View {
    @StateObject private var viewModel = NotesViewModel()
    @State private var showingAddNoteView = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.notes) { note in
                    NavigationLink(destination: NoteDetailView(note: note)) {
                        VStack(alignment: .leading) {
                            Text(note.title)
                                .font(.headline)
                            Text(note.date, style: .date)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .onDelete(perform: viewModel.deleteNote)
            }
            .navigationTitle("Not Defteri")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddNoteView = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddNoteView) {
                AddNoteView(viewModel: viewModel)
            }
        }
    }
}

struct NotesListView_Previews: PreviewProvider {
    static var previews: some View {
        NotesListView()
    }
}




import SwiftUI

struct AddNoteView: View {
    @ObservedObject var viewModel: NotesViewModel
    @State private var title: String = ""
    @State private var content: String = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Not Bilgileri")) {
                    TextField("Başlık", text: $title)
                    TextEditor(text: $content)
                        .frame(height: 200)
                }
            }
            .navigationTitle("Yeni Not Ekle")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kaydet") {
                        if !title.isEmpty && !content.isEmpty {
                            viewModel.addNote(title: title, content: content)
                            dismiss()
                        }
                    }
                    .disabled(title.isEmpty || content.isEmpty)
                }
            }
        }
    }
}




import SwiftUI

struct NoteDetailView: View {
    let note: Note
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(note.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("Oluşturulma Tarihi: \(note.date.formatted(date: .long, time: .shortened))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Divider()
                
                Text(note.content)
                    .font(.body)
            }
            .padding()
        }
        .navigationTitle("Not Detayı")
        .navigationBarTitleDisplayMode(.inline)
    }
}
