# BTC Mining Simulator

**Tagline:** Build your mining empire.

Idle simulator: start with a small rig and grow into a mega mining farm. Mining continues in the background (idle), daily rewards, shop with one-time products and premium subscriptions, leaderboard and profile with Firebase Auth. Data is stored locally and synced to **Firebase Realtime Database**.

## Features

- **Mining:** Laptop → GPU rig → Mining rack → Warehouse farm → Mega facility (increasing BTC/min)
- **Idle:** Miners keep producing when the app is closed; see earnings when you return
- **Shop:** Buy rigs with BTC; **one-time products** (Starter Pack, Satoshi Pack, 2x Boost, Mega Pack); **Premium plans** (Monthly/Yearly) — all stored in Firebase
- **Leaderboard:** Global ranking from Firebase Realtime Database (by BTC balance)
- **Daily rewards:** 7-day cycle (coins, GPU upgrade, rare miner); state synced to Firebase
- **Auth:** Anonymous (guest), Google Sign-In, profile, logout, link guest → Google

## Firebase setup

1. Create a project at [Firebase Console](https://console.firebase.google.com).
2. Add Android and iOS apps (bundle ID: `com.example.btc_sim`).
3. Enable **Authentication** → Sign-in method: **Anonymous** and **Google**.
4. Enable **Realtime Database** and set rules (or deploy `database.rules.json`):
   ```bash
   firebase deploy --only database
   ```
   Rules in `database.rules.json`: users can read/write their own `users/{uid}` and their own leaderboard entry; leaderboard list is readable by all.
5. Run FlutterFire CLI (or use existing `lib/firebase_options.dart` if generated from your config):
   ```bash
   dart pub global activate flutterfire_cli
   dart run flutterfire configure
   ```
6. **iOS:** In `ios/Runner/Info.plist`, set `CFBundleURLSchemes` to your reversed client ID from `GoogleService-Info.plist`.

## In-app purchases (Play Store / App Store)

One-time products and premium subscriptions are bought via the store; rewards are applied in-app and **saved to Firebase Realtime Database** (`users/{uid}/purchases/`).

1. **Google Play Console:** Create in-app products and subscriptions with these **exact** IDs:
   - One-time: `starter_pack`, `satoshi_pack`, `mega_pack`, `boost_2x_1h`
   - Subscriptions: `premium_monthly`, `premium_yearly`
2. **App Store Connect:** Create the same product IDs under your app’s In-App Purchases and Subscriptions.
3. **Shop:** “Buy” on real-money products opens the store; after a successful purchase the app applies the reward (BTC, rigs, boost, premium) and writes to Firebase. **Restore** loads previous purchases from the store and reapplies them (and syncs to Firebase).

## Run

```bash
flutter pub get
flutter run
```

## Screens

- **Login:** Google / Guest
- **Dashboard:** BTC balance, mining rate, idle earnings, sync indicator, Boost/Premium badges
- **Mining Farm:** List of rigs and counts
- **Shop:** Tabs — **Rigs** (buy with BTC), **One-time** (packs, 2x boost), **Premium** (subscriptions, stored in Firebase)
- **Leaderboard:** Live from Firebase, pull-to-refresh
- **Rewards:** Daily reward (7-day cycle), state in Firebase
- **Profile:** Avatar, name, link Google, Sign out
