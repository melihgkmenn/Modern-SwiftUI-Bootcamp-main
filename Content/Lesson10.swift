
//https://pokeapi.co/api/v2/ kullanıldı
//https://pokeapi.co/


import Foundation

struct PokemonResponse: Codable {
    let results: [PokemonEntry]
}

struct PokemonEntry: Codable, Identifiable {
    let name: String
    let url: String
    var id: String { name }
    var imageUrl: URL? {
        if let idString = url.split(separator: "/").last, let id = Int(idString) {
            return URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/\(id).png")
        }
        return nil
    }
}




import Foundation
import Combine

@MainActor
class PokemonViewModel: ObservableObject {
    @Published var pokemonList: [PokemonEntry] = []
    @Published var errorMessage: String?
    private let apiURL = "https://pokeapi.co/api/v2/pokemon?limit=151"
    
    func fetchPokemon() async {
        guard let url = URL(string: apiURL) else {
            errorMessage = "Geçersiz URL!"
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(PokemonResponse.self, from: data)
            self.pokemonList = response.results
            self.errorMessage = nil
        } catch {
            errorMessage = "Veri çekilemedi: \(error.localizedDescription)"
        }
    }
}




//
//  ContentView.swift
//  PokeApiApp
//
//  Created by Melih Gökmen on 18.09.2025.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @StateObject private var viewModel = PokemonViewModel()
    @State private var searchText = ""
    
    var filteredPokemon: [PokemonEntry] {
        if searchText.isEmpty {
            return viewModel.pokemonList
        } else {
            return viewModel.pokemonList.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                } else {
                    List(filteredPokemon) { pokemon in
                        NavigationLink(destination: PokemonDetailView(pokemonEntry: pokemon)) {
                            HStack {
                                AsyncImage(url: pokemon.imageUrl) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                    case .failure:
                                        Image(systemName: "questionmark.diamond")
                                            .foregroundColor(.gray)
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                                .frame(width: 80, height: 80)
                                
                                Text(pokemon.name.capitalized)
                                    .font(.headline)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Pokémon")
            .searchable(text: $searchText, prompt: "Pokémon Ara...")
            .onAppear {
                Task {
                    await viewModel.fetchPokemon()
                }
            }
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}





import Foundation

struct PokemonDetail: Codable {
    let id: Int
    let height: Int
    let weight: Int
    let types: [PokemonTypeEntry]
    let sprites: PokemonSprites
}

struct PokemonTypeEntry: Codable, Identifiable {
    var id: Int { slot }
    let slot: Int
    let type: PokemonType
}

struct PokemonType: Codable {
    let name: String
}

struct PokemonSprites: Codable {
    let front_default: URL
}




import Foundation
import SwiftUI

struct PokemonDetailView: View {
    let pokemonEntry: PokemonEntry
    @StateObject private var viewModel = PokemonDetailViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let detail = viewModel.pokemonDetail {
                    AsyncImage(url: detail.sprites.front_default) { image in
                        image.resizable()
                    } placeholder: {
                        ProgressView()
                    }
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 200)

                    Text(pokemonEntry.name.capitalized)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(String(format: "#%03d", detail.id))
                        .font(.title)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        ForEach(detail.types) { typeEntry in
                            Text(typeEntry.type.name.capitalized)
                                .font(.headline)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(typeColor(for: typeEntry.type.name))
                                .foregroundColor(.white)
                                .cornerRadius(20)
                        }
                    }
                    
                    HStack(spacing: 40) {
                        VStack {
                            Text("Height")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("\(String(format: "%.1f", Double(detail.height) / 10.0)) m")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        VStack {
                            Text("Weight")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("\(String(format: "%.1f", Double(detail.weight) / 10.0)) kg")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                    }
                    .padding()
                    
                } else if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                } else {
                    ProgressView()
                }
            }
        }
        .navigationTitle(pokemonEntry.name.capitalized)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                await viewModel.fetchData(for: pokemonEntry.url)
            }
        }
    }
    
    private func typeColor(for type: String) -> Color {
        switch type {
        case "fire": return .red
        case "grass": return .green
        case "water": return .blue
        case "poison": return .purple
        case "electric": return .yellow
        case "bug": return .brown
        case "normal": return .gray
        case "flying": return .cyan
        case "ground": return .orange
        case "rock": return .secondary
        case "psychic": return .pink
        default: return .black.opacity(0.6)
        }
    }
}



import Foundation
import Combine

@MainActor
class PokemonDetailViewModel: ObservableObject {
    
    @Published var pokemonDetail: PokemonDetail?
    @Published var errorMessage: String?
    
    func fetchData(for urlString: String) async {
        guard let url = URL(string: urlString) else {
            errorMessage = "Geçersiz Pokémon URL'i!"
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decodedDetail = try JSONDecoder().decode(PokemonDetail.self, from: data)
            self.pokemonDetail = decodedDetail
            self.errorMessage = nil
            
        } catch {
            errorMessage = "Detaylar alınamadı: \(error.localizedDescription)"
            pokemonDetail = nil
        }
    }
}

