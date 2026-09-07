# Sobo Society Mobile App - Shorebird & Deployment Guide

## 📌 Proje Genel Bilgileri
- **Uygulama Adı:** Sobo Society
- **Shorebird App ID:** `dfef2ab2-bc9c-4317-a46a-0be276645962`
- **Backend API:** `https://sobosociety.com/api/v1`
- **Geçerli Sürüm:** `1.0.0+10`
- **APK İndirme Adresi:** `https://ilacbilgi.org/ss/uploads/sobosociety-app.apk`

---

## 🚀 Shorebird (CodePush) İle Mağaza Onaysız Anlık Güncelleme

Sitede veya mobil uygulamanın arayüzünde/kodunda bir değişiklik yaptığınızda App Store veya Play Store onayını beklemeden Over-The-Air (OTA) güncelleme gönderebilirsiniz.

### 1. Ortam Değişkeni (Token) Tanımlama
```bash
export SHOREBIRD_TOKEN="sb_api_TXmtC63S-oANCcJJfCydAso1jolGgyTFpHgsm7fTuCA"
export PATH="/root/.shorebird/bin:$PATH"
cd /home/sobo/android
```

### 2. Anlık Yama (Patch) Gönderme (Önemli!)
Uygulamayı kullanan mevcut kullanıcılara mağaza incelemesi olmadan anında kod güncellemesi göndermek için:

#### Android İçin Patch Gönderme:
```bash
shorebird patch --platforms=android
```

#### iOS İçin Patch Gönderme:
```bash
shorebird patch --platforms=ios
```

> 💡 **Not:** Bu komutu çalıştırdığınızda kullanıcılar uygulamayı bir sonraki açışlarında değişiklikleri doğrudan telefonlarında görürler.

---

## 📦 Yeni Sürüm (Release) Derleme

Eğer `pubspec.yaml` dosyasında ana versiyon numarasını değiştirirseniz (örn: 1.0.1+11) yeni bir temel yayın derlemeniz gerekir:

### Android APK Derleme ve Yükleme:
```bash
export SHOREBIRD_TOKEN="sb_api_TXmtC63S-oANCcJJfCydAso1jolGgyTFpHgsm7fTuCA"
export PATH="/root/.shorebird/bin:$PATH"
cd /home/sobo/android
yes | shorebird release android --artifact=apk
cp build/app/outputs/flutter-apk/app-release.apk /var/www/html/ilacbilgi-ss/uploads/sobosociety-app.apk
```

### Android Play Store AAB Derleme:
```bash
shorebird release android
```

---

## 🛠️ Mimari Özellikler ve Kurallar

1. **İçerik Güncellemeleri:**  
   Paketler, seanslar, workshoplar ve yapay zeka kuralları `https://sobosociety.com/api/v1` üzerinden dinamik çekilir. Admin panelinde yapılan veri değişiklikleri uygulamaya anında yansır.
2. **Üye Olmayan Fiyat Gizliliği:**  
   Giriş yapmamış misafir kullanıcılara net fiyatlar gösterilmez, WhatsApp yönlendirmesi yapılır.
3. **Popüler Paket:**  
   12 Derslik paket "POPÜLER SEÇİM ⭐" etiketi ile otomatik öne çıkarılır.
4. **Ders İptali 12 Saat Kuralı:**  
   "Derslerim" sekmesinde ders başlangıcına 12 saatten az süre kaldığında iade/iptal hakkı kısıtlanır ve sayaç gösterilir.
