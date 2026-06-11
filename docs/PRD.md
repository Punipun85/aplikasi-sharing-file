# PRD SecureShare

## 1. Nama Produk

SecureShare - Aplikasi Sharing File Aman Berbasis Multi-Platform.

## 2. Ringkasan Produk

SecureShare adalah aplikasi berbagi file aman berbasis Flutter dan Supabase. Aplikasi memungkinkan user mengunggah file, menyimpan file terenkripsi, membagikan file melalui link kepada user login, mengatur password link, expired link, access type, izin lihat/download, serta melihat activity log.

Target awal aplikasi adalah Android dan Web. Target lanjutan adalah iOS dan Desktop.

## 3. Tujuan Produk

1. Memudahkan user mengunggah dan menyimpan file secara online.
2. Memungkinkan user berbagi file melalui link aman.
3. Memberikan kontrol akses melalui public, protected, private, dan specific user.
4. Memberikan opsi expired link dalam menit, jam, dan hari.
5. Membatasi izin penerima menjadi view only atau view and download.
6. Menyimpan file secara terenkripsi sebelum masuk ke Supabase Storage.
7. Menampilkan preview file untuk pemilik file.
8. Mencatat activity log penting secara realtime.
9. Menyediakan dashboard user dan admin.
10. Mendukung pengalaman responsif untuk Android dan Web.

## 4. Target Platform

| Platform | Status |
| --- | --- |
| Android | Target utama |
| Web | Target utama |
| iOS | Target lanjutan |
| Desktop | Target lanjutan |

## 5. Target Pengguna

1. Mahasiswa untuk berbagi tugas, laporan, source code, dan dokumen kelompok.
2. Dosen atau guru untuk membagikan materi, modul, soal, dan dokumen akademik.
3. Organisasi untuk berbagi proposal, surat, laporan, desain, dan arsip.
4. Pekerja kantor untuk berbagi laporan, dokumen proyek, dan data tim.
5. Admin sistem untuk memantau user, file, dan aktivitas.

## 6. Stack Teknologi

| Area | Teknologi |
| --- | --- |
| Frontend | Flutter |
| Backend | Supabase |
| Database | PostgreSQL Supabase |
| Auth | Supabase Auth |
| Storage | Supabase Storage private bucket |
| State Management | Provider |
| Routing | GoRouter |
| File Picker | file_picker |
| Encryption | AES-256-GCM client-side encryption |
| Edge Function | generate-download-url |

## 7. Role Pengguna

### User

User dapat login, upload file, melihat file miliknya, preview file miliknya, rename, delete, membuat share link, mengatur password, expired date, access type, izin view/download, dan melihat activity log miliknya.

User tidak dapat melihat atau mengelola file milik user lain tanpa izin.

### Admin

Admin dapat melihat dashboard admin, users, audit metadata file terbatas, logs, statistik sistem, menonaktifkan user, dan menandai file melanggar sebagai deleted. Admin tidak dapat membuka isi file, signed URL file, path storage, atau key enkripsi.

## 8. Fitur Utama

### 8.1 Authentication

1. Register menggunakan email dan password.
2. Login menggunakan email dan password.
3. Logout.
4. Session tersimpan.
5. Role user dan admin.
6. Redirect berdasarkan role.
7. Popup sukses register lalu diarahkan ke login.

### 8.2 Dashboard User

1. Total file.
2. Total active links.
3. Total downloads.
4. Storage used.
5. Recent files.
6. Recent activity realtime.
7. Mailbox realtime untuk file yang dibagikan ke user.

### 8.3 Upload File

1. User memilih file dari device.
2. Validasi tipe file dan ukuran maksimal 50 MB.
3. File dienkripsi di client memakai AES-256-GCM.
4. File terenkripsi diupload ke bucket private `secure-files`.
5. Metadata file dan metadata enkripsi disimpan di tabel `files`.
6. Activity log upload dicatat.

### 8.4 My Files

1. Menampilkan file milik user login.
2. Mobile berupa card list.
3. Web berupa data table.
4. Search, filter, dan sort.
5. Action detail, share, rename, delete.

### 8.5 File Detail dan Preview

1. Menampilkan nama, tipe, ukuran, tanggal upload, status, download count.
2. Menampilkan active share links.
3. User pemilik dapat preview file.
4. File terenkripsi diambil dari private storage, lalu didekripsi di client.
5. Gambar dan TXT tampil inline.
6. PDF dan dokumen lain bisa dibuka setelah didekripsi.

### 8.6 Share Link

User dapat membuat link dengan access type:

| Access Type | Perilaku |
| --- | --- |
| public | User login dengan link bisa akses selama link aktif dan belum expired |
| protected | User login dengan link bisa akses setelah password benar |
| private | Hanya pemilik file yang bisa akses |
| specific_user | Hanya user/email tertentu yang terdaftar sebagai penerima |

Pengaturan share link:

1. Access type.
2. Password untuk protected.
3. Email penerima untuk specific user.
4. Expired link.
5. Izin penerima: view only atau view and download.
6. Web link.
7. Android deep link.
8. Protected delivery token untuk link protected.

### 8.7 Expired Link

Pilihan expired link:

1. 5 minutes.
2. 15 minutes.
3. 30 minutes.
4. 1 hour.
5. 2 hours.
6. 12 hours.
7. 24 hours.
8. 7 days.
9. 30 days.

Sistem menyimpan waktu expired ke `share_links.expired_at`. Edge Function menolak link jika `expired_at` sudah lewat.

### 8.8 Download dan View

1. Halaman `/share/:token` membuka metadata link.
2. Sistem validasi token, status link, expired date, status file, access type, password, dan penerima.
3. Jika `can_view = true`, tombol lihat file aktif.
4. Jika `can_download = true`, tombol download aktif.
5. Jika view only, tombol download nonaktif.
6. File terenkripsi diambil melalui signed URL lalu didekripsi di client.
7. Activity log download dicatat.

### 8.9 Activity Log

Aktivitas yang dicatat:

1. login.
2. upload_file.
3. rename_file.
4. delete_file.
5. create_share_link.
6. update_share_link.
7. download_file.
8. wrong_password.
9. expired_link_access.
10. access_denied.

### 8.10 Profile

1. Menampilkan nama, email, role, storage used.
2. Edit profile.
3. Edit foto profile.
4. Logout.

### 8.11 Admin Dashboard

1. Total users.
2. Total files.
3. Total storage.
4. Total downloads.
5. Recent activity.
6. Users page.
7. Files page.
8. Logs page.

## 9. Struktur Database

Tabel utama:

1. `profiles`.
2. `files`.
3. `share_links`.
4. `share_recipients`.
5. `activity_logs`.

Kolom penting untuk enkripsi file di `files`:

1. `is_encrypted`.
2. `encryption_algorithm`.
3. `encryption_key`.
4. `encryption_nonce`.
5. `encryption_mac`.

Kolom penting untuk share link:

1. `token`.
2. `access_type`.
3. `password_hash`.
4. `expired_at`.
5. `is_active`.
6. `can_view`.
7. `can_download`.

## 10. Keamanan dan Privasi Admin

1. Supabase Auth untuk login/register.
2. RLS untuk membatasi akses data.
3. Bucket `secure-files` private.
4. Upload file dienkripsi memakai AES-256-GCM.
5. Download/view file melalui Edge Function dan signed URL.
6. Token share dibuat unik dan panjang.
7. Password link disimpan dalam bentuk hash.
8. Link expired ditolak oleh Edge Function.
9. Private link hanya dapat diakses pemilik file.
10. Specific user link hanya dapat diakses email/user penerima.
11. Akses guest dihapus; halaman share membutuhkan login.
12. Admin tidak membaca tabel `files` langsung. Admin memakai RPC audit yang hanya mengembalikan metadata aman.
13. Admin tidak menerima `file_path`, `encryption_key`, `encryption_nonce`, atau `encryption_mac`.

## 11. Deteksi File Berbahaya Tanpa Membuka Data

SecureShare mendeteksi file berbahaya tanpa melihat isi file menggunakan fingerprint hash.

Alur:

1. Saat upload, aplikasi menghitung SHA-256 file asli sebelum enkripsi.
2. Aplikasi juga menghitung SHA-256 ciphertext setelah enkripsi.
3. Nilai hash disimpan sebagai metadata, bukan isi file.
4. Database memiliki tabel `threat_signatures` berisi hash file berbahaya yang diketahui.
5. Trigger database membandingkan hash upload dengan threat signature.
6. Jika cocok, file diberi `risk_status = malicious` atau `suspicious`.
7. Admin hanya melihat status risiko, tipe, ukuran, status file, dan ID pendek.
8. Admin dapat menandai file sebagai deleted tanpa membuka isi file.

## 12. Halaman Aplikasi

1. Splash Page.
2. Onboarding Page.
3. Login Page.
4. Register Page.
5. User Dashboard Page.
6. My Files Page.
7. File Detail Page.
8. Share File Dialog.
9. Download Share Page.
10. Activity Log Page.
11. Profile Page.
12. Edit Profile Page.
13. Admin Dashboard Page.
14. Admin Users Page.
15. Admin Files Page.
16. Admin Logs Page.

## 13. Indikator Keberhasilan

1. User dapat register dan login.
2. User dapat upload file dari Web atau Android.
3. File yang diupload tersimpan terenkripsi.
4. User dapat melihat file miliknya di My Files.
5. User dapat preview file miliknya di File Detail.
6. User dapat membuat share link.
7. Link expired tidak dapat digunakan setelah waktunya lewat.
8. Public link dapat dibuka oleh user login yang punya link.
9. Protected link meminta password.
10. Private link hanya bisa dibuka pemilik file.
11. Specific user link hanya bisa dibuka penerima.
12. View only menonaktifkan tombol download.
13. View and download mengaktifkan tombol lihat dan download.
14. Activity log berjalan realtime.
15. Admin dapat melihat users, audit metadata file, dan logs tanpa membuka data rahasia.

## 14. Catatan Pengembangan Lanjutan

1. Memindahkan wrapping key enkripsi agar key file tidak disimpan langsung dalam bentuk base64.
2. Menambahkan preview inline PDF native.
3. Menambahkan custom expired date/time picker.
4. Menambahkan folder management.
5. Menambahkan storage quota per user.
6. Menambahkan scan file berbahaya.
7. Menambahkan push notification dan email notification.
