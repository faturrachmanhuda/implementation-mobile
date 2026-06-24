<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" />
  <img src="https://img.shields.io/badge/Django-092E20?style=for-the-badge&logo=django&logoColor=white" />
  <img src="https://img.shields.io/badge/REST_API-FF6F00?style=for-the-badge&logo=fastapi&logoColor=white" />
</p>

# 🚀 Implementation — Mobile

> **Subsistem Deployment, Monitoring, & Pemeliharaan Model AI**
> 
> Bagian dari ekosistem **Intelligence Engineerings** — Platform Terintegrasi untuk Siklus Hidup Pengembangan Kecerdasan Buatan.

---

## 📖 Tentang Proyek

**Intelligence Engineerings** adalah sebuah platform terintegrasi yang dirancang untuk mendukung seluruh siklus hidup (*lifecycle*) pengembangan proyek berbasis kecerdasan buatan (AI). Platform ini dikembangkan sebagai bagian dari mata kuliah **Praktikum Rekayasa Perangkat Lunak** di **Universitas Trisakti**, dengan tujuan memberikan pengalaman langsung kepada mahasiswa dalam membangun sistem perangkat lunak berskala besar yang saling terintegrasi.

Platform ini terdiri dari **5 subsistem** yang masing-masing menangani fase berbeda dalam *lifecycle* pengembangan AI:

| # | Subsistem | Deskripsi |
|---|-----------|-----------|
| 1 | **Intelligence Engineering** | Perencanaan & perancangan blueprint proyek AI |
| 2 | **Project Management** | Manajemen proyek, tugas, dan timeline |
| 3 | **Intelligence Creation** | Pembuatan & pelatihan model machine learning |
| 4 | **Dataset Management** | Pengelolaan dataset dan distribusi data |
| 5 | **Implementation** | Deployment, monitoring, dan pemeliharaan model AI |

Aplikasi mobile ini merupakan **companion app** untuk subsistem **Implementation**, yang memungkinkan pengguna untuk men-deploy model AI, mencatat log implementasi, memantau performa & environment, serta mengelola maintenance notes langsung dari perangkat mobile.

---

## ✨ Fitur Utama

- 📊 **Implementation Dashboard** — Overview seluruh proyek implementasi dan statistik
- 📝 **Implementation Logging** — Catat log aktivitas deployment dengan foto dokumentasi
- 🔄 **Model Transaction Logging** — Rekam transaksi penggunaan model AI di lapangan
- 🌡️ **Environment Monitoring** — Pantau kondisi lingkungan deployment (suhu, latensi, uptime)
- 📈 **Performance Monitoring** — Monitor metrik performa model secara real-time
- 🔧 **Maintenance Notes** — Kelola catatan pemeliharaan dengan seleksi fungsi/fitur spesifik
- 🔗 **Cross-System Integration** — Sinkronisasi otomatis dengan Intelligence Creation & Project Management
- 📱 **Responsive Design** — UI modern dengan Material Design 3

---

## 🛠️ Tech Stack

| Teknologi | Versi | Keterangan |
|-----------|-------|------------|
| Flutter | 3.x | Framework UI cross-platform |
| Dart | 3.x | Bahasa pemrograman |
| Provider | Latest | State management |
| HTTP | Latest | REST API communication |
| Django REST API | 6.x | Backend server |

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (>= 3.0.0)
- [Android Studio](https://developer.android.com/studio) atau [VS Code](https://code.visualstudio.com/)
- Android Emulator atau physical device

### Installation

```bash
# Clone repository
git clone https://github.com/faturrachmanhuda/implementation-mobile.git

# Masuk ke direktori proyek
cd implementation-mobile

# Install dependencies
flutter pub get

# Jalankan aplikasi
flutter run
```

### Konfigurasi API

Sesuaikan base URL API di `lib/services/api_client.dart`:
```dart
static const String baseUrl = 'http://38.47.94.194/tif2/implementation';
```

---

## 📁 Struktur Proyek

```
lib/
├── main.dart                              # Entry point
├── app/
│   └── app.dart                           # App configuration
├── models/                                # Data models
│   ├── project.dart                       # Model proyek
│   ├── implementation_log.dart            # Log implementasi
│   ├── model_transaction.dart             # Transaksi model
│   ├── environment_record.dart            # Record lingkungan
│   ├── performance_record.dart            # Record performa
│   └── maintenance_note.dart              # Catatan pemeliharaan
├── services/                              # API & business logic
│   ├── api_client.dart                    # HTTP client & API calls
│   └── app_session.dart                   # Session management
├── viewmodels/                            # State management (MVVM)
│   └── counter_view_model.dart
└── views/                                 # UI screens
    ├── halaman_awal.dart                  # Landing page
    ├── home_view.dart                     # Home dashboard
    ├── login_dan_buat_akun_page.dart      # Authentication
    ├── project_seleksi.dart               # Project selection
    ├── fitur_seleksi.dart                 # Feature selection
    ├── implementation_log_page.dart       # Logging page
    ├── model_transaction_logging_page.dart # Transaction logging
    ├── environment_monitoring_page.dart   # Environment monitor
    ├── performance_monitoring_page.dart   # Performance monitor
    ├── maintenance_notes_page.dart        # Maintenance management
    └── profil_page.dart                   # User profile
```

---

## 📚 Dokumentasi

| Dokumen | Link |
|---------|------|
| 📘 User Guide | [Download PDF](https://drive.google.com/file/d/1OphU_laj4WWgASZMBsMbChTrsojWoOR9/view?usp=sharing) |
| 📐 UML Diagrams (APPL) | [Download PDF](https://drive.google.com/file/d/19c_ERPAOsVxXoOy-gELkrpGIOFlaaTSB/view?usp=sharing) |
| 🎨 Figma Design — Mobile | [Open in Figma](https://www.figma.com/design/zKUS4e3lUGRH79vC3QCB3F/Untitled?t=XhDzFoZpDXPI7RqJ-1) |
| 🎨 Figma Design — Web | [Open in Figma](https://www.figma.com/design/x1Ns3TN6ywOv4ZOUFr4GGf/WEB---Implementation-Kelompok-1?node-id=0-1&t=n2B13ykK5ef3KylD-1) |
| 🌐 Web Demo | [Open Web App](http://38.47.94.194/tif2/implementation/) |

> **User Guide** berisi panduan lengkap penggunaan aplikasi, termasuk langkah-langkah deployment model, monitoring performa, dan troubleshooting umum.
>
> **UML Diagrams (APPL)** berisi dokumentasi arsitektur sistem yang mencakup Use Case Diagram, Sequence Diagram, Activity Diagram, Class Diagram, dan Component Diagram.

---

## 🔗 Subsistem Terkait

| Subsistem | Repository | Web Demo |
|-----------|------------|----------|
| Intelligence Engineering | [GitHub](https://github.com/faturrachmanhuda/intelligence-engineering-mobile) | [🌐 Demo](http://38.47.94.194/tif2/engineering/) |
| Project Management | [GitHub](https://github.com/faturrachmanhuda/project-management-mobile) | [🌐 Demo](http://38.47.94.194/tif2/pm/) |
| Intelligence Creation | [GitHub](https://github.com/faturrachmanhuda/intelligence-creation-mobile) | [🌐 Demo](http://38.47.94.194/tif2/creation/) |
| Dataset Management | [GitHub](https://github.com/faturrachmanhuda/dataset-management-mobile) | [🌐 Demo](http://38.47.94.194/tif2/dataset/) |
| Implementation | 📍 *You are here* | [🌐 Demo](http://38.47.94.194/tif2/implementation/) |

---

## 👥 Tim Pengembang

Dikembangkan oleh mahasiswa **Universitas Trisakti** — Fakultas Teknologi Industri, Program Studi Teknik Informatika.

---

## 📄 Lisensi

Proyek ini dikembangkan untuk keperluan akademis dalam rangka mata kuliah **Praktikum Rekayasa Perangkat Lunak**.

---

<p align="center">
  <b>Intelligence Engineerings</b> — Integrated AI Development Lifecycle Platform<br/>
  <sub>Universitas Trisakti • 2024/2025</sub>
</p>
