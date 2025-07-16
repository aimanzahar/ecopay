```mermaid
flowchart TD
  %% User Device Layer
  subgraph A["📱 User Device"]
    direction TB
    A1[👤 User]
    A2["TnG eWallet App"]
    A3["EcoPay SDK"]
    A1 -->|"Launch Wallet"| A2
    A2 -->|"Triggers Payment"| A3
  end

  %% EcoPay SDK Modules
  subgraph B["💡 EcoPay SDK (Frontend Modules)"]
    direction LR
    B1["CO₂ Estimator\n(Local or Cached)"]
    B2["UI Display\n(Impact Tags, Tree, Badges)"]
    B3["Donation Prompt\n(Round-Up Overlay)"]
    B4["Gamification Logic\n(Progress, Streaks)"]
    B5["AI Chatbot\n(Eco Help Assistant)"]
    B6["API Client\n(Sync to Backend)"]
    
    A3 --> B1
    A3 --> B2
    A3 --> B3
    A3 --> B4
    A3 --> B5
    A3 --> B6
  end

  %% Backend Core
  subgraph C["☁️ EcoPay Backend (Cloud Services)"]
    direction TB
    C1["User Auth & Session Manager"]
    C2["Carbon Engine\n(Backend Calculator, History)"]
    C3["Gamification Engine\n(Streaks, Leaderboards)"]
    C4["Donation Logic\n(Round-Up Handling, Matching)"]
    C5["Notification Engine\n(FOMO Nudges, Rewards)"]

    B6 --> C1
    B6 --> C2
    B6 --> C3
    B6 --> C4
    B6 --> C5
  end

  %% Backend Storage
  subgraph D["🗄️ Databases"]
    D1["User DB\n(Account Info, Settings)"]
    D2["Metrics DB\n(CO₂, Rewards, Donations)"]
    
    C1 --> D1
    C2 --> D2
    C3 --> D2
    C4 --> D2
  end

  %% Third-Party APIs
  subgraph E["🔌 Third-Party Integrations"]
    E1["Climatiq API\n(Carbon Emission Factors)"]
    E2["TnG Payment API\n(Round-Up Donations)"]
    E3["Push Notification Service\n(e.g. Firebase)"]
    
    C2 -->|"Fetch Carbon Data"| E1
    C4 -->|"Execute Donation"| E2
    C5 -->|"Send Alerts"| E3
  end
