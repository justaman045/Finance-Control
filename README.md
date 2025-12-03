# 📱 Money Control – Free vs Pro Feature Guide
*A complete breakdown of everything included in the Money Control app.*

This document is designed for your **README.md** so new users, contributors, and customers clearly understand what the app offers and what upgrades are available in **Money Control Pro**.

---

# 🌟 Overview

Money Control is a modern finance tracking app that helps users record expenses & income, manage categories, analyze spending patterns, and eventually automate everything with AI-powered features like SMS-based auto-transaction detection.

This guide explains:

- ✔ What’s included in the **Free Plan**
- ⭐ What’s unlocked in the **Pro Plan**
- 🚀 Features available now (MVP)
- 🔮 Planned advanced features

---


## Downloads

### Latest APK Build

Get the latest built APK from the [Releases](../../releases) page.

**Direct Download:**
- [app-release.apk](https://github.com/justaman045/Money_Control/releases/download/v1.0.74/app-release.apk

**How to Install:**
1. Download the APK file from the releases page
2. Transfer to your Android device
3. Open file manager and tap the APK to install
4. Grant permissions when prompted

----

# 🆓 Free Tier – Features Included

## ✔ Core Finance Features
- Add income and expenses manually
- Choose transaction type (Send / Receive)
- Add recipient/sender name
- Add notes to transactions
- Pick custom dates for transactions
- Add & manage categories
- **Long-press to delete a category**
- View transaction details
- Edit or delete transactions
- Smooth UI with gradients and dark/light theme

## ✔ Analytics & Balance
- Monthly summary
- Total balance card
- View daily/weekly/monthly totals
- Basic analytics with simple bar charts
- Scrollable detailed transaction list

## ✔ App Experience
- Light mode / Dark mode
- Clean responsive UI (ScreenUtil)
- GetX navigation
- Smooth animations
- Local data caching via Firestore

## ✔ Notifications
- Local reminders to record expenses
- Background worker setup
- Automatic inactivity reminders

## ✔ Sharing & Printing
- Share transaction screenshot
- Print screenshot (PDF print dialog)
- Save image sharing

## ✔ Settings
- Update user profile (name, phone)
- About screen
- Help/FAQ placeholder
- Privacy policy link
- Logout
- Cloud sync (basic)

## ✔ Limits (Free Plan)
- Up to **150 transactions per month**
- Up to **10 categories**
- Basic analytics only
- No export files
- No budgets or alerts

---

# ⭐ Pro Tier – Premium Features

Unlock the full Money Control experience with **Money Control Pro**.

## ✨ Unlimited Everything
- Unlimited transactions
- Unlimited categories
- Lifetime history analytics
- Multi-device prioritization

## 📊 Advanced Analytics
- Full range analytics:
    - Weekly
    - Monthly
    - Quarterly
    - Yearly
- Category breakdown
- Spending insights
- AI-generated spend summaries
- Pattern detection (food, transport, bills, etc.)

## 📁 Export & Reports
- Export **PDF** reports
- Export **CSV** files
- Share monthly statements
- Print official finance summaries

## 🎯 Budgeting Tools
- Create budgets by category
- Smart budgeting suggestions (AI-ready)
- Overspending alerts
- Bill reminders

## 📩 Smart Notifications
- Smart reminders based on past behavior
- Alerts for bill due dates
- Alerts for category overspend

## 🤖 AI-Powered Features
- Automatic transaction categorization
- Auto-suggestions while entering transactions
- AI spending assistant
- AI summary insights (monthly & daily)

## 📱 SMS Auto-Transaction Detection (Major Pro Feature)
- Reads bank SMS (with permission)
- Extracts amount, merchant, time
- Detects sender/receiver
- Predicts category using ML
- Auto-creates transaction
- Shows confirmation popup
- Detects duplicates

## ☁️ Cloud & Backup
- Faster sync
- Multi-device syncing
- Priority data restoration

## 🛠 Priority Support
- Faster support response
- Guaranteed bug fixes
- Feature voting access

---

# 🚀 Future Roadmap Features (Pro)

These are advanced features planned for upcoming releases:

- OCR receipt scanning
- Bank account sync (where legal)
- Family/shared wallets
- Team/business expense mode
- Recurring transactions
- Automatic tax calculation
- Web dashboard for Pro users
- AI financial forecasting
- Smart investment suggestions
- Multi-currency support
- Savings goals tracking

---

# 🪜 MVP (Launched Features)

The current MVP includes:

- Add/Edit/Delete Transactions
- Categories (create/delete)
- Balance calculation
- Monthly analytics
- Dark/Light theme
- Background reminders
- Transaction detail view
- Share/Print
- Beautiful responsive UI
- Smooth animations with GetX
- Firestore backend
- User profile
- Settings
- About screen
- Notifications
- Receipt placeholder (OCR coming soon)

---

# 🧩 App Architecture Overview

**Flutter + Firebase Stack:**
- Flutter (Dart) UI
- GetX navigation + state
- Firebase Auth
- Firestore Database
- Background Worker (WorkManager)
- Local Notifications
- ScreenUtil responsive system
- Printing & SharePlus integration

**Firestore Schema:**
 - users/{email}
   - profile
   - settings
   - categories/{categoryId}
   - transactions/{transactionId}


---

# 📦 Monetization Strategy

**Recommended pricing:**
- **₹249/month** (India)
- **₹1499/year**
- **$3.99–$4.99/month** (Global)
- **$29/year**

---

# 🎯 Summary

Money Control delivers essential finance tracking for free, while offering powerful premium features for Pro users including AI tools, advanced analytics, exports, intelligent automation, and smart alerts.