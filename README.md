# Money Control 💰

A Cross Platform Flutter app to control and track your money, expenses, and transactions with ease.

## ✨ New Feature: Add Transaction Widget

**Just Added!** A comprehensive widget for adding transactions and viewing your current balance in real-time.

### Quick Start

```dart
import 'package:money_control/Components/add_transaction_widget.dart';

// Use in any screen
AddTransactionWidget(transactionType: 'send')
```

**Features:**
- ✅ Real-time balance calculation
- ✅ Add send/receive transactions
- ✅ Input validation
- ✅ Balance verification
- ✅ Firebase integration
- ✅ Light/Dark theme support

📚 **[Read Quick Start Guide](QUICK_START.md)**

📖 **[Full Documentation](docs/ADD_TRANSACTION_WIDGET_GUIDE.md)**

🎨 **[Visual Features Guide](docs/WIDGET_FEATURES.md)**

---

## 🚀 Getting Started

This project is a Flutter application for personal finance management.

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK
- Android Studio / VS Code
- Firebase account (for backend)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/justaman045/Money_Control.git
   cd Money_Control
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Set up Firebase:**
   - Create a Firebase project
   - Add your Android/iOS app to Firebase
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Place them in the respective directories

4. **Run the app:**
   ```bash
   flutter run
   ```

---

## 📱 Downloads

### Latest APK Build

Get the latest built APK from the [Releases](../../releases) page.

**Direct Download:**
- [app-release.apk](https://github.com/justaman045/Money_Control/releases/download/v1.0.30/app-release.apk) - Latest build

**How to Install:**
1. Download the APK file from the releases page
2. Transfer to your Android device
3. Open file manager and tap the APK to install
4. Grant permissions when prompted
5. Enable "Install from Unknown Sources" if needed

---

## 📚 Documentation

- **[Quick Start Guide](QUICK_START.md)** - Get started in 5 minutes
- **[Add Transaction Widget Guide](docs/ADD_TRANSACTION_WIDGET_GUIDE.md)** - Comprehensive widget documentation
- **[Widget Features](docs/WIDGET_FEATURES.md)** - Visual guide and feature descriptions

---

## 🛠️ Project Structure

```
lib/
├── Components/          # Reusable UI components
│   ├── add_transaction_widget.dart
│   ├── balance_card.dart
│   ├── colors.dart
│   └── ...
├── Models/              # Data models
│   ├── transaction.dart
│   ├── user_model.dart
│   └── ...
├── Screens/             # App screens
│   ├── add_transaction_screen.dart
│   └── ...
├── data/                # Data management
└── main.dart            # App entry point
```

---

## 🎯 Features

### Current Features
- ✅ User authentication (Firebase Auth)
- ✅ Transaction management (send/receive)
- ✅ Real-time balance tracking
- ✅ Transaction history
- ✅ Category-based organization
- ✅ Light/Dark theme support
- ✅ Cross-platform (Android, iOS, Web)
- ✅ Cloud sync (Firestore)
- ✅ Offline support

### Upcoming Features
- 🔄 Recurring transactions
- 🔄 Budget management
- 🔄 Expense analytics
- 🔄 Receipt scanning (OCR)
- 🔄 Multi-currency support
- 🔄 Export to CSV/PDF
- 🔄 Bill reminders
- 🔄 Spending predictions

---

## 💻 Tech Stack

- **Framework:** Flutter
- **Language:** Dart
- **Backend:** Firebase
  - Authentication
  - Cloud Firestore
  - Cloud Storage
  - Cloud Functions
- **State Management:** Provider / Riverpod
- **UI:** Material Design 3
- **Responsive Design:** flutter_screenutil

---

## 👥 Contributing

Contributions are welcome! Here's how you can help:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Development Guidelines

- Follow the existing code style
- Write clear commit messages
- Add tests for new features
- Update documentation as needed
- Test on multiple devices/platforms

---

## 🐛 Known Issues

- [ ] Balance calculation may be slow with many transactions (optimization in progress)
- [ ] Offline mode needs improvement
- [ ] Dark theme needs refinement in some areas

**Report Issues:** [GitHub Issues](https://github.com/justaman045/Money_Control/issues)

---

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

## 📧 Contact

**Developer:** Aman Kumar

**Email:** coderaman07@gmail.com

**GitHub:** [@justaman045](https://github.com/justaman045)

---

## 🚀 Resources

### Flutter Resources
- [Flutter Documentation](https://docs.flutter.dev/)
- [Flutter Cookbook](https://docs.flutter.dev/cookbook)
- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)

### Firebase Resources
- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire](https://firebase.flutter.dev/)

---

## 🌟 Show Your Support

Give a ⭐️ if this project helped you!

---

## 📊 Changelog

### [Unreleased]
- Added comprehensive Add Transaction Widget
- Added real-time balance display
- Improved input validation
- Added documentation

### [v1.0.30] - Latest Release
- Initial public release
- Basic transaction management
- Firebase integration
- Cross-platform support

**Full Changelog:** [View Releases](../../releases)

---

<p align="center">
  Made with ❤️ using Flutter
</p>
