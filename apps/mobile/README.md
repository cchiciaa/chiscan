# ChiScan Mobile

Aplikasi Flutter untuk Smart Split Bill. Aplikasi mendukung pembuatan sesi
tagihan, penyimpanan lokal, state management Riverpod, dan boundary integrasi
REST API.

## Menjalankan

Pastikan Flutter SDK tersedia, lalu dari folder ini jalankan:

```text
flutter pub get
flutter test
flutter run
```

Tanpa backend, aplikasi menggunakan repository lokal berbasis
`shared_preferences`. Integrasi API menggunakan base URL default
`http://localhost:3000/api` dan dapat dikonfigurasi melalui konstruktor
`BillSessionApiClient`.

## Dokumentasi

- Arsitektur dan batasan proyek: [../../Architecture.md](../../Architecture.md)
- Panduan reviewer P4-P6: [../../panduan-reviewer.md](../../panduan-reviewer.md)
- Peta state management: [docs/STATE_MANAGEMENT.md](docs/STATE_MANAGEMENT.md)
