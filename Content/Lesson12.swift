//
//  FavoriteLocation.swift
//  MapApp
//
//  Created by Melih Gökmen on 9.10.2025.
//

import Foundation
import SwiftData
import CoreLocation

@Model
final class FavoriteLocation {
    @Attribute(.unique) var id: UUID
    var name: String
    var address: String
    var latitude: Double
    var longitude: Double
    var timestamp: Date

    init(name: String, address: String, coordinate: CLLocationCoordinate2D) {
        self.id = UUID()
        self.name = name
        self.address = address
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.timestamp = .now
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}



//
//  ContentView.swift
//  MapApp
//
//  Created by Melih Gökmen on 7.10.2025.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var locationManager: LocationManager
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            MapView()
                .tabItem {
                    Label("Harita", systemImage: "map.fill")
                }
                .tag(0)

            FavoritesListView()
                .tabItem {
                    Label("Favoriler", systemImage: "star.fill")
                }
                .tag(1)
        }
        .onAppear {
            locationManager.requestLocationPermission()
        }
        .onOpenURL { url in
            handleIncomingURL(url)
        }
    }
    
    private func handleIncomingURL(_ url: URL) {
        guard let scheme = url.scheme, scheme == "konumharitam" else { return }
        
        if url.host == "favorites" {
            selectedTab = 1
        } else if url.host == "map" {
            selectedTab = 0
        }
    }
}




//
//  FavoritesListView.swift
//  MapApp
//
//  Created by Melih Gökmen on 9.10.2025.
//

import SwiftUI
import SwiftData

struct FavoritesListView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \FavoriteLocation.timestamp, order: .reverse) private var favoriteLocations: [FavoriteLocation]

    var body: some View {
        NavigationStack {
            List {
                ForEach(favoriteLocations) { location in
                    VStack(alignment: .leading) {
                        Text(location.name)
                            .font(.headline)
                        Text(location.address)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("Eklenme: \(location.timestamp, format: .relative(presentation: .named))")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .navigationTitle("Favori Konumlar")
            .overlay {
                if favoriteLocations.isEmpty {
                    ContentUnavailableView("Henüz Favori Yok", systemImage: "star.slash", description: Text("Haritadan bir noktaya dokunarak favori ekleyebilirsiniz."))
                }
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(favoriteLocations[index])
            }
        }
    }
}




//
//  LocationManager.swift
//  MapApp
//
//  Created by Melih Gökmen on 9.10.2025.
//

import Foundation
import CoreLocation
import SwiftUI
import Combine

@MainActor
final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    private let locationManager = CLLocationManager()
    
    @Published var userLocation: CLLocation?
    @Published var userAddress: String = "Adres bilgisi bekleniyor..."
    @Published var authorizationStatus: CLAuthorizationStatus

    override init() {
        self.authorizationStatus = locationManager.authorizationStatus
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestLocationPermission() {
        if authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
    }

    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.userLocation = location
        
        Task {
            await reverseGeocode(location: location)
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        self.authorizationStatus = manager.authorizationStatus
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Lokasyon hatası: \(error.localizedDescription)")
    }
    
    private func reverseGeocode(location: CLLocation) async {
        let geocoder = CLGeocoder()
        do {
            if let placemark = try await geocoder.reverseGeocodeLocation(location).first {
                var addressString = ""
                if let street = placemark.thoroughfare { addressString += street + ", " }
                if let subLocality = placemark.subLocality { addressString += subLocality + ", " }
                if let locality = placemark.locality { addressString += locality + ", " }
                if let country = placemark.country { addressString += country }
                
                if !addressString.isEmpty {
                    self.userAddress = addressString
                } else {
                    self.userAddress = "Adres bulunamadı."
                }
            }
        } catch {
            print("Adrese çevirme hatası: \(error.localizedDescription)")
            self.userAddress = "Adres alınamadı."
        }
    }
}





import SwiftUI
import SwiftData

@main
struct MapAppApp: App {
    @StateObject private var locationManager = LocationManager()
    
    let container: ModelContainer = {
        let appGroupId = "group.HaritaUygulamasi"
        let schema = Schema([FavoriteLocation.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, groupContainer: .identifier(appGroupId))
        do {
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("ModelContainer oluşturulamadı: \(error.localizedDescription)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .environmentObject(locationManager)
        .modelContainer(container)
    }
}




//
//  MapView.swift
//  MapApp
//
//  Created by Melih Gökmen on 9.10.2025.
//

import Foundation
import SwiftUI
import MapKit
import SwiftData

struct MapView: View {
    @EnvironmentObject var locationManager: LocationManager
    @Environment(\.modelContext) private var modelContext
    
    @Query private var favoriteLocations: [FavoriteLocation]
    
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var mapSelection: MKMapItem?
    
    @State private var showAddFavoriteAlert = false
    @State private var newLocationCoordinate: CLLocationCoordinate2D?
    @State private var newLocationName = ""

    var body: some View {
        ZStack {
            MapReader { proxy in
                Map(position: $cameraPosition, selection: $mapSelection) {
                    UserAnnotation()
                    
                    ForEach(favoriteLocations) { location in
                        Marker(location.name, coordinate: location.coordinate)
                            .tint(.yellow)
                    }
                }
                .onTapGesture { position in
                    if let coordinate = proxy.convert(position, from: .local) {
                        self.newLocationCoordinate = coordinate
                        self.showAddFavoriteAlert = true
                    }
                }
            }
            .ignoresSafeArea()

            VStack {
                locationInfoCard
                Spacer()
                centerOnUserButton
            }
            .padding()
        }
        .alert("Favori Konum Ekle", isPresented: $showAddFavoriteAlert) {
            TextField("Konum Adı", text: $newLocationName)
            Button("Kaydet", action: saveNewLocation)
            Button("İptal", role: .cancel) { newLocationName = "" }
        } message: {
            Text("Bu noktayı favorilerinize eklemek için bir isim girin.")
        }
        .onChange(of: locationManager.userLocation) { _, newLocation in
            if let newLocation {
                cameraPosition = .region(MKCoordinateRegion(
                    center: newLocation.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                ))
            }
        }
        .onAppear {
            locationManager.startUpdatingLocation()
        }
    }
    
    private var locationInfoCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Mevcut Konumunuz")
                .font(.headline)
            if let location = locationManager.userLocation {
                Text("Koordinat: \(String(format: "%.4f", location.coordinate.latitude)), \(String(format: "%.4f", location.coordinate.longitude))")
                    .font(.subheadline)
            }
            Text(locationManager.userAddress)
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(.thinMaterial)
        .cornerRadius(12)
        .shadow(radius: 5)
    }
    
    private var centerOnUserButton: some View {
        Button {
            if let userLocation = locationManager.userLocation {
                withAnimation {
                    cameraPosition = .region(MKCoordinateRegion(
                        center: userLocation.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)))
                }
            }
        } label: {
            Image(systemName: "location.fill")
                .font(.title2)
                .padding()
                .background(.primary)
                .foregroundColor(.secondary)
                .clipShape(Circle())
                .shadow(radius: 4)
        }
    }
    
    private func saveNewLocation() {
        guard let coordinate = newLocationCoordinate, !newLocationName.isEmpty else { return }
        
        let newFavorite = FavoriteLocation(
            name: newLocationName,
            address: "Adres bilgisi yakında eklenecek...",
            coordinate: coordinate
        )
        modelContext.insert(newFavorite)
        newLocationName = ""
    }
}






//
//  MapWidget.swift
//  MapApp
//
//  Created by Melih Gökmen on 9.10.2025.
//

import Foundation
import WidgetKit
import SwiftUI
import SwiftData
import CoreLocation
import AppIntents

struct Provider: TimelineProvider {
    private let appGroupId = "group.HaritaUygulamasi"

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), lastFavorite: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), lastFavorite: fetchLastFavorite())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = SimpleEntry(date: .now, lastFavorite: fetchLastFavorite())
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(15 * 60)))
        completion(timeline)
    }
    
    private func fetchLastFavorite() -> FavoriteLocation? {
        guard let container = try? ModelContainer(for: FavoriteLocation.self, configurations: ModelConfiguration(groupContainer: .identifier(appGroupId))) else {
            return nil
        }
        let descriptor = FetchDescriptor<FavoriteLocation>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
        return try? container.mainContext.fetch(descriptor).first
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let lastFavorite: FavoriteLocation?
}

struct HaritaWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Son Favori Konum")
                .font(.headline)
                .foregroundColor(.secondary)
            
            if let location = entry.lastFavorite {
                Text(location.name)
                    .font(.title2)
                    .fontWeight(.bold)
                Text(location.address)
                    .font(.footnote)
                Text(location.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.gray)
            } else {
                Text("Henüz favori konum eklenmedi.")
                    .font(.body)
            }
            Spacer()
            Button(intent: ShowFavoritesIntent()) {
                Label("Favorileri Aç", systemImage: "star.fill")
            }
            .tint(.yellow)
        }
        .padding()
    }
}

//@main
struct HaritaWidget: Widget {
    let kind: String = "HaritaWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            HaritaWidgetEntryView(entry: entry)
                .modelContainer(for: FavoriteLocation.self)
        }
        .configurationDisplayName("Son Favori Konum")
        .description("En son eklediğiniz favori konumu gösterir.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

extension FavoriteLocation {
    static var placeholder: FavoriteLocation {
        FavoriteLocation(name: "Anıtkabir", address: "Anıttepe, Çankaya, Ankara", coordinate: CLLocationCoordinate2D(latitude: 39.925016, longitude: 32.836952))
    }
}





//
//  AppIntents.swift
//  MapApp
//
//  Created by Melih Gökmen on 9.10.2025.
//

import Foundation
import AppIntents
import SwiftUI

struct ShowFavoritesIntent: AppIntent {
    static var title: LocalizedStringResource = "Favori Konumları Göster"
    static var description = IntentDescription("Kaydedilmiş favori konumlar listesini açar.")
    
    func perform() async throws -> some IntentResult {
        guard let url = URL(string: "konumharitam://favorites") else {
            return .result()
        }
        await UIApplication.shared.open(url)
        return .result()
    }
}

struct ShowCurrentLocationIntent: AppIntent {
    static var title: LocalizedStringResource = "Mevcut Konumumu Göster"
    static var description = IntentDescription("Haritayı açar ve mevcut konuma odaklar.")

    func perform() async throws -> some IntentResult {
        guard let url = URL(string: "konumharitam://map") else {
            return .result()
        }
        await UIApplication.shared.open(url)
        return .result()
    }
}
/*
struct HaritaAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ShowFavoritesIntent(),
            phrases: ["\(.applicationName) içinde favori konumlarımı aç", "Favorilerimi göster"]
        )
        AppShortcut(
            intent: ShowCurrentLocationIntent(),
            phrases: ["\(.applicationName) içinde mevcut konumumu göster", "Neredeyim"]
        )
    }
}
*/
