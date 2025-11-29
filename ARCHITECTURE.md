# 🏗 BloodBridge System Architecture

BloodBridge is designed using a modular and scalable architecture that enables real-time emergency alerts and efficient blood donor matching.

---

## 🔧 High Level Architecture

Mobile App (Flutter)
↓
Firebase Authentication
↓
Firestore Database (Donor Information)
↓
SOS Trigger
↓
Custom Notification Server (Vercel)
↓
Firebase Cloud Messaging (HTTP v1)
↓
User Devices (Push Notifications)
---

## 📦 Core Components

| Component | Description |
|-----------|-------------|
| Flutter Mobile App | User interface / donor registration / SOS broadcast |
| Firebase Authentication | Secure login and identity management |
| Firestore Database | Stores donor data and availability |
| Firebase Storage | Profile image storage |
| Custom Vercel Server | API endpoint for sending notification requests |
| Firebase Cloud Messaging | Delivery of push notifications |

---

## 🌐 Data Flow

| Step | Action |
|------|--------|
| 1 | User logs in using Firebase Authentication |
| 2 | Donor registers blood group & availability |
| 3 | Emergency SOS button triggers API call |
| 4 | Vercel server sends request to FCM |
| 5 | FCM notifies eligible donors instantly |
| 6 | Donors respond and contact recipient |

---

## 🧱 Database Structure (Firestore)

donors
└── userId
├── name: string
├── bloodGroup: string
├── location: string
├── phone: string
└── available: boolean

---

## 📈 Scalability Plan

- Add hospital onboarding system
- Enable automated location-based matching with geofencing
- Introduce AI-based prioritization
- Expand nationwide via cluster deployment

---

## 🏁 Conclusion
This architecture enables fast emergency response, modular development, and scalability for national-level expansion.


