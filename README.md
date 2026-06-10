# SecureShare

SecureShare adalah aplikasi sharing file aman berbasis Flutter dan Supabase. Target awalnya Android dan Web, dengan struktur yang siap diperluas ke iOS dan Desktop.

## Stack

- Frontend: Flutter
- Backend: Supabase
- Database: PostgreSQL
- Authentication: Supabase Auth
- Storage: Supabase Storage private bucket
- State management: Provider
- Routing: GoRouter
- File picker: file_picker

## Struktur Folder

- `lib/config`: konfigurasi Supabase dan konstanta aplikasi.
- `lib/core`: theme, widget reusable, formatter, dan helper responsive.
- `lib/features/auth`: login, register, session, role user/admin.
- `lib/features/dashboard`: user dashboard.
- `lib/features/files`: upload, daftar file, detail file, provider, service, model.
- `lib/features/share`: share link, password/expiry, download page.
- `lib/features/activity`: activity log.
- `lib/features/admin`: dashboard admin, users, files, logs.
- `lib/features/profile`: profile dan logout.
- `supabase/functions`: Edge Function untuk share link dan signed download URL.

## Setup Supabase

1. Buat project Supabase.
2. Buka SQL Editor, jalankan isi `supabase_schema.sql`.
3. Pastikan bucket `secure-files` sudah ada dan private. Schema SQL sudah membuat bucket ini jika policy storage tersedia.
4. Aktifkan email/password di Authentication.
5. Buat user admin, lalu update role:

Jika register berhasil di `Authentication > Users` tetapi tabel `profiles` tetap kosong, jalankan `supabase_profile_trigger.sql` di SQL Editor untuk memasang ulang trigger pembuat profile.

```sql
update public.profiles
set role = 'admin'
where email = 'admin@secureshare.dev';
```

## Environment

Project ini sudah diarahkan ke Supabase:

- URL: `https://nydvzmqmcldmbglplrxs.supabase.co`
- REST API: `https://nydvzmqmcldmbglplrxs.supabase.co/rest/v1/`
- Publishable key: sudah terpasang di `lib/config/supabase_config.dart`

Catatan: Supabase Flutter memakai base URL project, bukan URL `/rest/v1/` secara langsung. Operasi edit data seperti `insert`, `update`, `delete`, dan `select` akan diarahkan otomatis ke REST API Supabase.

Kamu tetap bisa override konfigurasi dengan `--dart-define`:

```bash
flutter run -d chrome --dart-define=SUPABASE_URL=https://your-project-ref.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=your-publishable-key
```

Untuk Android:

```bash
flutter run -d android --dart-define=SUPABASE_URL=https://your-project-ref.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=your-publishable-key
```

Jika konfigurasi Supabase dikosongkan, aplikasi berjalan dalam demo mode dengan data contoh.

## Edge Functions

Deploy dari folder project setelah Supabase CLI login:

```bash
supabase functions deploy create-share-link
supabase functions deploy verify-share-password
supabase functions deploy generate-download-url
```

Tambahkan secret:

```bash
supabase secrets set SUPABASE_URL=https://your-project-ref.supabase.co
supabase secrets set SUPABASE_ANON_KEY=your-anon-or-publishable-key
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

## Catatan Keamanan

- Bucket `secure-files` private, file tidak dibuka langsung dari public URL.
- Download produksi harus lewat `generate-download-url` agar token, expiry, access type, status file, dan penerima divalidasi.
- Password share link di-hash di Edge Function memakai bcrypt.
- RLS membatasi user hanya pada profile, file, share link, dan activity miliknya.
- Admin dibatasi lewat role `admin` di tabel `profiles`.

## Contoh Akun Demo

- User demo UI: `demo@secureshare.dev` dengan password apa pun minimal 8 karakter.
- Admin demo UI: gunakan email yang mengandung `admin`, misalnya `admin@secureshare.dev`.
