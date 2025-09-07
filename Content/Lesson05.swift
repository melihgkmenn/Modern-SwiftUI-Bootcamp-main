import Foundation
import Combine
import SwiftUI


// MARK: - Model
struct Task: Identifiable, Equatable {
    let id: UUID
    var title: String
    var isCompleted: Bool

    // Initializer
    init(id: UUID = UUID(), title: String, isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
    }
}



// MARK: - ViewModel
class TaskViewModel: ObservableObject {
    @Published var tasks: [Task] = []
    
    init() {
        loadSampleTasks()
    }

    func addTask(title: String) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        
        let newTask = Task(title: trimmedTitle)
        tasks.append(newTask)
    }
    
    func toggleIsCompleted(for task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
        }
    }
    
    func deleteTask(at offsets: IndexSet) {
        tasks.remove(atOffsets: offsets)
    }
    
    private func loadSampleTasks() {
        tasks = [
            Task(title: "MVVM Öğren", isCompleted: true),
            Task(title: "SwiftUI List Kullan"),
            Task(title: "Kaydırarak Silme Ekle")
        ]
    }
}


// MARK: - View
struct TaskView: View {
    @StateObject private var viewModel = TaskViewModel()
    @State private var newTaskTitle: String = ""
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    TextField("Yeni görev ekle...", text: $newTaskTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.leading)
                    Button(action: {
                        viewModel.addTask(title: newTaskTitle)
                        newTaskTitle = ""
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.blue)
                    }
                    .padding(.trailing)
                    .disabled(newTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(.top)
                
                // MARK: Görev Listesi
                List {
                    ForEach(viewModel.tasks) { task in
                        TaskRowView(task: task)
                            .onTapGesture {
                                withAnimation {
                                    viewModel.toggleIsCompleted(for: task)
                                }
                            }
                    }
                    .onDelete(perform: viewModel.deleteTask)
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("Görev Yöneticisi")
        }
    }
}


struct TaskRowView: View {
    let task: Task

    var body: some View {
        HStack {
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(task.isCompleted ? .green : .gray)
            Text(task.title)
                .strikethrough(task.isCompleted, color: .primary)
                .opacity(task.isCompleted ? 0.5 : 1.0)
            Spacer()
        }
        .font(.title3)
        .padding(.vertical, 8)
    }
}


struct TaskView_Previews: PreviewProvider {
    static var previews: some View {
        TaskView()
    }
}