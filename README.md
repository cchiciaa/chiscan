# Smart Split Bill (ChiScan)

Aplikasi kalkulator tagihan pintar (*smart split bill*) yang merancang pembagian pembayaran secara adil, cepat, dan akurat, memperhitungkan pajak, biaya layanan, serta diskon secara proporsional.

---

## 1. Deskripsi Masalah

Kegiatan berkumpul dan makan bersama di restoran atau kafe sering kali diakhiri dengan proses pembagian tagihan (*split bill*) yang rumit dan membingungkan. Beberapa kendala utama yang sering dihadapi meliputi:

- **Perhitungan Manual yang Rawan Error:** Menghitung pembagian tagihan secara manual menggunakan kalkulator biasa sering memicu kesalahan matematis, terutama saat memperhitungkan pajak (PPN/PB1), biaya layanan (*service charge*), dan diskon/promo.
- **Ketidakadilan Pembagian Biaya Tambahan:** Pajak dan *service charge* sering kali dibagi rata secara mentah tanpa melihat proporsi harga makanan yang dipesan masing-masing orang.
- **Penanganan Item Bersama (*Shared Items*):** Kesulitan membagi harga satu item makanan/minuman yang dikonsumsi bersama oleh beberapa orang.
- **Kerugian Pembayar Utama (*Host*):** Pembayar utama yang menanggulangi struk sering mengalami kerugian finansial akibat pembulatan yang salah atau rekan yang membayar kurang dari kewajibannya.
- **Waktu yang Terbuang:** Membutuhkan waktu lama di meja kasir/restoran hanya untuk menghitung bagian masing-masing individu.

---

## 2. Profil Target Pengguna

Target pengguna aplikasi ini berfokus pada kelompok masyarakat produktif dan bersosialisasi tinggi:

1. **Mahasiswa / Pelajar**
   - **Karakteristik:** Sering melakukan kegiatan kelompok, belajar bersama, atau sekadar *hangout* di kafe. Memiliki anggaran terbatas sehingga perhitungan hingga rupiah terkecil sangat krusial.
2. **Pekerja Muda (*First Jobbers* & Profesional)**
   - **Karakteristik:** Sering makan siang bersama rekan kerja, *after-work dinner*, atau *gathering* tim. Membutuhkan solusi serba cepat, praktis, dan transparan tanpa mengganggu waktu kerja.
3. **Komunitas & Pengelola Acara (*Group Event Organizers*)**
   - **Karakteristik:** Kelompok penghobi atau penyelenggara acara kecil yang sering melakukan transaksi bersama dan membutuhkan transparansi pencatatan biaya.

---

## 3. Manfaat Aplikasi

Aplikasi **Smart Split Bill** memberikan berbagai manfaat nyata bagi pengguna:

- **Keadilan & Akurasi Kalkulasi:** Pajak, *service fee*, dan diskon dihitung secara proporsional berdasarkan persentase total belanjaan masing-masing orang.
- **Efisiensi Waktu:** Memangkas waktu perhitungan tagihan dari yang tadinya memakan waktu 10-15 menit menjadi kurang dari 2 menit.
- **Transparansi & Mencegah Konflik:** Menyajikan rincian biaya (*breakdown*) yang jelas dan terbuka sehingga tidak ada keraguan atau prasangka antar anggota kelompok.
- **Kemudahan Pembayaran Kembali:** Menyajikan ringkasan tagihan beserta informasi nomor rekening/QRIS tujuan transfer secara jelas untuk mempermudah pelunasan.

---

## 4. Daftar Fitur Inti (Rencana 12 Pertemuan)

Berikut adalah daftar fitur inti yang realistis dirancang dan diselesaikan dalam jangka waktu **12 Pertemuan**:

### Modul Fitur
1. **Manajemen Sesi Tagihan (*Bill Session Management*)**
   - Membuat sesi *split bill* baru dengan nama tempat/event.
   - Menambahkan daftar nama partisipan/anggota kelompok.
2. **Input Item Pesanan & Penetapan Konsumen (*Item Allocation*)**
   - Menambahkan nama item, harga satuan, dan kuantitas.
   - Mengalokasikan item ke satu orang (konsumsi pribadi) atau banyak orang (*shared item*).
3. **Engine Perhitungan Proporsional (*Smart Calculation Engine*)**
   - Kalkulasi pajak (persentase) dan *service charge* (persentase) secara proporsional.
   - Kalkulasi diskon (nominal flat atau persentase) yang dipotong adil sesuai porsi pesanan.
4. **Ringkasan Tagihan Individu (*Individual Bill Summary*)**
   - Tampilan rincian biaya yang harus dibayar oleh setiap anggota kelompok.
5. **Informasi Pembayaran & Salin Rincian (*Payment Details & Copy/Share*)**
   - Menyimpan informasi rekening bank / e-wallet pembayar utama (*host*).
   - Fitur *Copy Text / Share Summary* untuk membagikan ringkasan tagihan yang rapi langsung ke aplikasi pesan (WhatsApp/Telegram).

### Roadmap Pengembangan 12 Pertemuan

| Pertemuan | Agenda & Output Pengembangan |
| :--- | :--- |
| **Pertemuan 1** | Identifikasi kebutuhan sistem, analisis masalah, dan penyusunan spesifikasi dokumen *README.md*. |
| **Pertemuan 2** | Perancangan arsitektur aplikasi, pembuatan *wireframe*, dan desain UI/UX (*User Flow*). |
| **Pertemuan 3** | Inisialisasi proyek, pengaturan struktur folder, serta penyiapan komponen dasar UI. |
| **Pertemuan 4** | Implementasi Fitur 1: Manajemen Sesi Tagihan (Input nama event & daftar anggota). |
| **Pertemuan 5** | Implementasi Fitur 2 (Bagian 1): Formulir input daftar item pesanan, harga, dan jumlah. |
| **Pertemuan 6** | Implementasi Fitur 2 (Bagian 2): Fitur alokasi item ke individu maupun *shared items*. |
| **Pertemuan 7** | Implementasi Fitur 3 (Bagian 1): Formula matematis kalkulasi pajak dan *service charge* proporsional. |
| **Pertemuan 8** | Implementasi Fitur 3 (Bagian 2): Formula kalkulasi diskon (flat/%) serta pembulatan nominal (*rounding handling*). |
| **Pertemuan 9** | Implementasi Fitur 4: Tampilan *Individual Bill Summary* (Kartu rincian tagihan per orang). |
| **Pertemuan 10** | Implementasi Fitur 5: Input rekening *host* & generator teks ringkasan untuk fitur *Share*. |
| **Pertemuan 11** | Pengujian menyeluruh (*Unit Testing* & *User Acceptance Testing*), penanganan *edge cases*, serta perbaikan *bug*. |
| **Pertemuan 12** | *Final Polishing* UI, pembuatan *build/deployment* aplikasi, dan persiapan presentasi demo produk. |

---

## 5. Fitur yang Tidak Dikerjakan (Out of Scope)

Untuk memastikan proyek selesai dengan kualitas baik dalam batasan waktu 12 pertemuan, fitur-fitur berikut **TIDAK** termasuk dalam cakupan pengerjaan versi ini:

- ❌ **Scan Struk Otomatis (OCR / AI Camera Parsing):** Tidak menggunakan teknologi pemindaian gambar struk otomatis. Seluruh data item diinput secara manual oleh pengguna.
- ❌ **Integrasi Payment Gateway Real-Time:** Tidak menyediakan fitur auto-debit atau integrasi API pembayaran langsung (seperti Midtrans/Xendit).
- ❌ **Autentikasi & Akun Pengguna Kompleks:** Tidak ada sistem pendaftaran (*register/login*), verifikasi OTP, atau manajemen profil pengguna berbasis cloud database.
- ❌ **Konversi Mata Uang Asing (Multi-Currency):** Aplikasi hanya mendukung transaksi dalam mata uang Rupiah (IDR).
- ❌ **Sinkronisasi Real-Time Multi-Device (Cloud Sync/WebSocket):** Versi awal tidak menyediakan pembaruan otomatis antar perangkat secara *real-time*; sinkronisasi lintas perangkat bukan bagian dari target 12 pertemuan.

---

## 6. Kriteria Aplikasi Dinyatakan Berhasil

Aplikasi **Smart Split Bill** dinyatakan **BERHASIL** apabila memenuhi indikator kriteria berikut:

1. **Akurasi Perhitungan 100%:**
   - Total penjumlahan dari kewajiban seluruh anggota kelompok sama persis (selisih Rp 0) dengan total nominal pada struk (Subtotal + Pajak + Service - Diskon).
2. **Proporsionalitas Pajak & Diskon Valid:**
   - Pajak, *service fee*, dan diskon terhitung secara proporsional sesuai dengan persentase belanjaan masing-masing individu, bukan dibagi rata secara acak.
3. **Penanganan Shared Item yang Tepat:**
   - Item makanan/minuman yang dikonsumsi $N$ orang terbagi secara presisi tanpa meninggalkan sisa pembulatan yang timpang.
4. **Kecepatan & Kemudahan Penggunaan (Usability):**
   - Pengguna dapat menyelesaikan seluruh proses penginputan tagihan (hingga menghasilkan rincian per orang) dalam waktu di bawah **3 menit** untuk 5 item dan 4 anggota.
5. **Stabilitas Aplikasi:**
   - Aplikasi berjalan lancar tanpa mengalami crash, *infinite loop*, error kalkulasi (`NaN`), atau hilangnya data saat navigasi.
6. **Format Output Ringkasan Rapi:**
   - Teks ringkasan tagihan yang disalin (*copy to clipboard*) memiliki format yang jelas, rapi, dan mudah dibaca saat ditempel ke aplikasi pesan singkat.
