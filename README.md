#  BloodBridge — Blood Donation & SOS Emergency Platform

BloodBridge is a mobile application designed to **save lives by enabling fast blood donor matching and emergency SOS broadcasting** within a community.  
Developed for **H4SC / VBYLD 2026**, the project aims to solve real-world delays in accessing blood during emergencies.

---

##  Problem Statement
In many regions, patients and hospitals face **critical delays in securing compatible blood** due to:

- Lack of real-time donor availability information
- No emergency broadcast system for urgent blood needs
- Limited awareness and weak communication channels between donors, NGOs & hospitals

This leads to **preventable deaths**, especially in rural and remote areas.

---

##  Solution
BloodBridge provides an **instant, location-aware blood donor network** that connects verified donors and receivers through:

- Instant SOS broadcast notifications
- Real-time donor registration
- Blood type filtering & availability
- Cross-platform support (Android, iOS & Web)

The system improves emergency response time, reduces panic, and ensures **faster access to lifesaving blood**.

---

##  Core Features

| Feature | Description |
|--------|-------------|
|  SOS Emergency Broadcast | Send immediate alert to all registered donors in selected blood group |
|  Push Notifications | Real-time alerts using custom Vercel notification server |
|  Donor Registration | Register with profile, blood group & contact |
|  Donor Search | Filter by blood type (A+, O-, AB+, etc.) |
|  Location-based Reach | Notify nearest donors |
|  User Profile | Manage donor info & availability |
|  Clean UI | Minimal modern UI built with Flutter |

---

##  Tech Stack

| Technology | Purpose |
|-----------|----------|
| Flutter | Mobile App UI |
| Firebase Auth | Authentication |
| Firestore Database | Donor data storage |
| Firebase Storage | Profile images |
| Vercel Custom Server | SOS notification endpoint |
| Firebase Cloud Messaging (HTTP v1) | Push Notifications |

---


##  System Architecture

```

Mobile App (Flutter)
↓
Firebase Auth → Firestore → Donor database
↓
SOS Trigger (button)
↓
Vercel Notification Server
↓
Firebase Cloud Messaging
↓
User Devices (Push Alerts)
```
---

##  Installation & Setup

```bash
git clone https://github.com/Rindika-9/bloodbridge.git
flutter pub get
flutter run


### Firebase Setup
Add Firebase configuration files:
- android/app/google-services.json
- ios/Runner/GoogleService-Info.plist

---

## 🧪 Firestore Structure Example

donors
└── userId
├── name: string
├── bloodGroup: string
├── phone: string
├── location: string
└── available: boolean
---

## 📄 License
MIT License

---

##  Contact
Developed by **TheTriad – Mizoram**  
📧 rindikarenthlei2004@gmail.com  

---

##  Vision
**State pilot → National Scale**  
Connecting donors and saving lives across India.



