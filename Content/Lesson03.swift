import SwiftUI

// Ana Profil
struct UserProfileView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                ProfileHeaderView()
                ProfileStatsView()
                AboutMeView()
                ActionButtonsView()
                Spacer()
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(Color(.systemGroupedBackground))
    }
}
 
 
struct ProfileHeaderView: View {
    var body: some View {
        ZStack(alignment: .top) {
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 270)
            
            VStack {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 4))
                    .shadow(radius: 10)
                    .padding(.top, 60)
                
                Text("Melih Gökmen")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Text("İOS Developer")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.9))
            }
        }
    }
}

// 2. Bilgi Kartları
struct ProfileStatsView: View {
    var body: some View {
        HStack(spacing: 16) {
            StatsCard(value: "1.2M", label: "Takipçi")
            StatsCard(value: "345", label: "Takip Edilen")
            StatsCard(value: "5.8M", label: "Beğeni")
        }
        .padding(.horizontal)
    }
}

// Tek bir bilgi kartı için yeniden kullanılabilir View
struct StatsCard: View {
    let value: String
    let label: String
    var body: some View {
        VStack {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 5)
    }
}

// 3. Hakkımda
struct AboutMeView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Hakkımda")
                .font(.title2)
                .fontWeight(.bold)

            Text("Developed and implemented UI and business logic using‬‭ MVVM architecture‬‭, ‬‭ Swift‬‭, and‬ SwiftUI‬‭. Managed one-week sprints following the‬‭ Agile-Scrum‬‭ methodology‬‭ to deliver‬ timely updates. Published multiple versions of apps on the App Store, enhancing app functionality and‬‭ user experience. Debugged and integrated new modules, improving application performance and stability.")
                .lineLimit(nil)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }
}

// 4. Buton Alanı
struct ActionButtonsView: View {
    var body: some View {
        HStack(spacing: 16) {
            Button(action: {
                print("Mesaj Gönder tıklandı!")
            }) {
                Text("Mesaj Gönder")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            
            Button(action: {
                print("Takip Et tıklandı!")
            }) {
                Text("Takip Et")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.blue)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue, lineWidth: 2)
                    )
            }
        }
        .padding(.horizontal)
    }
}


struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        UserProfileView()
    }
}
