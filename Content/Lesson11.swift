//
//  Character.swift
//  Rick & Morty Verse
//
//  Created by Melih Gökmen on 23.09.2025.
//


import Foundation

struct APIResponse: Codable {
    let info: Info
    let results: [Character]
}

struct Info: Codable {
    let count: Int
    let pages: Int
    let next: String?
    let prev: String?
}

struct Character: Codable, Identifiable, Equatable {
    let id: Int
    let name: String
    let status: Status
    let species: String
    let type: String
    let gender: Gender
    let origin: Location
    let location: Location
    let image: String
    let episode: [String]
    let url: String
    let created: String
}

enum Status: String, Codable {
    case alive = "Alive"
    case dead = "Dead"
    case unknown = "unknown"
}

enum Gender: String, Codable {
    case female = "Female"
    case male = "Male"
    case genderless = "Genderless"
    case unknown = "unknown"
}

struct Location: Codable, Equatable {
    let name: String
    let url: String
}





//
//  CharacterListView.swift
//  Rick & Morty Verse
//
//  Created by Melih Gökmen on 23.09.2025.
//

import SwiftUI

struct CharacterListView: View {
    @StateObject private var viewModel = CharacterListViewModel()
    @State private var searchText = ""

    var body: some View {
        NavigationView {
            VStack {
                if let errorMessage = viewModel.errorMessage, viewModel.characters.isEmpty {
                    VStack {
                        Text("😢")
                            .font(.largeTitle)
                        Text(errorMessage)
                            .padding()
                        Button("Tekrar Dene") {
                            Task {
                                await viewModel.loadCharacters(isInitialLoad: true, searchQuery: searchText)
                            }
                        }
                    }
                } else {
                    List {
                        ForEach(viewModel.characters) { character in
                            NavigationLink(destination: CharacterDetailView(character: character)) {
                                CharacterRowView(character: character)
                                    .onAppear {
                                        viewModel.loadMoreCharactersIfNeeded(currentItem: character)
                                    }
                            }
                        }
                        
                        if viewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else if viewModel.canLoadMorePages {
                             Button("Daha Fazla Yükle") {
                                Task {
                                    await viewModel.loadCharacters(isInitialLoad: false, searchQuery: searchText)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                    .listStyle(.plain)
                    .refreshable { // Pull-to-refresh
                        await viewModel.refreshCharacters()
                    }
                }
            }
            .navigationTitle("Rick & Morty")
            .searchable(text: $searchText, prompt: "Karakter ara...")
            .onChange(of: searchText) { newValue in
                Task {
                    await viewModel.loadCharacters(isInitialLoad: true, searchQuery: newValue)
                }
            }
            .onAppear {
                if viewModel.characters.isEmpty {
                    Task {
                        await viewModel.loadCharacters()
                    }
                }
            }
        }
    }
}


struct CharacterRowView: View {
    let character: Character

    var body: some View {
        HStack {
            AsyncImage(url: URL(string: character.image)) { image in
                image.resizable()
                     .aspectRatio(contentMode: .fill)
            } placeholder: {
                ProgressView()
            }
            .frame(width: 60, height: 60)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.gray, lineWidth: 1))
            
            VStack(alignment: .leading) {
                Text(character.name)
                    .font(.headline)
                Text(character.species)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}



//
//  CharacterDetailView.swift
//  Rick & Morty Verse
//
//  Created by Melih Gökmen on 23.09.2025.
//

import SwiftUI

struct CharacterDetailView: View {
    let character: Character
    @State private var isFavorite = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                AsyncImage(url: URL(string: character.image)) { image in
                    image.resizable()
                         .aspectRatio(contentMode: .fit)
                } placeholder: {
                    ProgressView()
                }
                .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text(character.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    HStack {
                        Circle()
                            .fill(character.status == .alive ? .green : (character.status == .dead ? .red : .gray))
                            .frame(width: 10, height: 10)
                        Text("\(character.status.rawValue) - \(character.species)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    InfoRow(label: "Cinsiyet", value: character.gender.rawValue)
                    InfoRow(label: "Son Görüldüğü Yer", value: character.location.name)
                    InfoRow(label: "Kökeni", value: character.origin.name)
                }
                .padding()
            }
            .padding()
        }
        .navigationTitle(character.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: toggleFavorite) {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .foregroundColor(.yellow)
                }
            }
        }
        .onAppear(perform: checkFavoriteStatus)
    }
    
    private func checkFavoriteStatus() {
        let favorites = UserDefaults.standard.array(forKey: "favoriteCharacters") as? [Int] ?? []
        isFavorite = favorites.contains(character.id)
    }

    private func toggleFavorite() {
        var favorites = UserDefaults.standard.array(forKey: "favoriteCharacters") as? [Int] ?? []
        if isFavorite {
            favorites.removeAll { $0 == character.id }
        } else {
            favorites.append(character.id)
        }
        UserDefaults.standard.set(favorites, forKey: "favoriteCharacters")
        isFavorite.toggle()
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.body)
        }
    }
}



//
//  CharacterListViewModel.swift
//  Rick & Morty Verse
//
//  Created by Melih Gökmen on 23.09.2025.
//


import Foundation
import Combine

@MainActor
class CharacterListViewModel: ObservableObject {
    
    @Published var characters: [Character] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var canLoadMorePages = true
    
    private let apiService = RickAndMortyAPIService()
    private var currentPage = 1
    private var currentSearchQuery = ""

    func loadCharacters(isInitialLoad: Bool = true, searchQuery: String? = nil) async {
        if isLoading { return }
    
        if let searchQuery = searchQuery, searchQuery != currentSearchQuery {
            self.currentSearchQuery = searchQuery
            self.characters = []
            self.currentPage = 1
            self.canLoadMorePages = true
        } else if isInitialLoad {
            self.characters = []
            self.currentPage = 1
            self.canLoadMorePages = true
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiService.fetchCharacters(page: currentPage, name: currentSearchQuery)
            characters.append(contentsOf: response.results)
            
            if response.info.next == nil {
                canLoadMorePages = false
            } else {
                currentPage += 1
            }
        } catch {
            if let apiError = error as? APIError {
                switch apiError {
                case .invalidResponse:
                    errorMessage = "Karakter bulunamadı."
                    canLoadMorePages = false
                default:
                    errorMessage = "Veri alınırken bir hata oluştu. Lütfen internet bağlantınızı kontrol edin."
                }
            } else {
                errorMessage = error.localizedDescription
            }
        }
        
        isLoading = false
    }
    
    func refreshCharacters() async {
        currentSearchQuery = ""
        await loadCharacters(isInitialLoad: true)
    }
    
    func loadMoreCharactersIfNeeded(currentItem: Character?) {
        guard let currentItem = currentItem else {
            return
        }
        
        let thresholdIndex = characters.index(characters.endIndex, offsetBy: -5)
        if characters.firstIndex(where: { $0.id == currentItem.id }) == thresholdIndex && canLoadMorePages {
            Task {
                await loadCharacters(isInitialLoad: false)
            }
        }
    }
}



//
//  RickAndMortyAPIService.swift
//  Rick & Morty Verse
//
//  Created by Melih Gökmen on 23.09.2025.
//


import Foundation

enum APIError: Error {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case decodingError(Error)
}

class RickAndMortyAPIService {
    private let baseURL = "https://rickandmortyapi.com/api"

    func fetchCharacters(page: Int, name: String? = nil) async throws -> APIResponse {
        var urlComponents = URLComponents(string: "\(baseURL)/character")!
        
        var queryItems = [URLQueryItem(name: "page", value: "\(page)")]
        if let name = name, !name.isEmpty {
            queryItems.append(URLQueryItem(name: "name", value: name))
        }
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw APIError.invalidResponse
            }
            
            let decodedResponse = try JSONDecoder().decode(APIResponse.self, from: data)
            return decodedResponse
        } catch {
            if error is DecodingError {
                throw APIError.decodingError(error)
            } else {
                throw APIError.requestFailed(error)
            }
        }
    }
}





import SwiftUI

@main
struct RickAndMortyVerseApp: App {
    init() {
        configureURLCache()
    }

    var body: some Scene {
        WindowGroup {
            CharacterListView()
        }
    }
    
    private func configureURLCache() {
        let memoryCapacity = 50 * 1024 * 1024
        let diskCapacity = 100 * 1024 * 1024
        URLCache.shared = URLCache(memoryCapacity: memoryCapacity, diskCapacity: diskCapacity, diskPath: "rickandmorty_images")
    }
}



//
//  CharacterListViewModelTests.swift
//  Rick & Morty VerseTests
//
//  Created by Melih Gökmen on 23.09.2025.
//


import Foundation
import XCTest
@testable import RickMortyVerseApp 

class MockAPIService: APIServiceProtocol {
    var shouldReturnError = false

    func fetchCharacters(page: Int, name: String?) async throws -> APIResponse {
        if shouldReturnError {
            throw APIError.invalidResponse
        }

        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "MockCharacterResponse", withExtension: "json") else {
            fatalError("Mock JSON file not found")
        }
        let data = try Data(contentsOf: url)
        let decodedResponse = try JSONDecoder().decode(APIResponse.self, from: data)
        return decodedResponse
    }
}

@MainActor
class CharacterListViewModelTests: XCTestCase {
    var viewModel: CharacterListViewModel!
    var mockAPIService: MockAPIService!

    override func setUp() {
        super.setUp()
        mockAPIService = MockAPIService()
    }

    func test_loadCharacters_success() async {
        mockAPIService.shouldReturnError = false

        await viewModel.loadCharacters()

        XCTAssertFalse(viewModel.characters.isEmpty, "Karakterler yüklenmeliydi.")
        XCTAssertEqual(viewModel.characters.count, 2, "Mock veride 2 karakter olmalı.")
        XCTAssertNil(viewModel.errorMessage, "Hata mesajı olmamalı.")
    }

    func test_loadCharacters_failure() async {
        mockAPIService.shouldReturnError = true

        await viewModel.loadCharacters()

        XCTAssertTrue(viewModel.characters.isEmpty, "Hata durumunda karakter listesi boş olmalı.")
        XCTAssertNotNil(viewModel.errorMessage, "Hata mesajı set edilmiş olmalı.")
    }
}

