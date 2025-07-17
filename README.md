---
title: EcoPay README
---

# 🌱 EcoPay

**EcoPay** is a sustainability-focused plugin designed to integrate directly into e-wallets like **Touch ‘n Go (TnG)**. Built with Flutter, EcoPay helps Gen Z users in Malaysia track their carbon footprint, make greener choices, and donate to causes—all while using the payment apps they already love.

---

## 📌 Challenge Overview

This project was developed for **PayHack25 – Challenge 3: ESG/Sustainability**:

> _How can digital payments be leveraged to seamlessly integrate environmental sustainability and social impact into daily transactions?_

---

## 💡 What is EcoPay?

EcoPay is a Flutter-based module that integrates seamlessly into existing digital wallets. It empowers users to:

- 📉 **See their carbon impact** in real-time per purchase
- 🥕 **Make greener spending choices** with nudges (e.g., Chicken > Beef)
- 🎮 **Get rewarded** through badges, tree-growth, and streaks
- 💸 **Donate easily** via round-up donations to verified causes
- 🤖 **Chat with EcoBot**, an AI assistant for sustainability support

---

## 🎯 Why Gen Z?

- 71% of Malaysian Gen Z use digital wallets
- 66% are willing to pay more for sustainable products
- But 78% feel powerless without tools to take action

EcoPay bridges that gap—helping Gen Z act on their values, daily.

---

## 🚀 Features

| Feature | Description |
|---|---|
| 💨 **Carbon Estimator** | Estimates CO₂ per transaction via local calculations. |
| 🎁 **Rewards & Gamification** | Includes leaderboards, achievements, and challenges to reward sustainable behavior. |
| 🪙 **Round-Up Donations** | Donates spare change to verified NGOs via TnG. |
| 📊 **Impact Dashboard** | View monthly CO₂ saved, donations made, and progress. |
| 🌏 **Local Project Support** | Enables users to support local environmental projects in Malaysia. |
| 📱 **QR Code Payments** | Supports DuitNow QR payments with an integrated scanner. |

---

## 🧠 Architecture

```mermaid
graph TD
    subgraph A["📱 User Device"]
        A1[User] --> A2["TnG eWallet App"];
        A1 --> A2_Future_1["Boost eWallet App (Future)"];
        A1 --> A2_Future_2["GrabPay eWallet App (Future)"];
        A2 --> A3["EcoPay SDK"];
        A2_Future_1 --> A3;
        A2_Future_2 --> A3;
    end

    subgraph B["💡 EcoPay SDK"]
        A3 --> B1["CO₂ Estimator"];
        A3 --> B2["Gamification & UI"];
        A3 --> B3["Donation Prompt"];
        A3 --> B4["QR Scanner"];
        A3 --> B5["API Client (Future)"];
    end

    subgraph C["⚙️ Backend & Database (Local)"]
        B1 --> C1["Environmental Impact Calculator"];
        B2 --> C2["Gamification Helper"];
        B3 --> C3["Database Helper (sqflite)"];
        B4 --> C4["DuitNow QR Parser"];
        C1 --> C3;
        C2 --> C3;
        C4 --> C3;
    end

    subgraph D["☁️ Cloud Backend (Future)"]
        B5 --> D1["User Auth"];
        B5 --> D2["Carbon Engine"];
        B5 --> D3["Gamification Engine"];
        B5 --> D4["Donation Logic"];
        B5 --> D5["Notification Engine"];
    end

    subgraph E["🗄️ Databases (Future)"]
        D1 --> E1["User DB"];
        D2 --> E2["Metrics DB"];
        D3 --> E2;
        D4 --> E2;
    end

    subgraph F["🔌 Third-Party APIs (Future)"]
        D2 --> F1["Climatiq API"];
        D4 --> F2["TnG Payment API"];
        D5 --> F3["Push Notification Service"];
    end
```

---

## 🔩 Modules Overview

### `main.dart`
- **Entry Point**: Initializes the Flutter application and sets up the main theme and routing.

### `screens`
- **UI/UX**: Contains all major user-facing screens, including the EcoPay dashboard, QR scanner, payment confirmation, and leaderboards.

### `helpers`
- **`database_helper.dart`**: Manages the local `sqflite` database, handling all CRUD operations for transactions, users, contributions, and achievements.
- **`gamification_helper.dart`**: Implements the logic for achievements and challenges based on user activity.

### `models`
- **Data Structures**: Defines the data models for `User`, `Transaction`, `Contribution`, `Project`, and other core entities.

### `utils`
- **`duitnow_qr_parser.dart`**: Parses DuitNow QR codes to extract merchant information and other payment details.
- **`environmental_impact_calculator.dart`**: Calculates the carbon footprint and other environmental metrics for each transaction.

### `widgets`
- **Reusable Components**: Includes custom widgets like the `receipt_modal.dart` to maintain a consistent UI across the app.

---

## 📱 Screenshots

---

### 🧭 EcoPay Integration
<p float="left">
  <img src="assets/readme_img/Touchngo.png" width="300" alt="Touch ‘n Go Integration Preview"/>
</p>

---

### 🔷 Dashboard Views
<p float="left">
  <img src="assets/readme_img/dashboard1.png" width="300" alt="Dashboard View 1"/>
  <img src="assets/readme_img/dashboard2.png" width="300" alt="Dashboard View 2"/>
</p>

---

### 🔍 QR Scan Flow
<p float="left">
  <img src="assets/readme_img/scan_qr.png" width="300" alt="Scan QR"/>
  <img src="assets/readme_img/after_scan_qr.png" width="300" alt="Post Scan"/>
  <img src="assets/readme_img/info_qr.png" width="300" alt="QR Info"/>
  <img src="assets/readme_img/info_qr_2.png" width="300" alt="QR Info 2"/>
</p>

---

### ✅ Confirmation & Success
<p float="left">
  <img src="assets/readme_img/success.png" width="300" alt="Success Screen"/>
</p>

---

### 🕓 Transaction History
<p float="left">
  <img src="assets/readme_img/history.png" width="300" alt="History Screen"/>
</p>

## 🛠️ Getting Started

### Prerequisites

- Flutter SDK (`>=3.x`)
- Dart (`>=3.x`)
- Android Studio or VS Code with Flutter extension

### Installation

```bash
git clone https://github.com/your-org/ecopay.git
cd ecopay
flutter pub get
flutter run
```

---

## 📦 Folder Structure

```
📁 Simplified Project Structure (root files + lib + assets):

├── Architecture.md
├── README.md
├── analysis_options.yaml
├── assets
│   ├── animations
│   │   ├── Money growth.json
│   │   ├── Tomato_plant.json
│   │   └── Tree in the wind.json
│   ├── fonts
│   │   └── SpaceMono-Regular.ttf
│   └── images
│       ├── EcoPayIcon.png
│       ├── EcoPayIconremovebg.png
│       ├── malaysia-flag.png
│       └── profile.png
├── generate_tree.py
├── lib
│   ├── helpers
│   │   ├── database_helper.dart
│   │   └── gamification_helper.dart
│   ├── main.dart
│   ├── models
│   │   ├── achievement.dart
│   │   ├── balance.dart
│   │   ├── contribution.dart
│   │   ├── project.dart
│   │   ├── transaction.dart
│   │   └── user.dart
│   ├── screens
│   │   ├── achievements_screen.dart
│   │   ├── challenges_screen.dart
│   │   ├── donation_history_screen.dart
│   │   ├── ecopay_screen.dart
│   │   ├── leaderboard_screen.dart
│   │   ├── local_projects_screen.dart
│   │   ├── my_contribution_screen.dart
│   │   ├── payment_confirmation_screen.dart
│   │   ├── qr_scanner_screen.dart
│   │   ├── touch_n_go_homepage.dart
│   │   └── transaction_history_screen.dart
│   ├── utils
│   │   ├── duitnow_qr_parser.dart
│   │   └── environmental_impact_calculator.dart
│   └── widgets
│       └── receipt_modal.dart
├── pubspec.lock
└── pubspec.yaml
```

---

## 🧪 Future Plans

- [ ] Support multiple wallets (Boost, GrabPay, MAE)
- [ ] Real-time emissions using location and merchant category
- [ ] ESG data marketplace for investors
- [ ] Tree-planting rewards or carbon credit partnerships

---

## 👥 Team

- Aiman – Backend & System Design
- Azri - UI Design & Backend Support
- Hanim - Presenter
- Kamil - Researcher

---

## 📄 License

This project is licensed under the MIT License.

---

## 🌍 Together, Let’s Pay It Green.

EcoPay turns every transaction into a tiny step for a better planet—no extra effort required.
