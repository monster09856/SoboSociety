# Sobo Society — Rezervasyon Sistemi Tasarım Dokümanı

**Tarih:** 2026-08-25
**Durum:** Onay bekliyor
**Kapsam:** Tanıtım sitesi + üye rezervasyon (web) + admin paneli + iOS uygulaması

---

## 1. Bağlam

Sobo Society bir barre/pilates/functional stüdyosu. Instagram profili:
`@thesobosociety` — "Barre | Pilates | Functional / Not just a studio. It's a
society." 655 takipçi, 39 gönderi (Ağustos 2026).

**Bugünkü durum:** rezervasyonlar **Instagram DM üzerinden** alınıyor. Kayıt
defteri eğitmenin kendi belleği ve DM geçmişi.

**Çözülecek asıl problem** rezervasyon almak değil, DM'de dağılmış olan üç
bilginin tek yerde toplanması:
1. Bir derste kaç kişi var, kimler
2. Bir üyenin kaç dersi kaldı
3. Kim gelip kim gelmedi

### 1.1 Bu projenin başarısızlık senaryosu

Sistem teknik olarak çalışır ama **eğitmen DM'e geri döner.** Bu, bu tür
projelerin en yaygın ölüm sebebi ve tasarımın tamamını yönlendiriyor:

- Admin paneli bir raporlama ekranı değil, eğitmenin **asıl çalışma aleti**
- DM'den gelen rezervasyonu panele işlemek **5 saniyeden kısa** sürmeli
- Üye sistemi kullanmasa bile eğitmen kullanabilmeli (üyeyi panelden aç,
  dersine ekle, kredisi otomatik düşsün)

Sistem, DM'i bir günde öldüremez. DM ile birlikte yaşayabilmeli.

---

## 2. Varsayımlar

Ölçülmemiş, işletmeden teyit edilmedi. **Yanlış çıkanlar spec'i değiştirir.**

| # | Varsayım | Yanlışsa etkisi |
|---|---|---|
| V1 | 3 ders tipi: Barre, Pilates, Functional | Sadece veri, kod değişmez |
| V2 | Kontenjan ders tipine göre ayarlanır, başlangıç 8 | Sadece veri |
| V3 | Tek salon, aynı anda tek ders | Model çok salonu destekliyor, v1'de UI'da gizli |
| V4 | 2–3 eğitmen | Sadece veri |
| V5 | Haftalık program sabit şablon + sık istisna | **Yüksek** — şablon yoksa takvim yönetimi baştan tasarlanır |
| V6 | Paketler: 8/12/16 ders, süreli geçerlilik | Orta — sınırsız aylık üyelik varsa ledger'a yeni tip eklenir |
| V7 | Online ödeme YOK, paket panelden tanımlanır | **Yüksek** — ödeme v1'e girerse kapsam ~2 kat |
| V8 | Birebir özel ders = kontenjan 1 ders | Düşük |
| V9 | İptal penceresi ders saatinden 6 saat önce | Sadece config |

---

## 3. Kapsam

### v1'de var
Üye kaydı (telefon + SMS OTP) · haftalık program · rezervasyon · iptal ·
bekleme listesi · ders paketi ve kredi takibi · yoklama · push bildirim ·
duyuru · admin paneli · tanıtım sitesi.

### v1'de yok (bilinçli)
Online ödeme · sosyal akış/yorum · video ders arşivi · ilerleme takibi ·
çoklu şube · **Android uygulaması**.

**Ödeme neden dışarıda:** iyzico/PayTR entegrasyonu tek başına gelmiyor —
iade, kısmi iade, mutabakat ve fatura kuyruğunu da getirir. Kredi ledger'ı
(§5.2) doğru kurulursa ödeme sonradan tek servis olarak takılır, veri modeli
değişmez.

**Android neden dışarıda:** işletme kararı (25 Ağu 2026).

---

## 4. Platform kararı ve sonucu

```
FastAPI + PostgreSQL + Redis        ← tüm iş kuralları burada
   ├── Next.js   → tanıtım sitesi + ÜYE REZERVASYON + admin paneli
   └── SwiftUI   → iOS uygulaması
```

**Neden ayrık backend:** iş kuralları — kredi düşme, kontenjan, iptal
penceresi — tek yerde. Üç istemci de aynı kuralı görüyor. Mevcut ekip
uzmanlığı (AkorLab) birebir bu stack.

**Neden SwiftUI, Flutter değil:** AkorLab Flutter'dan native SwiftUI'ye
geçmiş durumda (`ios-native/`, 301 Swift dosyası). Ekip uzmanlığı ve
paylaşılabilir tasarım sistemi orada.

### 4.1 Android olmamasının doğrudan sonucu

Türkiye'de Android payı ~%70. Yani **üyelerin çoğunluğu iOS uygulamasını
hiç görmeyecek.** Bu, web'in rolünü değiştirir:

> Web'deki üye rezervasyon akışı bir yedek değil, **çoğunluğun asıl
> arayüzüdür.**

Bunun tasarım karşılıkları:
- Üye web akışı **mobil-first** tasarlanır, masaüstü ikincildir
- **PWA**: manifest + service worker → "Ana Ekrana Ekle" ile app hissi
- Web push (Android Chrome destekler) → iOS app'e paralel bildirim kanalı
- iOS uygulamasında olan hiçbir üye özelliği web'de eksik olamaz

---

## 5. Backend tasarımı

### 5.1 Veri modeli

```
members             telefon(unique), ad, kvkk_onay_at, katilimci_gorunurluk_onay
instructors         ad, biyografi, foto
class_types         ad, kontenjan, sure_dk, renk, iptal_penceresi_saat
rooms               ad, kapasite            (v1: 1 kayıt)
schedule_templates  hafta_gunu, saat, class_type_id, instructor_id, room_id,
                    gecerli_baslangic, gecerli_bitis
class_sessions      baslangic_utc, class_type_id, instructor_id, room_id,
                    kontenjan, dolu_sayi, durum(active|cancelled),
                    template_id(nullable)
bookings            member_id, session_id, durum(booked|cancelled|attended|no_show),
                    olusturma_kaynagi(app|web|admin)
packages            ad, ders_adedi, gecerlilik_gun, fiyat
member_packages     member_id, package_id, baslangic, bitis
credit_ledger       member_id, member_package_id, tip, miktar, sebep,
                    booking_id(nullable), created_at      ← APPEND-ONLY
waitlist_entries    member_id, session_id, sira, teklif_bitis(nullable)
devices             member_id, platform, push_token
announcements       baslik, metin, gonderim_at
```

### 5.2 Üç kritik mekanizma

#### (a) Kontenjan yarışı

İki kişi son yere aynı anda basarsa. Kilit yerine tek atomik UPDATE:

```sql
UPDATE class_sessions
   SET dolu_sayi = dolu_sayi + 1
 WHERE id = :session_id
   AND dolu_sayi < kontenjan
   AND durum = 'active'
RETURNING dolu_sayi;
```

Etkilenen satır **0 ise** ders dolmuştur → üye bekleme listesine düşer.
`SELECT FOR UPDATE` yok, deadlock yok, tek round-trip.

`dolu_sayi` denormalize bir sayaçtır; doğruluğu bu UPDATE'in atomikliğine
bağlıdır. Gece bir job `bookings` sayımıyla karşılaştırıp sapma varsa
loglar (sessiz bozulmaya karşı).

`class_sessions.kontenjan`, `class_types.kontenjan`'ın **kopyasıdır, referansı
değil.** Ders tipinin kontenjanı sonradan 8'den 6'ya düşerse geçmiş derslerin
kaydı bozulmamalı; ayrıca tek bir dersin kontenjanı istisnaen değiştirilebilir
(iki reformer arızalandı). Snapshot bu yüzden.

#### (b) Kredi ledger'ı

`member_packages.kalan_ders` diye bir sayaç **tutulmaz.** Bunun yerine
append-only hareket defteri:

| tip | miktar | ne zaman |
|---|---|---|
| `purchase` | +8 | paket tanımlandı |
| `booking` | −1 | rezervasyon yapıldı |
| `cancel_refund` | +1 | pencere içinde iptal |
| `late_cancel` | 0 | geç iptal — kredi yanar, satır yine yazılır |
| `no_show` | 0 | gelmedi — kredi yanar |
| `expire` | −n | paket süresi doldu |
| `admin_adjust` | ±n | eğitmen düzeltmesi — **sebep zorunlu** |

Bakiye = `SUM(miktar)`.

**Neden ledger:** "Benim 3 dersim daha vardı" tartışması küçük stüdyoda her
ay çıkar. Sayaçla bu tartışma kapanmaz, tarihçeyle kapanır. `late_cancel` ve
`no_show` satırlarının miktarı 0 olsa bile yazılır — çünkü onlar bakiyeyi
değil, **neyin neden yandığını** anlatır.

#### (c) Bekleme listesi

Yer açıldığında sıradaki üyeye push gider, **20 dakika** hakkı olur;
kullanmazsa sıra ilerler. Redis'te süreli anahtar + arka plan işi.

Ders saatine 20 dakikadan az kaldıysa teklif süresi kalan süreye kısaltılır.

### 5.3 Diğer kararlar

- **Saat dilimi:** UTC saklanır, `Europe/Istanbul` ile sunulur.
- **Idempotency:** mobil ağda çift tıklama → `Idempotency-Key` başlığı.
- **Auth:** telefon + SMS OTP (Netgsm / İletimerkezi).
  Eğitmen üyeyi panelden telefonla açar; üye app'e/web'e girince kayıt
  kendiliğinden eşleşir. **Instagram DM geçişini çözen mekanizma budur.**
- **Yetki:** `member` / `instructor` / `admin`
- **KVKK:** aydınlatma metni + zaman damgalı açık rıza kaydı.
  Katılımcı görünürlüğü **ayrı** rıza, **varsayılan kapalı**.
- **Rate limit:** OTP isteği telefon başına dakikada 1, saatte 5.

---

## 6. Tasarım sistemi

### 6.1 Yöntem: ölç, uydurma

`premium-ui` disiplini. Bir maddeyi "var" diye kapatmadan önce üç şey
ölçülür: kaç kez kullanılıyor · değeri doğru mu · yanlış alternatifi hâlâ
yaşıyor mu.

AkorLab'de bunun kanıtı: `AkorRadius` ölçeği "vardı" ama fiilen sevk edilen
527 yüzey sayıldığında en sık üç değerden ikisi ölçekte yoktu
(`12→122, 14→113, 16→89, 10→64, 18→47`); ölçeği kullanan yalnız 16 çağrı
vardı (%3) — çünkü ihtiyaç duyulan değer ölçekte yoktu.

**Her token dosyası "neden var + ölçüm + ne zaman değişti" yorumu taşır.**

### 6.2 AkorLab'ten devralınan yapı

Değerler DEĞİL, yapı ve isimlendirme devralınır. AkorLab koyu tema + neon
yeşil (`#00E676` / `#0B0F14`); Sobo aydınlık + taupe. Değer kopyalamak
felaket olur.

| AkorLab | Kullanım (ölçüldü) | Sobo karşılığı |
|---|---|---|
| `AkorColors.swift` | 2.801 çağrı | `SoboColors` — kademeli semantik renk |
| `AkorSpacing.swift` | 327 çağrı | `SoboSpacing` — 4pt ölçek + `gutter` |
| `AkorRadius` | 413 çağrı | `SoboRadius` — kademeli yarıçap |
| `AkorMotion.swift` | süre + yay ölçeği | `SoboMotion` |
| `AkorFonts.swift` | 9 kademe | `SoboFonts` |
| `AkorButtonStyle.swift` | 173 çağrı | 3 kademeli buton ailesi |
| `Haptics.swift` | 477 çağrı | aynen |
| `AkorSectionLabel.swift` | tek bileşen | + Türkçe büyük-harf çözümü |

### 6.3 Türkçe büyük-harf tuzağı (AkorLab'den devralınan bug fix)

SwiftUI `.textCase(.uppercase)` **ortam yerelini** okur, locale parametresi
yoktur. Cihazı İngilizce olan kullanıcıda `i → I` olur:

```
"Bildirimler" → "BILDIRIMLER"   (doğrusu BİLDİRİMLER)
"Üyeliğim"    → "ÜYELIĞIM"      (doğrusu ÜYELİĞİM)
```

AkorLab'de ölçüldü: 37 bölüm başlığının 16'sı küçük `i` içeriyordu.

**Çözüm:** `SoboL10n.buyukHarf(_:)` — cihaz yerelini değil uygulamanın
seçili dilini kullanır. Web tarafında `toLocaleUpperCase('tr-TR')`.
Karşılaştırmalarda her zaman `lowercased(with: Locale(identifier: "en_US_POSIX"))`.

### 6.4 Renk

Marka: sıcak taupe/mocha, krem, ivory, açık meşe. Aydınlık tema. **Koyu tema
yok** — bu marka aydınlık, koyu varyant üretmek markayı bozar.

```
--ink        #2B2522   birincil metin
--secondary  #6B5D52   ikincil metin
--muted      #8A7B6E   üçüncül / etiket
--mocha      #A2846F   marka vurgusu — METİN DEĞİL
--espresso   #6F5647   dolu buton, koyu çapa
--sand       #E9E1D6   kart zemini
--ivory      #F7F4EF   sayfa zemini
--line       #DDD3C7   ayraç, kenarlık
--sage       #7D8B72   onaylandı / rezerve
--clay       #B5714E   uyarı / geç iptal
```

**Kontrast (ivory `#F7F4EF` zemininde, hesaplandı):**

| Token | Oran | Kullanım |
|---|---|---|
| `ink` | 13.0:1 | ✅ AAA — her yerde |
| `secondary` | 5.8:1 | ✅ AA — açıklama, eğitmen adı |
| `muted` | 3.7:1 | ⚠️ **yalnız ≥18pt** etiket / bölüm başlığı |
| beyaz on `espresso` | 6.8:1 | ✅ AA — buton metni |
| beyaz on `mocha` | 3.4:1 | ❌ **gövde metni için YASAK** |

> 🔴 `muted` gövde metninde kullanılamaz. Bu token yorumuna yazılacak —
> yoksa altı ay sonra biri açıklama metnine uygular ve kimse fark etmez.

> 🔴 Marka mochası metin rengi değildir. Vurgu, çizgi, ikon, aktif durum.
> Dolu buton `espresso` kullanır.

### 6.5 Sobo'nun risk profili AkorLab'in TERSİ

AkorLab koyu + neon → riski **aşırı vurgu**: her şey parlar, hiçbiri öne
çıkmaz.

Sobo krem + taupe + serif → riski **hiç vurgu olmaması.** Düşük kontrastlı
sakin paletlerde "AI üretimi" hissi başka türlü doğar:

**a) Aynı-tonluluk.** Krem zemin / bej kart / taupe metin — hepsi aynı
ailede, hiyerarşi erir, ekran şablon gibi durur.
→ *Çözüm:* `espresso` koyu çapa + gerçek 3 kademeli metin rengi zorunlu.

**b) Serif her yerde.** Serif gövde metnine yayılırsa Canva şablonu olur.
→ *Kural:* serif **yalnız** display/başlık; gövde sans. Logodaki `S O B O`
hissi harf aralığından gelir, fontu yaymaktan değil.

**c) Boşluğu tasarım sanmak.** "Minimal marka" bahanesiyle her şey ortalanır
ve ekran bitmemiş görünür.
→ *Kural:* quiet luxury = boşluk değil, **kontrollü kontrast** — çok büyük
başlık + çok küçük etiket, arada hiçbir şey yok.

**d) AI görsel.** Instagram'da "Yapay zeka içeriği" etiketli post mevcut.
Stüdyo sitesinde bu, amatörlüğün en hızlı sinyali — insanlar oraya gerçek
mekânı görmeye gelir.
→ *Gereksinim:* gerçek stüdyo fotoğrafı çekimi.

### 6.6 Tipografi

- **Display/başlık:** Cormorant Garamond (ince serif, geniş tracking)
- **Gövde:** Inter
- İkisi de Türkçe karakter tam desteği (ğ ş ı İ ç ö ü)
- iOS'ta ikisi de bundle edilir; sistem fontuna düşülmez (marka tutarlılığı)
- Dynamic Type desteklenir (`...Scaled` varyantlar — AkorFonts deseni)

Kademeler: `largeTitle · title1 · title2 · title3 · headline · body ·
bodyEmph · callout · caption`

### 6.7 Buton hiyerarşisi — sayfada tek birincil

| Kademe | Biçim | Sobo'da |
|---|---|---|
| **Birincil** | `espresso` dolgu, beyaz metin, min 50pt | **Rezerve Et** — ekranda tek |
| **İkincil** | saydam + `line` 1px kenarlık | İptal Et, Bekleme Listesine Gir |
| **Üçüncül** | **kap yok, kenarlık yok, ikon yok** — `muted`, semibold, tracking +1.2 | "Tümünü gör", "Geçmiş dersler" |

🔴 En sık hata: üçüncül eylemi accent kapsüle koymak — onu birincil kademeye
terfi ettirir ve gerçek birincil eylemle yarışır.

### 6.8 Yarıçap — kademeli

Her şey aynı yarıçapta olursa şablon gibi durur.

```
chip     10    ders tipi filtresi
input    12    form alanı
card     14    ders kartı (en sık)
panel    18    geniş panel, kontrol çubuğu
sheet    24    modal başlığı
hero      0    tam ekran görsel
```

### 6.9 Hareket

AkorLab'in ölçümle türetilmiş kademesi devralınır (uydurma değil):

```
instant   0.12s easeOut     basış geri bildirimi
quick     0.18s easeOut     ikon/rozet değişimi
fast      0.20s easeOut     hızlı giriş/çıkış
standard  0.25s easeInOut   VARSAYILAN
smooth    0.30s easeInOut   panel/sheet içi
settle    spring(0.35, 0.85) liste/kart yerleşmesi
```

Basışta **ölçek (0.96) ve opaklık birlikte** değişir — yalnız ölçek sönük
hissettirir. Bounce yok, bu marka sakin. `reduce-motion` uyumlu.

### 6.10 İkon

- **Tek aile:** SF Symbols (iOS) / Lucide (web). Karıştırma yok.
- **Çizgi + gri** = pasif/etiket · **Dolu + renkli** = aktif/seçili
- **Bölüm başlıklarına ikon YOK** — "Bu Hafta" yanına takvim ikonu sıfır
  bilgi taşır, "her başlığa otomatik simge iliştirilmiş" hissi verir
- **Emoji yok** — platformdan platforma farklı çizilir, tipografiyle
  hizalanmaz, erişilebilirlik katmanında saçma okunur
- Dokunma alanı **≥44pt**, glif 16–20pt olsa bile

### 6.11 Yükleme ve boş durum

- **Spinner değil iskelet** — içeriğin şeklini taklit eden yüzeyler
- **İyimser güncelleme** — rezervasyon butonuna basınca anında boya, hata
  olursa geri al
- **Boş durum** kuru "Kayıt yok" değil: neden boş + gidilecek net eylem
  (örn. "Bu hafta rezervasyonun yok — Program'dan ders seçebilirsin")
- **Haptik** — iOS'ta rezervasyon onayı `.success`, hata `.error`

---

## 7. Ekranlar

### 7.1 iOS uygulaması — 5 sekme

1. **Bugün** — sonraki dersin kartı (geri sayım), kalan ders sayısı, tek
   dokunuşla rezervasyon
2. **Program** — hafta şeridi + gün listesi. Ders kartı üç durumdan biri:
   `4 yer kaldı` / `Son 1 yer` / `Dolu — bekleme listesi`
3. **Ders detayı** — eğitmen, süre, açıklama, katılımcılar (rıza verenler),
   rezerve et
4. **Üyeliğim** — aktif paket, kalan ders, bitiş tarihi, geçmiş dersler,
   kredi tarihçesi
5. **Profil** — bildirim tercihleri, KVKK, stüdyo iletişim

### 7.2 Admin paneli (web) — "DM'i öldürmeyen panel"

Ana ekran = **Bugün**. Bugünün dersleri alt alta, her kartta tek dokunuşla
yoklama. Yanında hızlı işlem çubuğu:

> *DM'den rezervasyon geldi* → üye ara (telefon son 4 hane) → dersi seç →
> **Ekle**. Üç tık, kredi otomatik düşer.

**Bu akışın 5 saniyenin altında kalması projenin başarı çizgisidir.**

Diğer ekranlar: takvim yönetimi (şablon + istisna) · üyeler (arama, paket
tanımlama) · duyuru gönder.

### 7.3 Üye web (mobil-first, PWA)

iOS uygulamasının tam eşdeğeri. Android üyelerin asıl arayüzü.
"Ana Ekrana Ekle" + web push.

### 7.4 Tanıtım sitesi

Hero (gerçek stüdyo fotoğrafı, "Not just a studio. It's a society.") →
Dersler → **Canlı program** → Eğitmenler → Galeri → Paketler →
İletişim/harita/WhatsApp.

Canlı program sayfası hem SEO değeri taşır (yerel aramalar) hem de
kayıt olmaya ikna eden vitrindir.

---

## 8. Yapım sırası

1. **Backend çekirdek** — veri modeli + kredi ledger + kontenjan, testlerle
2. **Admin paneli** — eğitmen sistemi kullanmaya başlar, veri girer
3. **Üye web rezervasyon** — herkes erişir, Android dahil
4. **Tanıtım sitesi**
5. **iOS uygulaması**

Sıra bilinçli: **eğitmen sistemi kullanmadan üyeyi çağırmak boş bir takvime
davet etmektir.**

---

## 9. Açık sorular

1. V1–V9 varsayımları işletmeden teyit edilecek (özellikle **V5** program
   şablonu ve **V7** ödeme)
2. Gerçek stüdyo fotoğrafı çekimi — kim, ne zaman?
3. SMS OTP sağlayıcısı: Netgsm mi İletimerkezi mi? (maliyet/mesaj)
4. Alan adı
5. Stüdyo adresi (harita + yerel SEO için)
