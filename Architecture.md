# Smart Split Bill (ChiScan)

Build a simple, full-stack web application named **Smart Split Bill (ChiScan)**.

## Tujuan Aplikasi

Aplikasi membantu pengguna membagi tagihan restoran atau kafe secara adil, cepat, dan akurat. Aplikasi menghitung subtotal setiap orang, pajak, biaya layanan, diskon, item yang dikonsumsi bersama, serta menghasilkan ringkasan pembayaran yang mudah dibagikan.

Target utama aplikasi adalah mahasiswa atau pelajar, pekerja muda, profesional, komunitas, dan pengelola acara kecil.

## Teknologi yang Digunakan

* Frontend: Flutter dan Dart
* Backend: Node.js, TypeScript, dan Express
* Database: MySQL
* ORM: Prisma
* API style: REST API
* Database lokal: Docker Compose untuk MySQL
* Konfigurasi: `.env.example` untuk database URL dan konfigurasi aplikasi
* Bahasa antarmuka: Bahasa Indonesia

## Aturan Kode

* Jangan menambahkan komentar kecuali benar-benar diperlukan.
* Gunakan PascalCase untuk class, type, interface, enum, widget Flutter, model database, dan API DTO.
* Gunakan camelCase untuk variabel lokal, nama field JSON, dan method Dart.
* Usahakan panjang baris kode tidak lebih dari 150 karakter.
* Gunakan struktur folder yang sederhana dan mudah dipahami.
* Versi pertama tidak menggunakan autentikasi, registrasi, login, OTP, atau akun pengguna berbasis cloud.
* Mata uang yang didukung hanya Rupiah (IDR).

## Entitas Utama

### BillSession

* `Id`
* `Title`
* `HostName`
* `PaymentMethod`
* `AccountNumber`
* `SubtotalAmount`
* `TaxPercent`
* `TaxAmount`
* `ServicePercent`
* `ServiceAmount`
* `DiscountType`
* `DiscountValue`
* `DiscountAmount`
* `GrandTotalAmount`
* `CreatedAt`
* `UpdatedAt`

### Participant

* `Id`
* `BillSessionId`
* `Name`
* `SubtotalAmount`
* `TaxAmount`
* `ServiceAmount`
* `DiscountAmount`
* `TotalAmount`
* `PaymentStatus`
* `CreatedAt`

### Item

* `Id`
* `BillSessionId`
* `Name`
* `Price`
* `Quantity`
* `TotalPrice`
* `CreatedAt`

### ItemParticipant

* `Id`
* `ItemId`
* `ParticipantId`
* `SplitShare`
* `CalculatedPrice`

## Enum

### DiscountType

* `PERCENTAGE`
* `FLAT`

### PaymentStatus

* `PENDING`
* `PAID`

## Aturan Database dan Kalkulasi

* Nama `Participant` harus unik dalam satu `BillSessionId`.
* `Item.TotalPrice` dihitung dari `Price * Quantity`.
* Item pribadi memberikan 100% total harga kepada satu participant.
* Item bersama dibagi berdasarkan total `SplitShare` participant yang dipilih.
* `ParticipantSubtotal` dihitung dari seluruh item yang dialokasikan kepada participant.
* Pajak, biaya layanan, dan diskon dibagi secara proporsional berdasarkan subtotal setiap participant.
* Gunakan rumus berikut:

```text
SubtotalRatio = ParticipantSubtotal / BillSession.SubtotalAmount
ParticipantTaxAmount = SubtotalRatio * BillSession.TaxAmount
ParticipantServiceAmount = SubtotalRatio * BillSession.ServiceAmount
ParticipantDiscountAmount = SubtotalRatio * BillSession.DiscountAmount
ParticipantTotalAmount = ParticipantSubtotal + ParticipantTaxAmount
  + ParticipantServiceAmount - ParticipantDiscountAmount
```

* `TaxAmount` dihitung dari `SubtotalAmount * TaxPercent / 100`.
* `ServiceAmount` dihitung dari `SubtotalAmount * ServicePercent / 100`.
* Diskon persentase dihitung dari subtotal, sedangkan diskon flat menggunakan nominal yang dimasukkan.
* `GrandTotalAmount` harus sama dengan `SubtotalAmount + TaxAmount + ServiceAmount - DiscountAmount`.
* Total seluruh `ParticipantTotalAmount` harus sama persis dengan `GrandTotalAmount` setelah pembulatan.
* Sisa pembulatan harus dialokasikan secara deterministik agar tidak ada selisih rupiah.
* Hindari nilai `NaN`, pembagian dengan nol, harga negatif, kuantitas nol, dan diskon yang melebihi subtotal.

## Fitur Backend

### Manajemen Sesi Tagihan

* Membuat sesi tagihan baru dengan nama tempat atau event.
* Menampilkan daftar sesi tagihan.
* Melihat detail sesi tagihan.
* Mengubah data sesi tagihan.
* Menghapus sesi tagihan.

### Manajemen Participant

* Menambahkan participant ke sesi tagihan.
* Menampilkan daftar participant.
* Mengubah nama participant.
* Menghapus participant.
* Mengubah status pembayaran menjadi `PENDING` atau `PAID`.

### Manajemen Item dan Alokasi

* Menambahkan item dengan nama, harga satuan, dan kuantitas.
* Mengubah item.
* Menghapus item.
* Mengalokasikan item kepada satu participant.
* Mengalokasikan item kepada beberapa participant sebagai item bersama.
* Mengubah atau menghapus alokasi participant pada item.

### Calculation Engine

* Menghitung subtotal sesi secara otomatis dari seluruh item.
* Menghitung pajak, biaya layanan, dan diskon.
* Menghitung tagihan setiap participant secara proporsional.
* Menghitung ulang setelah item, alokasi, pajak, biaya layanan, atau diskon berubah.
* Menangani sisa pembulatan agar total selalu konsisten.

### Ringkasan dan Pembayaran

* Mengembalikan rincian subtotal, pajak, layanan, diskon, dan total setiap participant.
* Menyimpan metode pembayaran dan rekening atau informasi QRIS host.
* Menghasilkan teks ringkasan yang siap disalin ke WhatsApp atau Telegram.

## Layar Aplikasi Flutter

Prototype UI/UX dibuat terlebih dahulu untuk memvalidasi alur utama aplikasi. Prototype dapat dirancang di Figma atau dibuat langsung sebagai mock UI Flutter.

Prototype minimum mencakup:

* Dashboard daftar sesi tagihan.
* Form pembuatan dan pengaturan sesi tagihan.
* Halaman detail sesi untuk mengelola participant dan item.
* Halaman ringkasan tagihan individu dan status pembayaran.
* Dialog atau halaman pengaturan informasi pembayaran host.

Struktur aplikasi Flutter harus memisahkan halaman, widget reusable, model data, service/API, dan routing agar mudah dikembangkan.

### Dashboard Sesi Tagihan

* Menampilkan daftar sesi tagihan.
* Menampilkan judul, nama host, total tagihan, jumlah participant, status pembayaran, dan tanggal pembuatan.
* Menyediakan tombol `Buat Sesi Baru`.
* Menampilkan empty state jika belum ada sesi.

### Builder dan Detail Sesi

* Header berisi judul sesi, subtotal, pajak, layanan, diskon, dan grand total.
* Form manajemen participant.
* Form item berisi nama item, harga, kuantitas, dan participant yang mengonsumsi.
* Form pajak, biaya layanan, dan diskon.
* Dialog konfirmasi sebelum menghapus data.
* Pesan validasi dan error dalam Bahasa Indonesia.

### Ringkasan Individu dan Pelacak Pembayaran

* Kartu rincian tagihan setiap participant.
* Badge status `PAID` atau `PENDING`.
* Tombol untuk mengubah status pembayaran.
* Kartu informasi pembayaran host.
* Tombol `Salin Ringkasan Tagihan`.

## Persyaratan UI

* Semua label, tombol, pesan, validasi, dan empty state menggunakan Bahasa Indonesia.
* Gunakan Flutter Material 3 dengan layout responsif, tabel atau list, kartu, badge, formulir, dan dialog konfirmasi.
* Gunakan package HTTP atau Dio untuk memanggil REST API.
* Gunakan state management sederhana yang konsisten, seperti Provider, Riverpod, atau BLoC.
* Sediakan loading state, error state, empty state, dan feedback sukses pada setiap alur utama.
* Gunakan warna hijau untuk `PAID` dan oranye atau merah untuk `PENDING`.
* Jangan menambahkan chart pada versi pertama.
* Prioritaskan alur input yang dapat diselesaikan kurang dari 3 menit untuk 5 item dan 4 participant.

## Routing dan Reusable Widget

* Gunakan routing terpusat untuk mengatur perpindahan antara dashboard, form sesi, detail sesi, dan ringkasan pembayaran.
* Definisikan nama route dalam satu file agar navigasi tidak menggunakan string yang tersebar di banyak halaman.
* Buat reusable widget untuk tombol utama, input field, app bar, kartu ringkasan, badge status, dialog konfirmasi, dan empty state.
* Widget reusable harus menerima data dan callback melalui parameter agar dapat digunakan di beberapa screen.
* Pisahkan tampilan, state, dan pemanggilan API agar screen tetap mudah diuji dan dirawat.

## API Routes

* `GET /api/sessions`
* `POST /api/sessions`
* `GET /api/sessions/:Id`
* `PUT /api/sessions/:Id`
* `DELETE /api/sessions/:Id`
* `GET /api/sessions/:BillSessionId/participants`
* `POST /api/sessions/:BillSessionId/participants`
* `PUT /api/participants/:Id`
* `DELETE /api/participants/:Id`
* `PATCH /api/participants/:Id/status`
* `GET /api/sessions/:BillSessionId/items`
* `POST /api/sessions/:BillSessionId/items`
* `PUT /api/items/:Id`
* `DELETE /api/items/:Id`
* `POST /api/sessions/:BillSessionId/calculate`
* `GET /api/sessions/:BillSessionId/summary`

## Struktur Project

Gunakan struktur project yang memisahkan aplikasi Flutter, backend API, dan kontrak API:

```text
smart-split-bill/
  apps/
    mobile/
    api/
  packages/
    api-contract/
```

`apps/mobile` adalah project Flutter/Dart dan `apps/api` adalah project Node.js/TypeScript.

## Kontrak API dan Model

Karena Flutter/Dart tidak dapat mengimpor package TypeScript secara langsung, gunakan kontrak REST sebagai sumber kebenaran bersama.

* Simpan OpenAPI atau dokumentasi JSON schema di `packages/api-contract`.
* Model Dart untuk `BillSession`, `Participant`, `Item`, `ItemParticipant`, `DiscountType`, dan `PaymentStatus` berada di `apps/mobile/lib/models`.
* DTO TypeScript untuk API berada di `apps/api/src/dto`.
* Nama property JSON REST harus konsisten antara Flutter dan backend.
* Jangan mengimpor Prisma type ke Flutter.

Contoh struktur Flutter:

```text
apps/mobile/lib/
  main.dart
  app.dart
  routes/
    app_routes.dart
  screens/
    dashboard_screen.dart
    bill_session_screen.dart
    summary_screen.dart
  widgets/
    primary_button.dart
    app_text_field.dart
    summary_card.dart
    status_badge.dart
    confirmation_dialog.dart
  models/
    bill_session_model.dart
    participant_model.dart
    item_model.dart
    item_participant_model.dart
  services/
    api_client.dart
    bill_session_service.dart
```

## Aturan Shared Model

* Definisikan model Dart dan DTO TypeScript berdasarkan kontrak API yang sama.
* Gunakan enum Dart untuk `DiscountType` dan `PaymentStatus`.
* Gunakan model immutable atau pola serialisasi JSON yang konsisten di Flutter.
* Model Prisma tetap berada di backend karena bersifat spesifik terhadap database.
* Backend memetakan entitas Prisma ke API model bersama sebelum mengembalikan response.
* Flutter tidak boleh mengimpor type Prisma atau kode TypeScript.
* Konfigurasikan `pubspec.yaml`, environment API URL, script Flutter, dan script backend agar aplikasi dapat dijalankan dan dikompilasi.

## Seed dan Deliverable

* Gunakan Prisma migration.
* Sediakan seed dengan satu contoh sesi tagihan, empat participant, lima item, termasuk item bersama, pajak, biaya layanan, dan diskon.
* Sediakan Docker Compose untuk MySQL.
* Sediakan `.env.example` untuk database URL dan konfigurasi aplikasi.
* Sediakan README berisi instalasi Flutter, migrasi database, seed, menjalankan aplikasi Flutter dan backend, penggunaan Docker, dan konfigurasi API URL.
* Pastikan build berhasil dan CRUD dasar serta calculation engine dapat digunakan.

## Batasan Versi Pertama

Fitur berikut tidak dikerjakan dalam versi pertama:

* Scan struk otomatis menggunakan OCR atau AI camera parsing.
* Integrasi payment gateway real-time seperti Midtrans atau Xendit.
* Registrasi, login, OTP, dan akun pengguna kompleks.
* Multi-currency atau konversi mata uang asing.
* Sinkronisasi real-time antar perangkat menggunakan cloud sync atau WebSocket.
