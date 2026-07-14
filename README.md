# NUSA Admin — License Management App

Aplikasi Flutter standalone untuk manajemen lisensi aktivasi NUSA.
Mirip dengan web dashboard [nusa-online](https://nusa-online.vercel.app/dashboard) tapi bisa diakses dari HP.

## Fitur

- **Overview** — Statistik lisensi (Total, Generated, Trial, Aktif, Cancelled, Expired, Suspended, Total Aktivasi)
- **Lisensi** — List, filter status, search, detail (termasuk daftar aktivasi), cancel, hapus
- **Generate** — Auto-generate key (termasuk trial 30 hari + kirim email), tambah key manual
- **Auth** — Login dengan admin key (tersimpan di secure storage, auto-login)

## Tech Stack

- Flutter 3.12+
- `flutter_secure_storage` — simpan admin key
- `google_fonts` — Inter font
- `intl` — format tanggal
- HTTP ke Supabase Edge Function `license-manager`

## Build & Run

```bash
flutter pub get
flutter run
```

## Related Projects

- [nusa-kasir](https://github.com/halugoods/nusa-kasir) — Aplikasi Kasir
- [nusa-online](https://github.com/halugoods/nusa-online) — Web Store + Admin Dashboard
