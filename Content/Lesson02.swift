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