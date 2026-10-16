# Panduan Reviewer: P4, P5, dan P6 (ChiScan Mobile)

Dokumen ini disusun untuk memudahkan reviewer/dosen dalam memeriksa dan menguji implementasi tiga milestone proyek:
- **P4**: State Management (Riverpod, Form, Validasi, 6 Kondisi UI, Anti Double-Tap)
- **P5**: Local Data & Persistence (`shared_preferences`, Data Model, CRUD, Persistence Test)
- **P6**: Integrasi API & Vertical Slice (REST API, Penyimpanan & Loading Backend, 6+ Unit Test)

---

## 1. Peta Posisi Kode (Code Structure)

Sistem dibangun dengan arsitektur bersih yang memisahkan tanggung jawab (Clean Architecture / Vertical Slice):

| Layer | File / Lokasi | Tanggung Jawab & Implementasi |
|---|---|---|
| **Data Model & Entity** | [`apps/mobile/lib/models/bill_session.dart`](file:///c:/Users/nomhn/Downloads/chiscan/apps/mobile/lib/models/bill_session.dart) | Entity `BillSession` immutable dengan `toJson()`, `fromJson()`, `copyWith()`, serta validasi schema yang melempar `FormatException` saat data tidak valid (**P5 & P6**). |
| **API Client (REST Service)** | [`apps/mobile/lib/services/bill_session_api_client.dart`](file:///c:/Users/nomhn/Downloads/chiscan/apps/mobile/lib/services/bill_session_api_client.dart) | **P6 Integrasi API:** Service HTTP berbasis `package:http` yang menghubungkan aplikasi ke backend REST API (`GET`, `POST`, `PUT`, `DELETE /api/sessions`). Dilengkapi penanganan `ApiException`, status code HTTP, dan parsing JSON. |
| **Repository Layer** | [`apps/mobile/lib/repositories/bill_session_repository.dart`](file:///c:/Users/nomhn/Downloads/chiscan/apps/mobile/lib/repositories/bill_session_repository.dart) | Interface `BillSessionRepository` dengan dua implementasi nyata:<br>1. `ApiBillSessionRepository`: Memanggil backend via `BillSessionApiClient` (**P6**).<br>2. `LocalBillSessionRepository`: Menyimpan data lokal via `shared_preferences` dengan CRUD penuh (**P5**).<br>3. `InMemoryBillSessionRepository`: Untuk mock/fallback. |
| **State Management (Riverpod)** | [`apps/mobile/lib/providers/bill_session_provider.dart`](file:///c:/Users/nomhn/Downloads/chiscan/apps/mobile/lib/providers/bill_session_provider.dart) | **P4 State Management:**<br>• `billSessionsProvider` (`BillSessionsNotifier`): Mengelola lifecycle async query daftar sesi (`build`, `retry`, `deleteSession`).<br>• `createSessionProvider` (`CreateSessionNotifier`): Mengelola submit form (Create & Update) dengan double-tap guard (`AsyncLoading`). |
| **Validator** | [`apps/mobile/lib/validators/bill_session_validator.dart`](file:///c:/Users/nomhn/Downloads/chiscan/apps/mobile/lib/validators/bill_session_validator.dart) | Rule validasi form: nama tempat dan nama host wajib diisi (**P4**). |
| **UI Screens & Widgets** | [`apps/mobile/lib/screens/dashboard_screen.dart`](file:///c:/Users/nomhn/Downloads/chiscan/apps/mobile/lib/screens/dashboard_screen.dart)<br>[`apps/mobile/lib/screens/create_session_screen.dart`](file:///c:/Users/nomhn/Downloads/chiscan/apps/mobile/lib/screens/create_session_screen.dart) | **FE Vertical Slice:**<br>• `DashboardScreen`: Menampilkan 5 kondisi UI (loading, empty, error + retry, success) serta tombol aksi Edit dan Delete (dialog konfirmasi).<br>• `CreateSessionScreen`: Form validasi input, mode Create/Update, disabled submit + spinner anti double-tap. |
| **Unit & Widget Tests** | [`apps/mobile/test/unit/bill_session_api_test.dart`](file:///c:/Users/nomhn/Downloads/chiscan/apps/mobile/test/unit/bill_session_api_test.dart)<br>[`apps/mobile/test/widget/bill_session_test.dart`](file:///c:/Users/nomhn/Downloads/chiscan/apps/mobile/test/widget/bill_session_test.dart)<br>[`apps/mobile/test/widget_test.dart`](file:///c:/Users/nomhn/Downloads/chiscan/apps/mobile/test/widget_test.dart) | 17 automated tests (100% Pass) mencakup 7 unit test P6, 6 kondisi widget test P4, dan tes CRUD & persistence P5. |

---

## 2. P6: Integrasi API & Vertical Slice

### A. Apakah Sudah Ada Koneksi ke API?
**YA, SUDAH ADA.**
- **File API Client**: [`apps/mobile/lib/services/bill_session_api_client.dart`](file:///c:/Users/nomhn/Downloads/chiscan/apps/mobile/lib/services/bill_session_api_client.dart)
- Menggunakan `package:http` untuk melakukan panggilan HTTP REST API nyata:
  - `GET /api/sessions`: Mengambil daftar seluruh sesi dari backend.
  - `POST /api/sessions`: Menyimpan sesi baru ke backend.
  - `PUT /api/sessions/:id`: Memperbarui data sesi di backend.
  - `DELETE /api/sessions/:id`: Menghapus sesi di backend.
- Dilengkapi `baseUrl` yang dapat dikonfigurasi (default: `http://localhost:3000/api`) dan `client` yang dapat di-inject (`MockClient` untuk unit testing).

### B. Alur Slice Vertikal (FE => Provider => Repository => API Client => Backend)
```mermaid
flowchart LR
  subgraph Frontend ["Frontend (UI)"]
    UI[Dashboard / Form]
  end
  subgraph StateManagement ["State Management"]
    Notifier[BillSessionsNotifier / CreateNotifier]
  end
  subgraph RepositoryLayer ["Repository Layer"]
    Repo[ApiBillSessionRepository]
  end
  subgraph ServiceLayer ["Service Layer"]
    Client[BillSessionApiClient (http)]
  end
  subgraph Server ["Backend REST API"]
    Backend["/api/sessions (Node/Express/DB)"]
  end

  UI -->|Action / Event| Notifier
  Notifier -->|Invoke CRUD| Repo
  Repo -->|HTTP Call| Client
  Client -->|GET / POST / PUT / DELETE| Backend
  Backend -->|JSON Response| Client
  Client -->|Parse Data / Throw Exception| Repo
  Repo -->|List<BillSession> / Error| Notifier
  Notifier -->|AsyncData / AsyncError / AsyncLoading| UI
```

### C. 5 Kondisi UI saat Terhubung API
1. **Loading**: Menampilkan spinner `CircularProgressIndicator` saat HTTP request sedang berlangsung.
2. **Empty**: Menampilkan `"Belum ada sesi tagihan."` saat backend merespon dengan array kosong `[]`.
3. **Error**: Menampilkan pesan `"Sesi tagihan gagal dimuat."` saat HTTP gagal (status 500, 404, atau koneksi terputus).
4. **Retry**: Menyediakan tombol `"Coba Lagi"` pada error state yang memicu pemanggilan ulang `ref.read(billSessionsProvider.notifier).retry()`.
5. **Success**: Menampilkan daftar card sesi tagihan beserta rincian lengkap.

### D. Pengujian Unit Test (7 Unit Tests P6 — 100% PASS)
Unit test terletak pada [`apps/mobile/test/unit/bill_session_api_test.dart`](file:///c:/Users/nomhn/Downloads/chiscan/apps/mobile/test/unit/bill_session_api_test.dart) menggunakan `package:http/testing.dart` (`MockClient`):

| No | Kategori Uji | Deskripsi Pengujian | Hasil |
|:---:|---|---|:---:|
| 1 | **Model Valid** | Mem-parsing JSON valid ke instance `BillSession` dan memverifikasi seluruh atribut. | **PASS** |
| 2 | **Model Invalid** | Memverifikasi `BillSession.fromJson` melempar `FormatException` saat JSON kehilangan field wajib (`id`, `title`, `hostName`) atau tipe data tidak cocok. | **PASS** |
| 3 | **API Sukses** | Mock server mengembalikan HTTP 200 OK dengan JSON array valid -> Repository menghasilkan `List<BillSession>`. | **PASS** |
| 4 | **Data Kosong** | Mock server mengembalikan HTTP 200 OK dengan array kosong `[]` -> Repository menghasilkan list kosong (`isEmpty == true`). | **PASS** |
| 5 | **HTTP Gagal** | Mock server mengembalikan status code 500 / error -> API Client melempar `ApiException` dengan status code 500. | **PASS** |
| 6 | **JSON Rusak** | Mock server mengembalikan response body dengan malformed JSON (misal `{"invalid_json: ...`) -> Melempar `ApiException` dengan keterangan format rusak. | **PASS** |
| 7 | **POST API Sukses** | Menyimpan data sesi baru ke backend via HTTP POST -> Backend mengembalikan HTTP 201 dengan data sesi yang tersimpan. | **PASS** |

---

## 3. P4: State Management (Riverpod) & 6 Kondisi UI

1. **Initial Loading**: Menampilkan spinner saat pertama kali membuka dashboard.
2. **Data Berhasil Dimuat**: Menampilkan daftar card sesi tagihan.
3. **Empty State**: Menampilkan teks ketika tidak ada data sesi.
4. **Error State dengan Retry**: Menampilkan pesan error dan tombol `"Coba Lagi"`.
5. **Validasi Input Form**: Menampilkan validasi form saat kolom judul/host dikosongkan.
6. **Loading saat Submit (Anti Double-Tap)**: Tombol form menjadi disabled (`onPressed: null`) dan menampilkan spinner saat submit berlangsung, dengan guard di notifier `if (state.isLoading) return false;`.

---

## 4. P5: Local Data & Persistence (`shared_preferences`)

1. **Local Data**: Menggunakan `shared_preferences` dengan key `chiscan_bill_sessions`.
2. **Data Model**: Model immutable `BillSession` dengan serialisasi JSON.
3. **CRUD Lengkap**:
   - **Create**: Menambah sesi baru via form.
   - **Read**: Menampilkan daftar sesi dari local storage.
   - **Update**: Mengedit sesi yang sudah ada via form edit.
   - **Delete**: Menghapus sesi dengan dialog konfirmasi `"Hapus Sesi?"`.
4. **Persistence Test**: Teruji di mana instance repository kedua membaca storage yang sama setelah restart simulasi dan data tetap tersimpan utuh.

---

## 5. Bukti Hasil Eksekusi Test (17/17 Passed)

Jalankan perintah berikut di terminal:
```bash
cd apps/mobile
flutter test
```

**Output Terminal:**
```text
00:00 +0: P6 1. Model Valid - berhasil mem-parsing JSON valid ke instance BillSession
00:00 +1: P6 2. Model Invalid - melempar FormatException jika field wajib tidak ada
00:00 +2: P6 3. API Sukses - mengembalikan daftar BillSession saat HTTP 200 OK
00:00 +3: P6 4. Data Kosong - mengembalikan List kosong saat HTTP 200 OK []
00:00 +4: P6 5. HTTP Gagal - melempar ApiException saat server 500
00:00 +5: P6 6. JSON Rusak - melempar ApiException saat response body malformed
00:00 +6: P6 7. Penyimpanan ke Backend (POST API) - berhasil menyimpan data sesi
00:00 +7: P4 menampilkan initial loading
00:02 +8: ChiScanApp smoke test menampilkan judul appBar dan data sesi
00:03 +11: P4 menampilkan error dan retry berhasil
00:03 +12: P4 menampilkan validasi input form
00:04 +13: P4 menampilkan loading submit dan mencegah double tap
00:04 +14: P5 CRUD Update - memperbarui sesi yang sudah ada
00:05 +15: P5 CRUD Delete - menghapus sesi dengan konfirmasi dialog
00:05 +16: P5 Persistence Test - data tersimpan di SharedPreferences setelah restart
00:05 +17: All tests passed!
```

---

## 6. Jawaban Cepat untuk Reviewer (Cheat Sheet Presentasi)

| Pertanyaan Reviewer | Jawaban Singkat & Bukti Kode |
|---|---|
| **Apakah sudah ada koneksi ke API?** | **Sudah ada.** Terletak di [`apps/mobile/lib/services/bill_session_api_client.dart`](file:///c:/Users/nomhn/Downloads/chiscan/apps/mobile/lib/services/bill_session_api_client.dart) dan [`apps/mobile/lib/repositories/bill_session_repository.dart`](file:///c:/Users/nomhn/Downloads/chiscan/apps/mobile/lib/repositories/bill_session_repository.dart) (`ApiBillSessionRepository`). Menggunakan `package:http` untuk request `GET`, `POST`, `PUT`, `DELETE` ke backend REST API. |
| **Apakah sudah ada Unit test?** | **Sudah ada, lengkap 7 unit test.** Terletak di [`apps/mobile/test/unit/bill_session_api_test.dart`](file:///c:/Users/nomhn/Downloads/chiscan/apps/mobile/test/unit/bill_session_api_test.dart). Mencakup: `model valid`, `model invalid`, `API sukses`, `data kosong`, `HTTP gagal (500)`, `JSON rusak`, dan `POST create sesi`. |
| **Bagaimana penanganan kondisi UI?** | Terhubung melalui Riverpod `billSessionsProvider` pada [`apps/mobile/lib/screens/dashboard_screen.dart`](file:///c:/Users/nomhn/Downloads/chiscan/apps/mobile/lib/screens/dashboard_screen.dart), menangani `loading` (spinner), `empty` (pesan kosong), `error` (pesan error + tombol Coba Lagi/retry), dan `success` (daftar kartu sesi). |
| **Apakah kode bebas dari issue/lint?** | **Ya.** `flutter analyze` menghasilkan `No issues found!`. |

