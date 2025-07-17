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
