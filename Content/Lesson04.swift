import Foundation

struct TodoItem: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var description: String
    var isCompleted: Bool = false
}


import Foundation
import SwiftUI

class TodoListViewModel: ObservableObject {
    
    @Published var items: [TodoItem] = []
    
    init() {
        loadInitialData()
    }
    
    func loadInitialData() {
        items = [
            TodoItem(title: "SwiftUI Öğren", description: "Listeler ve Navigasyon konularını tekrar et.", isCompleted: false),
            TodoItem(title: "Projeyi Tamamla", description: "MasterListApp ödevini bitir.", isCompleted: false),
            TodoItem(title: "Spor Yap", description: "1 saatlik antrenman yap.", isCompleted: true),
            TodoItem(title: "Alışveriş", description: "Süt, ekmek, yumurta al.", isCompleted: false),
            TodoItem(title: "Kitap Oku", description: "En az 30 sayfa kitap oku.", isCompleted: true),
            TodoItem(title: "E-postaları Kontrol Et", description: "Gelen kutusunu temizle.", isCompleted: false),
            TodoItem(title: "Bitkileri Sula", description: "Salondaki çiçeklere su ver.", isCompleted: true),
            TodoItem(title: "Faturaları Öde", description: "Elektrik ve su faturasını öde.", isCompleted: false),
            TodoItem(title: "Akşam Yemeği Planla", description: "Haftalık yemek listesi hazırla.", isCompleted: true),
            TodoItem(title: "Arabayı Yıkat", description: "Hafta sonu için arabayı temizlet.", isCompleted: false)
        ]
    }
    
    func deleteItem(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
    }
    
    func addItem(title: String, description: String) {
        let newItem = TodoItem(title: title, description: description)
        items.insert(newItem, at: 0)
    }
    
    func toggleCompletion(for item: TodoItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].isCompleted.toggle()
        }
    }
    
    var uncompletedItems: [TodoItem] {
        items.filter { !$0.isCompleted }
    }
    
    var completedItems: [TodoItem] {
        items.filter { $0.isCompleted }
    }
}





import SwiftUI

struct DetailView: View {
    let item: TodoItem
    
    private let sfSymbols: [String] = [
        "star.fill", "heart.fill", "flag.fill", "bell.fill", "tag.fill",
        "bolt.fill", "camera.fill", "mic.fill", "cart.fill", "flame.fill"
    ]
    @State private var randomSymbol: String
    
    init(item: TodoItem) {
        self.item = item
        _randomSymbol = State(initialValue: sfSymbols.randomElement() ?? "questionmark.circle.fill")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(item.title)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(item.description)
                .font(.body)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Image(systemName: randomSymbol)
                .font(.system(size: 100))
                .foregroundColor(.accentColor)
                .frame(maxWidth: .infinity, alignment: .center)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Detay")
        .navigationBarTitleDisplayMode(.inline)
    }
}






import SwiftUI

struct AddItemView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: TodoListViewModel
    @State private var title: String = ""
    @State private var description: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Yeni Görev Bilgileri")) {
                    TextField("Başlık", text: $title)
                    TextField("Açıklama", text: $description)
                }
            }
            .navigationTitle("Yeni Öğe Ekle")
            .navigationBarItems(
                leading: Button("İptal") {
                    dismiss()
                },
                trailing: Button("Kaydet") {
                    if !title.isEmpty {
                        viewModel.addItem(title: title, description: description)
                        dismiss()
                    }
                }
                .disabled(title.isEmpty)
            )
        }
    }
}






import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = TodoListViewModel()
    @State private var isAddingItem = false
    @State private var themeColor: Color = .blue
    
    private let colors: [Color] = [.blue, .green, .orange, .red, .purple, .pink, .teal]

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Tamamlanacaklar (\(viewModel.uncompletedItems.count))")) {
                    ForEach(viewModel.uncompletedItems) { item in
                        NavigationLink(destination: DetailView(item: item)) {
                            listItemView(item)
                        }
                    }
                    .onDelete(perform: deleteUncompleted)
                }
                
                Section(header: Text("Tamamlananlar (\(viewModel.completedItems.count))")) {
                    ForEach(viewModel.completedItems) { item in
                        NavigationLink(destination: DetailView(item: item)) {
                            listItemView(item)
                        }
                    }
                    .onDelete(perform: deleteCompleted)
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("MasterListApp")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isAddingItem = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear {
                themeColor = colors.randomElement() ?? .blue
            }
            .accentColor(themeColor)
            .sheet(isPresented: $isAddingItem) {
                AddItemView(viewModel: viewModel)
            }
        }
    }
    
    @ViewBuilder
    private func listItemView(_ item: TodoItem) -> some View {
        HStack {
            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(item.isCompleted ? .green : .gray)
                .onTapGesture {
                    withAnimation {
                        viewModel.toggleCompletion(for: item)
                    }
                }
            
            VStack(alignment: .leading) {
                Text(item.title)
                    .fontWeight(.semibold)
                    .strikethrough(item.isCompleted, color: .primary)
                Text(item.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .strikethrough(item.isCompleted, color: .secondary)
            }
        }
    }
    
    private func deleteUncompleted(at offsets: IndexSet) {
        let itemsToDelete = offsets.map { viewModel.uncompletedItems[$0] }
        let indicesInMainArray = itemsToDelete.compactMap { item in
            viewModel.items.firstIndex(where: { $0.id == item.id })
        }
        viewModel.deleteItem(at: IndexSet(indicesInMainArray))
    }
    
    private func deleteCompleted(at offsets: IndexSet) {
        let itemsToDelete = offsets.map { viewModel.completedItems[$0] }
        let indicesInMainArray = itemsToDelete.compactMap { item in
            viewModel.items.firstIndex(where: { $0.id == item.id })
        }
        viewModel.deleteItem(at: IndexSet(indicesInMainArray))
    }
}



struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}