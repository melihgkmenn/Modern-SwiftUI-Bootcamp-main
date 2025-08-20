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