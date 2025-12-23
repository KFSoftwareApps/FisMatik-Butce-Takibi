# 🧾 FişMatik - Smart Budget Tracking App

**FişMatik** is an AI-powered mobile budget tracking application that simplifies receipt and invoice management. It automatically analyzes and categorizes your expenses, providing personalized savings recommendations.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev/)
[![Supabase](https://img.shields.io/badge/Supabase-Backend-green.svg)](https://supabase.com/)
[![License](https://img.shields.io/badge/License-Proprietary-red.svg)]()

## ✨ Features

### 📸 Smart Receipt Scanning
- **AI-Powered OCR:** Automatic recognition of receipts and invoices using Google ML Kit.
- **Fast Entry:** Upload receipts via camera or gallery.
- **Auto-Categorization:** Intelligent categorization of expenses.

### 💰 Budget Management
- **Monthly Budget Tracking:** Set and track spending limits.
- **Fixed Expenses:** Manage regular payments like rent and utilities.
- **Detailed Reports:** Expense analysis by month, week, and category.

### 🎯 Premium Features

#### Smart Savings Center (Premium/Family)
- **Price History Tracking:** Monitor price changes for frequently purchased products.
- **Merchant Recommendations:** Discover where you can shop for less.
- **Category Filtering:** Search by categories like dairy, bakery, beverages, etc.
- **Real-Time Search:** Find your products instantly.

#### AI Finance Assistant
- **Personalized Recommendations:** Saving tips based on your spending habits.
- **Natural Language Processing:** Ask questions through chat.

### 👥 Family Economy Plan
- **Multi-User:** Share the budget with family members.
- **Collaborative Tracking:** Manage all family expenses in one place.
- **High Limits:** Up to 35 receipt scans and 200 manual entries daily.

## 🚀 Technology Stack

- **Frontend:** Flutter 3.x (Dart)
- **Backend:** Supabase (PostgreSQL, Realtime, Auth, Storage)
- **AI/ML:** 
  - Google ML Kit (OCR)
  - Google Gemini (AI Assistant)
- **State Management:** Provider
- **Localization:** Turkish & English
- **Payments:** RevenueCat (In-App Purchases)

## 📦 Installation

### Requirements
- Flutter SDK 3.x or higher
- Dart SDK 3.x or higher
- Android Studio / VS Code
- Supabase account

### Steps

1. **Clone the repository:**
```bash
git clone https://github.com/KFSoftwareApps/FisMatik-Butce-Takibi.git
cd FisMatik-Butce-Takibi
```

2. **Install dependencies:**
```bash
flutter pub get
```

3. **Create the environment file:**
```bash
# Create a .env file and add your Supabase credentials
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

4. **Run the application:**
```bash
flutter run
```

## 🏗️ Project Structure

```
lib/
├── core/              # Themes, constants, helpers
├── l10n/              # Localization support
├── models/            # Data models
├── providers/         # State management
├── screens/           # UI screens
│   ├── home_screen.dart
│   ├── profile_screen.dart
│   ├── product_list_screen.dart
│   └── ...
├── services/          # Backend services
│   ├── auth_service.dart
│   ├── supabase_database_service.dart
│   └── ...
└── main.dart          # Application entry point
```

## 🔒 Security

- **API Keys:** All sensitive information is stored in the `.env` file and protected by `.gitignore`.
- **Backend Security:** Supabase Row Level Security (RLS) policies.
- **Authentication:** Secure user management via Supabase Auth.
- **Data Encryption:** Sensitive data is stored encrypted.

## 📱 Subscription Tiers

| Feature | Free | Standard | Pro | Family Economy |
|---------|----------|----------|-----|----------------|
| Daily Scans | 1 | 10 | 25 | 35 |
| Manual Entries | 20 | 50 | 100 | 200 |
| AI Assistant | ❌ | ❌ | ✅ | ✅ |
| Smart Price Tracking| ❌ | ❌ | ✅ | ✅ |
| Category Management | ❌ | ✅ | ✅ | ✅ |
| Family Sharing | ❌ | ❌ | ❌ | ✅ |

## 🤝 Contributing

This project is currently private. For suggestions, please open an issue.

## 📄 License

Copyright © 2025 KF Software. All rights reserved.

## 📧 Contact

- **Email:** kfsoftwareapp@gmail.com
- **GitHub:** [@KFSoftwareApps](https://github.com/KFSoftwareApps)

---

**Developer:** KF Software  
**Last Update:** December 2025
