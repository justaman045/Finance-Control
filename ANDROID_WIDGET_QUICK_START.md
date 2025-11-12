# Android Home Screen Widget - Quick Start 🚀

## What is This?

An **Android home screen widget** that shows your Money Control balance directly on your phone's home screen - no need to open the app!

## Visual Preview

```
┌──────────────────────────────────────┐
│ Money Control              🔄       │
├──────────────────────────────────────┤
│                                      │
│ Available Balance                    │
│ ₹ 5,432.10                          │
│ Updated 10:30 PM                     │
│                                      │
│                                      │
│  ┌────────┐   ┌──────────┐      │
│  │  Send  │   │ Receive  │      │
│  └────────┘   └──────────┘      │
└──────────────────────────────────────┘
```

## Features

✅ Shows your current balance on home screen

✅ Tap Send/Receive to open app directly

✅ Refresh button to update balance

✅ Beautiful gradient design

✅ Auto-updates every 30 minutes

---

## 🛠️ Installation (5 Steps)

### Step 1: Run This Command

```bash
flutter pub get
```

### Step 2: Create These Files

You need to manually create XML files in Android Studio:

#### Create Folder Structure
```
android/app/src/main/res/
├── layout/
│   └── money_control_widget.xml
├── drawable/
│   ├── widget_background.xml
│   ├── button_send_background.xml
│   └── button_receive_background.xml
└── xml/
    └── money_control_widget_info.xml (Already created)
```

📄 **Get all file contents from:** [Full Setup Guide](docs/ANDROID_HOME_WIDGET_SETUP.md)

### Step 3: Create Kotlin Provider

Create: `android/app/src/main/kotlin/com/example/money_control/MoneyControlWidgetProvider.kt`

📄 **Get complete code from:** [Full Setup Guide](docs/ANDROID_HOME_WIDGET_SETUP.md#step-3-create-widget-provider-class)

### Step 4: Update AndroidManifest.xml

Add this inside `<application>` tag in `android/app/src/main/AndroidManifest.xml`:

```xml
<receiver
    android:name=".MoneyControlWidgetProvider"
    android:exported="true">
    <intent-filter>
        <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
        <action android:name="REFRESH_WIDGET" />
    </intent-filter>
    <meta-data
        android:name="android.appwidget.provider"
        android:resource="@xml/money_control_widget_info" />
</receiver>
```

### Step 5: Initialize in main.dart

Update your `main.dart`:

```dart
import 'package:money_control/services/home_widget_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Add this line
  await HomeWidgetService.initialize();
  
  runApp(MyApp());
}
```

---

## 📱 Build and Test

### Build the App

```bash
flutter clean
flutter pub get
flutter build apk --release
flutter install
```

### Add Widget to Home Screen

1. **Long press** on your home screen
2. Tap **"Widgets"**
3. Find **"Money Control"**
4. **Drag to home screen**
5. Done! 🎉

---

## 📝 File Checklist

Make sure you created all these files:

- [ ] `pubspec.yaml` - Updated (done automatically)
- [ ] `android/app/src/main/res/layout/money_control_widget.xml`
- [ ] `android/app/src/main/res/drawable/widget_background.xml`
- [ ] `android/app/src/main/res/drawable/button_send_background.xml`
- [ ] `android/app/src/main/res/drawable/button_receive_background.xml`
- [ ] `android/app/src/main/res/xml/money_control_widget_info.xml` (done)
- [ ] `android/app/src/main/kotlin/.../MoneyControlWidgetProvider.kt`
- [ ] `AndroidManifest.xml` - Updated with receiver
- [ ] `lib/services/home_widget_service.dart` (done)
- [ ] `main.dart` - Updated with initialization

---

## ⚖️ Common Issues

### ❌ Widget Not Showing in Widget Library

**Fix:**
```bash
flutter clean
flutter build apk
# Uninstall app from phone
# Reinstall
flutter install
```

### ❌ Widget Shows "₹ 0.00"

**Fix:**
1. Open the app
2. Log in
3. Add a transaction
4. Widget will auto-update

### ❌ Buttons Don't Work

**Fix:**
- Check `MoneyControlWidgetProvider.kt` has correct code
- Verify `AndroidManifest.xml` has receiver registered
- Rebuild the app

---

## 📚 Need More Help?

📖 **Full Documentation:** [Android Home Widget Setup Guide](docs/ANDROID_HOME_WIDGET_SETUP.md)

💬 **Have Questions?** Create an issue on GitHub

📧 **Contact:** coderaman07@gmail.com

---

## 🎯 What's Included

### Files Created

1. **home_widget_service.dart** - Flutter service for widget management
2. **money_control_widget_info.xml** - Widget configuration
3. **ANDROID_HOME_WIDGET_SETUP.md** - Complete setup guide
4. **pubspec.yaml** - Updated with home_widget package

### What You Need to Create

1. Widget layout XML
2. Background drawable XMLs
3. Kotlin provider class
4. Update AndroidManifest
5. Initialize in main.dart

---

## ⏱️ Estimated Time

- **XML Files Creation**: 10 minutes
- **Kotlin Code**: 5 minutes
- **Configuration**: 5 minutes
- **Testing**: 5 minutes

**Total: ~25 minutes**

---

## 🚀 After Setup

Once your widget is working, you can:

1. **Customize colors** in drawable XMLs
2. **Change update frequency** in widget_info.xml
3. **Add more features** (recent transactions, charts)
4. **Optimize performance** (cache balance)

---

## 🌟 Tips

💡 **Tip 1:** The widget updates every 30 minutes automatically

💡 **Tip 2:** Tap the refresh button for instant updates

💡 **Tip 3:** Widget works even when app is closed

💡 **Tip 4:** You can add multiple widget sizes in the future

---

## 👍 Ready to Start?

1. ✅ Read this quick start
2. ✅ Open [Full Setup Guide](docs/ANDROID_HOME_WIDGET_SETUP.md)
3. ✅ Follow step-by-step instructions
4. ✅ Build and test
5. ✅ Enjoy your home screen widget!

---

**Version:** 1.0.0

**Last Updated:** November 12, 2025

**Made with ❤️ for Money Control**
