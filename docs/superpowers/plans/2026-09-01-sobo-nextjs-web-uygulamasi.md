# Sobo Next.js Web Uygulaması (Tanıtım + Üye Web + Admin Paneli) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Sobo Society tanıtım sitesini, üye web rezervasyon ekranlarını ve eğitmenin 5 saniyede DM rezervasyonunu girebileceği admin yönetim panelini kapsayan Next.js 14+ (App Router) uygulamasını oluşturmak.

**Architecture:** App Router yapısıyla ayrılmış 3 ana dizin grubu: `(site)` tanıtım vitrini, `(uye)` mobil-first üye rezervasyon alanı, `(admin)` eğitmen hızlı yönetim paneli. UI bileşenleri Sobo Tasarım Sistemi (Taupe/Ivory palet, Cormorant Garamond / Jost tipografi) ile geliştirilir. API istemcisi FastAPI backend'e bağlanır.

**Tech Stack:** Next.js 14+ (App Router) · React 18/19 · Tailwind CSS · Lucide React · TypeScript

---

## Global Constraints & Design Rules

- **Renk Paleti & Kontrast:** Ivory (`#F7F4EF`) zemin, Ink (`#2B2522`) birincil metin, Espresso (`#6F5647`) dolu butonlar, Sand (`#E9E1D6`) kart zemini, Sage (`#7D8B72`) rezervasyon durumu, Clay (`#B5714E`) ceza/geç iptal. Koyu tema YOK.
- **Tipografi:** Başlıklar Cormorant Garamond (serif, geniş harf aralığı), gövde yazıları Jost (sans-serif). Türkçe büyük harf dönüşümlerinde `toLocaleUpperCase('tr-TR')` kullanılır.
- **Admin Hızlı İşlem:** Admin panelinde DM'den rezervasyon ekleme akışı 3 tıklamadan ve 5 saniyeden kısa sürmelidir.

---

## Dosya Yapısı

```
sobo/
└── frontend/
    ├── package.json
    ├── tailwind.config.ts
    ├── tsconfig.json
    ├── src/
    │   ├── app/
    │   │   ├── layout.tsx            Ana HTML layout & Font yüklemeleri
    │   │   ├── page.tsx              Tanıtım / Landing Page
    │   │   ├── (uye)/
    │   │   │   ├── giris/page.tsx    SMS OTP Giriş ekranı
    │   │   │   ├── rezervasyon/page.tsx  Üye Web Rezervasyon (Hafta/Gün şeridi, bakiye, rezerve et)
    │   │   │   └── hesabim/page.tsx  Üye paket ve geçmiş ders takibi
    │   │   └── (admin)/
    │   │       ├── admin/today/page.tsx    Eğitmen "5 Saniyelik Panel" (Bugünün dersleri & yoklama)
    │   │       ├── admin/members/page.tsx  Üye arama & paket tanımlama
    │   │       └── admin/schedule/page.tsx Şablon & ders türetme
    │   ├── components/
    │   │   ├── ui/                   Sobo Tasarım Sistemi bileşenleri (Button, Input, Card, Badge, Modal)
    │   │   ├── site/                 Tanıtım sitesi modülleri (Hero, LiveSchedule, Packages, Gallery)
    │   │   ├── uye/                  Üye rezervasyon kartları ve OTP formu
    │   │   └── admin/                Hızlı kayıt çubuğu, yoklama kartı, üye paket atama
    │   └── lib/
    │       ├── api.ts                FastAPI backend HTTP client (Fetch + JWT)
    │       ├── auth.ts               Auth state ve token yönetimi
    │       └── utils.ts              Türkçe büyük harf ve tarih biçimlendirme araçları
    └── tests/                        UI bileşen ve API entegrasyon testleri
```

---

### Task 1: Next.js Proje İskeleti, Tailwind & Design System Setup

**Files:**
- Create: `frontend/package.json`
- Create: `frontend/tailwind.config.ts`
- Create: `frontend/src/app/layout.tsx`
- Create: `frontend/src/lib/utils.ts`
- Create: `frontend/src/components/ui/button.tsx`
- Create: `frontend/src/components/ui/card.tsx`
- Create: `frontend/src/components/ui/badge.tsx`

- [ ] **Step 1: package.json ve Tailwind konfigürasyonunu oluştur**

`frontend/package.json`:
```json
{
  "name": "sobo-frontend",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint"
  },
  "dependencies": {
    "next": "^14.2.0",
    "react": "^18.3.0",
    "react-dom": "^18.3.0",
    "lucide-react": "^0.378.0",
    "clsx": "^2.1.1",
    "tailwind-merge": "^2.3.0"
  },
  "devDependencies": {
    "@types/node": "^20.12.0",
    "@types/react": "^18.3.0",
    "@types/react-dom": "^18.3.0",
    "autoprefixer": "^10.4.19",
    "postcss": "^8.4.38",
    "tailwindcss": "^3.4.3",
    "typescript": "^5.4.5"
  }
}
```

`frontend/tailwind.config.ts`: Sobo renklerini (`ink`, `secondary`, `muted`, `mocha`, `espresso`, `sand`, `ivory`, `line`, `sage`, `clay`) ve yarıçap kademelerini tanımla.

- [ ] **Step 2: Utility ve Türkçe büyük harf dönüştürücüsünü yaz (`frontend/src/lib/utils.ts`)**

```python
export function buyukHarf(metin: string): string {
  return metin.toLocaleUpperCase("tr-TR");
}
```

- [ ] **Step 3: Sobo UI Buton ve Kart bileşenlerini oluştur (`frontend/src/components/ui/button.tsx`, `card.tsx`)**

- [ ] **Step 4: Projenin derlendiğini ve paketlerin kurulduğunu doğrula**

---

### Task 2: API İstemcisi & Auth Yönetimi

**Files:**
- Create: `frontend/src/lib/api.ts`
- Create: `frontend/src/lib/auth.ts`
- Create: `frontend/src/app/(uye)/giris/page.tsx`
- Create: `frontend/src/components/uye/otp-form.tsx`

- [ ] **Step 1: API Client ve Fetch Wrapper yaz (`frontend/src/lib/api.ts`)**

FastAPI backend'e (`http://localhost:8000/api/v1`) istek atan, JWT token başlığını ekleyen ve domain hatalarını yakalayan API istemcisi.

- [ ] **Step 2: Auth State & Token depolama yaz (`frontend/src/lib/auth.ts`)**

- [ ] **Step 3: SMS OTP Giriş Ekranı ve Formunu yaz (`frontend/src/app/(uye)/giris/page.tsx`)**

Telefon gir -> OTP Al -> 6 Haneli OTP Kodunu gir -> Token Kaydet & Yönlendir.

---

### Task 3: Üye Web Rezervasyon Ekranı (Mobil-First & PWA)

**Files:**
- Create: `frontend/src/app/(uye)/rezervasyon/page.tsx`
- Create: `frontend/src/app/(uye)/hesabim/page.tsx`
- Create: `frontend/src/components/uye/session-card.tsx`
- Create: `frontend/src/components/uye/credit-badge.tsx`

- [ ] **Step 1: Ders Kartı Bileşeni (`frontend/src/components/uye/session-card.tsx`)**

Dersin durumu (`4 yer kaldı`, `Son 1 yer`, `Dolu — Bekleme Listesi`), eğitmen, saat ve Rezerve Et / İptal Et / Sıraya Gir butonları.

- [ ] **Step 2: Üye Rezervasyon Sayfası (`frontend/src/app/(uye)/rezervasyon/page.tsx`)**

Hafta şeridi (gün seçimi), derslerin listelenmesi, bakiye rozeti ve canlı rezervasyon işlemleri.

- [ ] **Step 3: Üyeliğim & Ders Geçmişi Sayfası (`frontend/src/app/(uye)/hesabim/page.tsx`)**

Aktif paket bilgisi, kalan kredi sayısı, geçmiş ders katılım durumu (`attended` / `no_show`).

---

### Task 4: Admin Paneli — "DM'i Öldürmeyen 5 Saniyelik Panel"

**Files:**
- Create: `frontend/src/app/(admin)/admin/today/page.tsx`
- Create: `frontend/src/components/admin/quick-booking-sidebar.tsx`
- Create: `frontend/src/components/admin/today-session-card.tsx`
- Create: `frontend/src/app/(admin)/admin/members/page.tsx`
- Create: `frontend/src/app/(admin)/admin/schedule/page.tsx`

- [ ] **Step 1: Hızlı Kayıt Sağ Çubuğu (`frontend/src/components/admin/quick-booking-sidebar.tsx`)**

Eğitmenin DM'den rezervasyon geldiğinde 5 saniyede üye telefonunu girip derse 1 tıkla ekleyebildiği panel bileşeni.

- [ ] **Step 2: Bugünkü Dersler ve Yoklama Ekranı (`frontend/src/app/(admin)/admin/today/page.tsx`)**

Bugünün ders kartları, her kart altında katılan/gelmeyen kutucukları ve "Yoklamayı Kaydet" butonu.

- [ ] **Step 3: Üye Yönetimi & Paket Tanımlama Sayfası (`frontend/src/app/(admin)/admin/members/page.tsx`)**

- [ ] **Step 4: Şablon & Ders Türetme Sayfası (`frontend/src/app/(admin)/admin/schedule/page.tsx`)**

---

### Task 5: Tanıtım (Landing) Sitesi

**Files:**
- Create: `frontend/src/app/page.tsx`
- Create: `frontend/src/components/site/hero.tsx`
- Create: `frontend/src/components/site/live-schedule.tsx`
- Create: `frontend/src/components/site/packages.tsx`

- [ ] **Step 1: Hero, Canlı Program ve Paket Vitrin bileşenlerini yaz**

"Not just a studio. It's a society." başlığı, canlı haftalık ders programı vitrini, paket ücretleri ve konum/harita bilgisi.

- [ ] **Step 2: Frontend Build Kontrolü (`npm run build`)**

Build hatası olmadığını ve tüm sayfaların statik/dinamik derlendiğini doğrula.
