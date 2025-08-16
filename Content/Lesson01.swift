//1.1
import Foundation

let adSoyad: String = "Melih Gökmen"
let sehir: String = "İstanbul"
var yas: Int = 33
let boy: Double = 1.78
let turkMü: Bool = true
var ikinciAd: String? = ""
var favoriRenk: String? = nil

//Bilgileri Yazdırma
print("KİŞİSEL BİLGİ KARTI")
print("Adı Soyadı: \(adSoyad)")
print("Yaşı: \(yas)")
print("Boyu: \(boy) metre")
print("Şehir: \(sehir)")
print("Türk Vatandaşı: \(turkMü ? "Evet" : "Hayır")")
print("---------------------------")

//(Optional Binding)
if let unwrappedIkinciAd = ikinciAd {
    print("İkinci Adı: \(unwrappedIkinciAd)")
} else {
    print("Kullanıcının ikinci bir adı yok.")
}

if let unwrappedFavoriRenk = favoriRenk {
    print("Favori Rengi: \(unwrappedFavoriRenk)")
} else {
    print("Kullanıcının belirttiği bir favori rengi yok.")
}


if let ikinciIsim = ikinciAd, let sansliNo = sansliNumarasi {
    print("\(ikinciIsim) isminin şanslı numarası \(sansliNo).")
}





//1.2
import Foundation

enum IslemTipi {
    case toplama
    case cikarma
    case carpma
    case bolme
}

// Hesap makinesi fonksiyonu
func hesapMakinesi(sayi1: Double, sayi2: Double, islem: IslemTipi) -> Double? {
    switch islem {
    case .toplama:
        return sayi1 + sayi2
    case .cikarma:
        return sayi1 - sayi2
    case .carpma:
        return sayi1 * sayi2
    case .bolme:
        if sayi2 == 0 {
            print("Hata: Bir sayı sıfıra bölünemez!")
            return nil // Hata durumunda nil
        }
        return sayi1 / sayi2
    }
}

print("--- HESAP MAKİNESİ SONUÇLARI ---")

if let toplamaSonucu = hesapMakinesi(sayi1: 10, sayi2: 5, islem: .toplama) {
    print("Toplama: \(toplamaSonucu)") // Çıktı: 15.0
}

if let cikarmaSonucu = hesapMakinesi(sayi1: 10, sayi2: 5, islem: .cikarma) {
    print("Çıkarma: \(cikarmaSonucu)") // Çıktı: 5.0
}

if let carpmaSonucu = hesapMakinesi(sayi1: 10, sayi2: 5, islem: .carpma) {
    print("Çarpma: \(carpmaSonucu)") // Çıktı: 50.0
}

if let bolmeSonucu = hesapMakinesi(sayi1: 10, sayi2: 5, islem: .bolme) {
    print("Bölme: \(bolmeSonucu)") // Çıktı: 2.0
}

let hataliBolme = hesapMakinesi(sayi1: 10, sayi2: 0, islem: .bolme)
print("Hatalı Bölme Sonucu: \(hataliBolme)")
print("---------------------------------")