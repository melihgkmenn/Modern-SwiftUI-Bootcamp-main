//NoteApp.xcdatamodeld
//id: UUID
//title: String
//content: String
//date: Date


import CoreData

class CoreDataManager {
    static let shared = CoreDataManager()

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "NoteApp")
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }()

    var mainContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    func saveContext() {
        if mainContext.hasChanges {
            do {
                try mainContext.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}




import SwiftUI

struct ContentView: View {
    @Environment(\.managedObjectContext) var managedObjectContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Note.date, ascending: false)],
        animation: .default
    ) var notes: FetchedResults<Note>

    var body: some View {
        NavigationView {
            List {
                ForEach(notes) { note in
                    NavigationLink(destination: NoteDetailView(note: note)) {
                        VStack(alignment: .leading) {
                            Text(note.title ?? "Başlıksız Not")
                                .font(.headline)
                            Text(note.date ?? Date(), style: .date)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .onDelete(perform: deleteNote)
            }
            .navigationTitle("Not Defteri")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: NewNoteView()) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }

    private func deleteNote(offsets: IndexSet) {
        withAnimation {
            offsets.map { notes[$0] }.forEach(managedObjectContext.delete)
            CoreDataManager.shared.saveContext()
        }
    }
}





import SwiftUI

struct NewNoteView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.dismiss) var dismiss

    @State private var title: String = ""
    @State private var content: String = ""

    var body: some View {
        Form {
            Section(header: Text("Yeni Not")) {
                TextField("Başlık", text: $title)
                TextEditor(text: $content)
                    .frame(minHeight: 200)
            }
        }
        .navigationTitle("Yeni Not")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Kaydet") {
                    saveNote()
                }
            }
        }
    }

    private func saveNote() {
        let newNote = Note(context: managedObjectContext)
        newNote.id = UUID()
        newNote.title = title
        newNote.content = content
        newNote.date = Date()

        CoreDataManager.shared.saveContext()
        dismiss()
    }
}





import SwiftUI

struct NoteDetailView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.dismiss) var dismiss
    @State private var note: Note

    init(note: Note) {
        _note = State(initialValue: note)
    }

    var body: some some View {
        Form {
            Section(header: Text("Notu Düzenle")) {
                TextField("Başlık", text: Binding<String>(
                    get: { note.title ?? "" },
                    set: { note.title = $0 }
                ))
                TextEditor(text: Binding<String>(
                    get: { note.content ?? "" },
                    set: { note.content = $0 }
                ))
                .frame(minHeight: 200)
            }
        }
        .navigationTitle("Not Detayı")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Kaydet") {
                    CoreDataManager.shared.saveContext()
                    dismiss()
                }
            }
        }
        .onDisappear {
            CoreDataManager.shared.saveContext()
        }
    }
}