# 🛠️ SyloNow Partner — B2B Vendor & Service Dispatch Mobile Platform

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Backend](https://img.shields.io/badge/Backend-Supabase_PostgreSQL-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com)
[![Push](https://img.shields.io/badge/Notifications-OneSignal-E53935?style=for-the-badge&logo=onesignal&logoColor=white)](https://onesignal.com)
[![Platform](https://img.shields.io/badge/Platform-Android_%7C_iOS-3DDC84?style=for-the-badge)](https://flutter.dev)

> **SyloNow Partner** is a dedicated enterprise B2B mobile application designed for event vendors, decoration teams, and service specialists. It powers real-time job dispatching, live order status progression, photo verification of completed work, and vendor earnings management.

---

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                       VENDOR MOBILE UI                      │
│  • Order Dispatch Feed & Live Notification Banner           │
│  • Job Action Controller (Accept / Decline / In-Transit)    │
│  • Camera Proof-of-Work Capture (Photo Verification)        │
│  • Vendor Earnings Dashboard & Performance Analytics        │
├─────────────────────────────────────────────────────────────┤
│                    REAL-TIME SYNC LAYER                     │
│  • Supabase Realtime Channels (Instant Dispatch Listeners)  │
│  • OneSignal Push Notification SDK (Background Job Alerts)  │
│  • Device Geolocation Reporting                             │
├─────────────────────────────────────────────────────────────┤
│                     DATA & BACKEND CORE                     │
│  • Supabase PostgreSQL Database with Row-Level Security     │
│  • Edge Functions for SMS & Vendor State Transitions        │
│  • Cloud Storage for Delivery Verification Photos           │
└─────────────────────────────────────────────────────────────┘
```

---

## ✨ Core Features

- ⚡ **Instant Dispatch Notifications:** Real-time job broadcasting powered by OneSignal and Supabase database triggers when customers place new event orders.
- 📋 **Order Lifecycle State Machine:** Seamless 4-stage job progression:
  1. `Assigned` ➔ 2. `In-Transit` ➔ 3. `In-Progress` ➔ 4. `Completed`
- 📸 **Photo Verification on Completion:** Integrated camera capture allowing decor teams to upload before/after photos directly to Supabase Storage before marking jobs complete.
- 💰 **Earnings & Payout Analytics:** Real-time summary of completed orders, pending payouts, commission breakdowns, and customer reviews.
- 🔐 **Secure Role-Based Access:** Enforces strict vendor authorization and isolated profile data via PostgreSQL Row-Level Security (RLS).

---

## 📂 Directory Structure

```
lib/
├── core/                  # Network configuration, constants, theme, error handlers
├── models/                # Vendor profile, order request, earnings data models
├── screens/               # Dashboard, orders, active job, earnings, profile screens
├── services/              # Supabase API, OneSignal push notifications, location
└── widgets/               # Reusable vendor cards, status badges, camera modals
```

---

## 🚀 Quick Setup & Installation

### 1. Clone the Repository
```bash
git clone https://github.com/sangamesh5588/sylonow_vendor_app.git
cd sylonow_vendor_app
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Configure Environment
Copy `.env.example` to `.env`:
```bash
cp .env.example .env
```
```ini
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
ONESIGNAL_APP_ID=your-onesignal-app-id
```

### 4. Run Application
```bash
flutter run
```

---

## 🛡️ License
Copyright © 2026 Sangamesh K. All rights reserved.