
# 🌱 EcoPay

**EcoPay** is a sustainability-focused plugin designed to integrate directly into e-wallets like **Touch ‘n Go (TnG)**. Built with Flutter, EcoPay helps Gen Z users in Malaysia track their carbon footprint, make greener choices, and donate to causes — all while using the payment apps they already love.

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
EcoPay bridges that gap — helping Gen Z act on their values, daily.

---

## 🚀 Features

| Feature | Description |
|--------|-------------|
| 💨 Carbon Estimator | Estimates CO₂ per transaction via [Climatiq API](https://www.climatiq.io/) |
| 🎁 Rewards & Gamification | Leaderboards, tree growth visuals, XP badges, and more |
| 💬 AI Assistant | EcoBot provides answers, tips, and suggestions in multiple languages |
| 🪙 Round-Up Donations | Donates spare change to verified NGOs via TnG |
| 📊 Impact Dashboard | View monthly CO₂ saved, donations made, and progress |
| 🌏 Multi-language & Low-data Mode | BM, English, Mandarin; optimized for rural areas |

---

## 🧠 Architecture

```mermaid
flowchart TD
  subgraph A["📱 User Device"]
    A1[👤 User] --> A2["TnG eWallet App"] --> A3["EcoPay SDK"]
  end

  subgraph B["💡 EcoPay SDK"]
    A3 --> B1["CO₂ Estimator"]
    A3 --> B2["Gamification UI"]
    A3 --> B3["Donation Prompt"]
    A3 --> B4["EcoBot Chat"]
    A3 --> B5["API Client"]
  end

  subgraph C["☁️ Backend"]
    B5 --> C1["Auth Service"]
    B5 --> C2["Carbon Engine"]
    B5 --> C3["Gamification Engine"]
    B5 --> C4["Donation Handler"]
    B5 --> C5["Notification Engine"]
  end

  subgraph D["🗄️ Databases"]
    C1 --> D1["User DB"]
    C2 --> D2["Metrics DB"]
    C3 --> D2
    C4 --> D2
  end

  subgraph E["🔌 Third-Party APIs"]
    C2 --> E1["Climatiq API"]
    C4 --> E2["TnG Payment API"]
    C5 --> E3["Push Notifications (e.g., Firebase)"]
  end
```

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
  <img src="assets/readme_img/dashboard3.png" width="300" alt="Dashboard View 2"/>
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

### MyContribution page

<p float="left">
  <img src="assets/readme_img/contribution1.png" width="300" alt="Success Screen"/>
    <img src="assets/readme_img/contribution2.png" width="300" alt="Success Screen"/>
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
- Firebase project (for push notifications, if used)
- Climatiq API key ([get it here](https://www.climatiq.io/))

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
│   │   └── database_helper.dart
│   ├── main.dart
│   ├── models
│   │   ├── balance.dart
│   │   └── transaction.dart
│   ├── screens
│   │   ├── payment_confirmation_screen.dart
│   │   └── touch_n_go_homepage.dart
│   ├── utils
│   │   └── duitnow_qr_parser.dart
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

EcoPay turns every transaction into a tiny step for a better planet — no extra effort required.
