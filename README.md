

<p align="center">
  <img src="https://yiraapp.blob.core.windows.net/appassets/yiraai.png" alt="Yira Clinx Logo" width="120" />
</p>

<h1 align="center">Yira Clinx</h1>

<p align="center">
  <strong>Smart Clinical Practice & Healthcare Management Platform</strong>
</p>

<p align="center">
<a href="https://flutter.dev">
    <img src="https://img.shields.io/badge/Platform-Flutter-02569B?logo=flutter&style=for-the-badge" alt="Flutter" />
</a>
<a href="https://dart.dev">
    <img src="https://img.shields.io/badge/Dart-3.11.4-0175C2?logo=dart&style=for-the-badge" alt="Dart" />
</a>
<a href="https://firebase.google.com">
    <img src="https://img.shields.io/badge/Backend-Firebase-FFCA28?logo=firebase&style=for-the-badge" alt="Firebase" />
</a>
</p>

<br>

# 🏥 About Yira Clinx

**Yira Clinx** is a modern healthcare practice management platform designed for healthcare providers, clinics, hospitals, and healthcare organizations.

The platform streamlines clinical workflows by enabling providers to manage patients, appointments, consultations, health records, care teams, and organizational memberships from a unified interface.

Whether you're an independent practitioner, multi-specialty clinic, hospital network, or healthcare organization, Yira Clinx helps deliver efficient, secure, and patient-centered care.

### Core Objectives

- Improve clinical efficiency
- Enhance patient engagement
- Simplify provider collaboration
- Securely manage health records
- Enable multi-organization healthcare operations

---

# ✨ Key Features

### 👨‍⚕️ Provider Management

- Provider onboarding and profile management
- Specialty and credential management
- Multi-organization memberships
- Multi-hospital affiliations

### 👤 Patient Management

- Patient registration
- Digital health profiles
- Medical history management
- Care team assignments

### 📅 Appointment Scheduling

- Provider availability management
- Appointment booking
- Follow-up scheduling
- Calendar integration

### 🩺 Clinical Consultations

- Encounter documentation
- Clinical notes
- Diagnosis tracking
- Treatment plans

### 📂 Electronic Health Records (EHR)

- Secure patient records
- Visit history
- Clinical documents
- Medical attachments

### 🏢 Organization & Hospital Management

- Multiple organizations support
- Multiple hospitals under organizations
- Membership-based access control
- Role-based permissions

### 🔒 Enterprise Security

- Biometric authentication
- Secure cloud storage
- Role-based access control
- HIPAA-inspired security practices

---

# 🏗️ Architecture

```text
Organization
│
├── Hospital
│   ├── Providers
│   ├── Patients
│   └── Appointments
│
├── Hospital
│   ├── Providers
│   ├── Patients
│   └── Appointments
│
└── Members
    ├── Provider
    └── Patient
```

---

# 🛠️ Tech Stack

| Category         | Package | Purpose |
|------------------|----------|----------|
| Package          | cloud_firestore | Clinical and patient data storage |
| Package          | firebase_auth | Authentication and authorization |
| Package          | firebase_remote_config | Feature management |
| Security         | flutter_secure_storage | Secure token storage |
| Security         | local_auth | Face ID & Fingerprint authentication |
| Security         | google_sign_in | Google OAuth integration |
| State Management | flutter_bloc | Scalable application state management |
| UI/UX            | shimmer | Skeleton loading states |
| UI/UX            | popup_menu | Contextual actions |
| UI/UX            | flutter_launcher_icons | App icon generation |
| Media            | photo_manager | Medical image management |
| Media            | image_picker | Capture and upload images |
| Utilities        | intl | Localization and date formatting |

---

# 👥 User Roles

## Provider

Healthcare professionals who can:

- View assigned patients
- Conduct consultations
- Create clinical notes
- Manage appointments
- Access organizational resources

## Patient

Patients who can:

- View appointments
- Access medical records
- Manage profile information
- Communicate with care teams

## Organization Admin

Administrators who can:

- Manage hospitals
- Manage memberships
- Configure access permissions
- Monitor organizational operations

---

# 🚀 Getting Started

### Clone Repository

```bash
git clone <repository-url>
```

### Install Dependencies

```bash
flutter pub get
```

### Run Application

```bash
flutter run
```

### Generate Code

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

# 📦 Build Release

### Android

```bash
flutter build apk --release
```

### iOS

```bash
flutter build ios --release
```
---

# 🤝 Contributing

1. Create a feature branch
2. Commit changes
3. Open a Pull Request
4. Request code review

---

# 📄 License

Copyright © YIRA HEALTH TECH PRIVATE LIMITED.

All rights reserved.

---

<p align="center">
Developed & Maintained by the <strong>Yira Engineering Team</strong>
</p>