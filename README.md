# 🧾 FişMatik - Akıllı Bütçe Takip Uygulaması

**FişMatik**, fiş ve fatura yönetimini kolaylaştıran, yapay zeka destekli bir mobil bütçe takip uygulamasıdır. Harcamalarınızı otomatik olarak analiz eder, kategorize eder ve size kişiselleştirilmiş tasarruf önerileri sunar.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev/)
[![Supabase](https://img.shields.io/badge/Supabase-Backend-green.svg)](https://supabase.com/)
[![License](https://img.shields.io/badge/License-Proprietary-red.svg)]()

## ✨ Özellikler

### 📸 Akıllı Fiş Tarama
- **AI Destekli OCR:** Google ML Kit ile fiş ve faturaları otomatik tanıma
- **Hızlı Kayıt:** Kamera veya galeriden fiş yükleme
- **Otomatik Kategorizasyon:** Harcamaları akıllıca kategorilere ayırma

### 💰 Bütçe Yönetimi
- **Aylık Bütçe Takibi:** Harcama limitlerini belirleyin ve takip edin
- **Sabit Giderler:** Kira, faturalar gibi düzenli ödemeleri yönetin
- **Detaylı Raporlar:** Aylık, haftalık ve kategoriye göre harcama analizleri

### 🎯 Premium Özellikler

#### Akıllı Tasarruf Merkezi (Premium/Aile)
- **Fiyat Geçmişi Takibi:** Sık aldığınız ürünlerin fiyat değişimlerini izleyin
- **Market Önerileri:** Hangi markette daha ucuz alışveriş yapabileceğinizi öğrenin
- **Kategori Filtreleme:** Süt ürünleri, fırın, içecek gibi kategorilere göre arama
- **Gerçek Zamanlı Arama:** Ürünlerinizi anında bulun

#### AI Finans Asistanı
- **Kişiselleştirilmiş Öneriler:** Harcama alışkanlıklarınıza göre tasarruf tavsiyeleri
- **Doğal Dil İşleme:** Sorularınızı sohbet ederek sorun

### 👥 Aile Ekonomisi Planı
- **Çoklu Kullanıcı:** Aile üyeleriyle bütçeyi paylaşın
- **Ortak Harcama Takibi:** Tüm aile harcamalarını tek yerden yönetin
- **Yüksek Limitler:** Günlük 35 fiş tarama, 200 manuel giriş

## 🚀 Teknoloji Stack

- **Frontend:** Flutter 3.x (Dart)
- **Backend:** Supabase (PostgreSQL, Realtime, Auth, Storage)
- **AI/ML:** 
  - Google ML Kit (OCR)
  - Google Gemini (AI Asistan)
- **State Management:** Provider
- **Localization:** Turkish & English
- **Payments:** RevenueCat (In-App Purchases)

## 📦 Kurulum

### Gereksinimler
- Flutter SDK 3.x veya üzeri
- Dart SDK 3.x veya üzeri
- Android Studio / VS Code
- Supabase hesabı

### Adımlar

1. **Repository'yi klonlayın:**
```bash
git clone https://github.com/KFSoftwareApps/FisMatik-Butce-Takibi.git
cd FisMatik-Butce-Takibi
```

2. **Bağımlılıkları yükleyin:**
```bash
flutter pub get
```

3. **Environment dosyasını oluşturun:**
```bash
# .env dosyası oluşturun ve Supabase bilgilerinizi ekleyin
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

4. **Uygulamayı çalıştırın:**
```bash
flutter run
```

## 🏗️ Proje Yapısı

```
lib/
├── core/              # Tema, sabitler, yardımcı sınıflar
├── l10n/              # Çoklu dil desteği
├── models/            # Veri modelleri
├── providers/         # State management
├── screens/           # UI ekranları
│   ├── home_screen.dart
│   ├── profile_screen.dart
│   ├── product_list_screen.dart
│   └── ...
├── services/          # Backend servisleri
│   ├── auth_service.dart
│   ├── supabase_database_service.dart
│   └── ...
└── main.dart          # Uygulama giriş noktası
```

## 🔒 Güvenlik

- **API Anahtarları:** Tüm hassas bilgiler `.env` dosyasında saklanır ve `.gitignore` ile korunur
- **Backend Security:** Supabase Row Level Security (RLS) politikaları
- **Authentication:** Supabase Auth ile güvenli kullanıcı yönetimi
- **Data Encryption:** Hassas veriler şifreli olarak saklanır

## 📱 Üyelik Seviyeleri

| Özellik | Ücretsiz | Standart | Pro | Aile Ekonomisi |
|---------|----------|----------|-----|----------------|
| Günlük Fiş Tarama | 1 | 10 | 25 | 35 |
| Manuel Giriş | 20 | 50 | 100 | 200 |
| AI Asistan | ❌ | ❌ | ✅ | ✅ |
| Akıllı Fiyat Takibi | ❌ | ❌ | ✅ | ✅ |
| Kategori Yönetimi | ❌ | ✅ | ✅ | ✅ |
| Aile Paylaşımı | ❌ | ❌ | ❌ | ✅ |

## 🤝 Katkıda Bulunma

Bu proje şu anda kapalı kaynak kodludur. Önerileriniz için lütfen issue açın.

## 📄 Lisans

Copyright © 2025 KF Software. Tüm hakları saklıdır.

## 📧 İletişim

- **Email:** kfsoftwareapp@gmail.com
- **GitHub:** [@KFSoftwareApps](https://github.com/KFSoftwareApps)

---

**Geliştirici:** KF Software  
**Son Güncelleme:** Aralık 2025
