App Group Ekleyin:
Proje ayarlarında Signing & Capabilities sekmesine gidin.
+ Capability butonuna tıklayıp App Groups'u seçin.
+ butonuna basarak yeni bir grup oluşturun. Genellikle group.com.sirketadiniz.projeadiniz formatında olur (Örn: group.com.QuickTask).
Widget Extension Ekleyin:
File > New > Target... menüsünden Widget Extension'ı seçin.
Oluşturduğunuz Widget Extension'ın Signing & Capabilities sekmesine gidin ve ana uygulamada oluşturduğunuz aynı App Group'u buraya da ekleyin.



//
//  TaskModel.swift
//  QuickTask
//
//  Created by Melih Gökmen on 20.10.2025.
//

import Foundation
import SwiftData

@Model
class TaskItem {
    @Attribute(.unique) var id: UUID
    var title: String
    var isCompleted: Bool
    var createdAt: Date

    init(title: String) {
        self.id = UUID()
        self.title = title
        self.isCompleted = false
        self.createdAt = .now
    }
}



//
//  SharedDataManager.swift
//  QuickTask
//
//  Created by Melih Gökmen on 20.10.2025.
//

import Foundation
import SwiftData

class SharedDataManager {
    static let shared = SharedDataManager()

    let container: ModelContainer

    private init() {
        let appGroupID = "group.com.QuickTask"
        guard let fileContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            fatalError("App Group container bulunamadı.")
        }

        let storeURL = fileContainer.appendingPathComponent("Tasks.sqlite")
        let schema = Schema([TaskItem.self])
        let config = ModelConfiguration(schema: schema, url: storeURL)

        do {
            container = try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("ModelContainer oluşturulamadı: \(error.localizedDescription)")
        }
    }
}



//
//  QuickTaskApp.swift
//  QuickTask
//
//  Created by Melih Gökmen on 20.10.2025.
//


import SwiftUI
import SwiftData

@main
struct QuickTaskApp: App {
    let sharedModelContainer = SharedDataManager.shared.container

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}


//
//  WidgetEx.swift
//  WidgetEx
//
//  Created by Melih Gökmen on 20.10.2025.
//

import WidgetKit
import SwiftUI
import SwiftData
import AppIntents

struct ConfigurationAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Görevi Tamamla"

    @Parameter(title: "Task ID")
    var taskID: String

    init() {}

    init(taskID: UUID) {
        self.taskID = taskID.uuidString
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        let modelContext = SharedDataManager.shared.container.mainContext

        guard let uuid = UUID(uuidString: taskID) else {
            return .result()
        }

        var descriptor = FetchDescriptor<TaskItem>(predicate: #Predicate { $0.id == uuid })
        descriptor.fetchLimit = 1

        if let taskToToggle = try? modelContext.fetch(descriptor).first {
            taskToToggle.isCompleted.toggle()
            try? modelContext.save()
        }

        return .result()
    }
}

struct ToggleTaskCompletionIntent: AppIntent {
    static var title: LocalizedStringResource = "Görevi Tamamla"

    @Parameter(title: "Task ID")
    var taskID: String

    init() {}

    init(taskID: UUID) {
        self.taskID = taskID.uuidString
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        let modelContext = SharedDataManager.shared.container.mainContext

        guard let uuid = UUID(uuidString: taskID) else {
            return .result()
        }

        var descriptor = FetchDescriptor<TaskItem>(predicate: #Predicate { $0.id == uuid })
        descriptor.fetchLimit = 1

        if let taskToToggle = try? modelContext.fetch(descriptor).first {
            taskToToggle.isCompleted.toggle()
            try? modelContext.save()
        }
        WidgetCenter.shared.reloadAllTimelines()

        return .result()
    }
}


@main
struct QuickTaskWidget: Widget {
    let kind: String = "QuickTaskWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            QuickTaskWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Hızlı Görev")
        .description("En önemli görevini gör ve tamamla.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}


struct QuickTaskWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sıradaki Görev")
                .font(.caption)
                .foregroundColor(.secondary)

            if let task = entry.task {
                Text(task.title)
                    .font(.headline)
                    .strikethrough(task.isCompleted)

                Button(intent: ToggleTaskCompletionIntent(taskID: task.id)) {
                    Label("Tamamla", systemImage: "checkmark.circle.fill")
                }
                .tint(.green)

            } else {
                Text("Tüm görevler tamamlandı!")
                    .font(.headline)
                    .foregroundColor(.green)
            }
        }
        .padding()
    }
}


struct Provider: TimelineProvider {
    typealias Entry = SimpleEntry
    
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: .now, task: nil)
    }

    @MainActor
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let modelContext = SharedDataManager.shared.container.mainContext
        let descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate { !$0.isCompleted },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let latestTask = try? modelContext.fetch(descriptor).first
        let entry = SimpleEntry(date: .now, task: latestTask)
        completion(entry)
    }

    @MainActor
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        // SwiftData'dan en son tamamlanmamış görevi çek
        let modelContext = SharedDataManager.shared.container.mainContext
        let descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate { !$0.isCompleted },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        let latestTask = try? modelContext.fetch(descriptor).first

        let entry = SimpleEntry(date: .now, task: latestTask)

        // Widget'ı 15 dakika sonra güncelle
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: .now)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let task: TaskItem?
}


