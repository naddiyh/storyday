# Supabase: fondasi dan sinkronisasi jurnal

Implementasi tahap pertama menambahkan akun email/password dan sinkronisasi jurnal/checklist/mixed notes. Penggunaan tanpa akun tetap didukung. Jadwal, fokus, profil, reminder dan tema masih lokal; belum ada cloud media, OAuth Google/Apple, vault, atau AI.

## Konfigurasi

Baseline tetap Flutter 3.24.0 / Dart 3.5.0. `supabase_flutter` dipin 2.8.4 karena kompatibel dengan baseline ini; versi SDK Supabase terbaru memerlukan Flutter/Dart lebih baru. Dependency lockfile telah diperbarui tanpa mengganti baseline atau intl.

1. Gunakan proyek Supabase khusus Daystick dari akun yang benar. Proyek CLI lain tidak digunakan oleh perubahan ini.
2. Salin `.env.example` menjadi `.env` (diabaikan Git). Isi URL proyek dan **publishable key** atau legacy **anon key**. `SUPABASE_PROJECT_REF`, `SUPABASE_ACCESS_TOKEN`, dan `SUPABASE_DB_PASSWORD` opsional untuk deployment lokal, bukan aplikasi.
3. Terapkan migrasi setelah memeriksa target proyek:

   ```powershell
   supabase link --project-ref YOUR_DAYSTICK_PROJECT_REF
   supabase db push --dry-run
   supabase db push
   ```

4. Jalankan aplikasi:

   ```powershell
   ./tool/flutter-env.ps1 -Action Check
   ./tool/flutter-env.ps1 -Action RunWeb
   ```

   Build rilis: `./tool/flutter-env.ps1 -Action BuildWeb`. Gunakan `-FlutterPath <path-ke-flutter-3.24.0>` jika SDK default berbeda dari baseline.

Launcher membaca `.env` sebagai data tanpa mengeksekusi isinya. Hanya URL dan public client key diteruskan ke Flutter melalui file dart defines sementara, yang dihapus setelah launcher selesai. Access token dan password database tidak diteruskan ke Flutter, `.env` tidak didaftarkan sebagai asset, dan nilai key tidak dicetak. `Check` hanya memvalidasi format, bukan koneksi server. File `.env` tidak otomatis mengubah sesi Supabase CLI: login/link/deploy tetap langkah terpisah.

Alternatif lintas-platform: salin `config/supabase.example.json` ke `config/supabase.local.json` dan gunakan flag Flutter `--dart-define-from-file=config/supabase.local.json`. Tanpa konfigurasi, aplikasi tetap berjalan lokal; konfigurasi sebagian/rusak tidak memblokir jurnal lokal.

Jangan masukkan service-role key, secret API key, access token CLI atau password database ke konfigurasi Flutter. Public client key memang terlihat pada bundle web; pembatasan data harus ditegakkan oleh Auth/RLS. Validator menolak secret key dan JWT dengan role selain anon.

## Auth dan callback

- Profile > Account & journal sync menyediakan login/signup, status sync, retry, import lokal dan logout.
- Signup yang memerlukan konfirmasi email menampilkan instruksi konfirmasi dan tidak menganggap pengguna telah login.
- Aktifkan email/password pada proyek. Atur Site URL ke origin deployment dan allowlist reset redirect `https://YOUR_ORIGIN/#/account/password`; development memakai `http://127.0.0.1:5177/**` atau localhost yang sesuai.
- Alur reset memanggil layanan email Supabase, lalu menerima event passwordRecovery untuk membuka form password. Perubahan password biasa memverifikasi password lama terlebih dahulu.
- Native email/password login tersedia, tetapi callback konfirmasi/reset pada Android/iOS memerlukan konfigurasi app/universal links sesuai domain produksi. Jangan mengklaim callback native selesai sebelum konfigurasi itu diuji pada perangkat.
- Mengganti akun/logout membangun ulang router sehingga editor atau detail akun sebelumnya ditutup.
- Logout mempertahankan cache dan outbox akun secara terpisah, lalu membuka jurnal tanpa akun. Login kembali ke akun yang sama untuk melanjutkan retry.

## Data lokal dan impor

- Koleksi tanpa akun tetap menggunakan key lama `ordinary-notes.v1`, sehingga jurnal yang sudah tersimpan tetap dapat dibaca.
- Cache akun menggunakan `ordinary-notes.user.<user-id>.v1`. Notes dan outbox disimpan bersama dalam satu envelope JSON per akun.
- Memuat koleksi gagal tidak diartikan sebagai koleksi kosong. Payload asli dipertahankan; mutasi diblokir sampai dapat dibaca kembali. Kesalahan notes muncul melalui banner retry; kegagalan planner/profile pada startup menampilkan recovery screen.
- Antrean controller/repository mencegah save/load/delete bersamaan dalam satu instance aplikasi saling menimpa. Toggle checklist mengambil versi terkini sebelum mengubah item.
- Import lokal memerlukan konfirmasi dan menyalin notes saja; data asal tidak dihapus. ID import deterministik dan pemeriksaan tombstone mencegah duplikasi/resurrection saat import diulang.
- SharedPreferences bukan penyimpanan terenkripsi. Cache akun tetap ada di perangkat setelah logout, walaupun tidak ditampilkan pada akun lain. Ini belum merupakan perlindungan terhadap orang yang mengakses storage browser/device secara langsung.
- Serialisasi berlaku dalam satu instance aplikasi. Sinkronisasi lintas-perangkat memakai revision server; penulisan simultan dari beberapa tab/proses yang berbagi SharedPreferences belum memiliki lock lintas-proses. Untuk dukungan multi-tab produksi dan volume jurnal besar, pindahkan envelope ke penyimpanan lokal dengan transaksi/koordinasi lintas-tab.

## Protokol sinkronisasi

1. Simpan perubahan lokal dahulu, termasuk dirty flag dan mutation UUID, lalu jadwalkan upload.
2. RPC `sync_journal_note` mengambil user ID dari Auth, memvalidasi payload, dan memeriksa expected revision. Client tidak memilih pemilik data.
3. Mutation UUID membuat retry setelah respons hilang menjadi idempoten. Revision naik hanya untuk perubahan baru.
4. Penghapusan menjadi tombstone yang juga dibawa ke perangkat lain. Hard delete tidak diberikan kepada client.
5. Acknowledgement hanya membersihkan mutation yang benar. Edit baru saat upload berjalan tetap dirty dan memakai revision hasil acknowledgement berikutnya.
6. Jika revision bertabrakan, versi cloud tetap pada ID asal, sedangkan versi lokal menjadi note baru dengan label `(conflict copy)`. Ini juga berlaku ketika penghapusan lokal bertabrakan dengan perubahan remote: remote dipertahankan dan salinan lama disediakan untuk review. Tidak ada merge teks otomatis.
7. Pull memakai paginasi cursor note ID, termasuk tombstone. Tahap pertama mengambil seluruh koleksi; belum memakai incremental cursor atau Realtime.
8. Sync dijalankan setelah save, saat account repository aktif, setiap 30 detik selama proses berjalan, atau lewat tombol Sync now. Kegagalan jaringan mempertahankan dirty data untuk retry berikutnya.

## Database dan pengujian

- Migration awal: `supabase/migrations/20261028000100_journal_sync.sql`; perbaikan konflik API: `20261028000200_journal_conflict_http409.sql`. Terapkan keduanya melalui `supabase db push`.
- Konflik bisnis mengembalikan SQLSTATE `PT409` / HTTP 409. Jangan menggunakan `40001` untuk kondisi ini: PostgREST pada proyek dapat mengulang transaksi tanpa selesai. Adapter Flutter mengenali PT409 sebagai konflik dan mempertahankan salinan lokal.
- RLS hanya memperbolehkan SELECT milik sendiri untuk authenticated. Role anon tidak diberi akses.
- INSERT/UPDATE/DELETE langsung dicabut; perubahan hanya melalui RPC dengan owner dari `auth.uid()`, search_path kosong, revision check dan lock per owner+note.
- SQL test: `supabase/tests/journal_rls.sql`. Fixture dibatalkan dengan rollback. Jalankan pada database test:

  ```sh
  psql "$TEST_DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/tests/journal_rls.sql
  ```

- `bootstrap_test_auth.sql` hanya untuk PostgreSQL kosong sementara, **bukan proyek Supabase**. File ini menyediakan auth.uid/roles tiruan untuk menguji mekanisme PostgreSQL tanpa Docker/GoTrue. CI membuat PostgreSQL 17 disposable, menjalankan bootstrap, migrasi, lalu pengujian RLS.
- Pengujian lokal migrasi/RLS menggunakan PostgreSQL 15 terpisah dan auth context tiruan: isolasi A/B, akses anonim, bypass direct write, revision conflict, retry idempoten, validasi payload dan tombstone berhasil diuji. Ini belum membuktikan login/email/recovery di proyek Supabase tujuan.
- Tes Dart mencakup integritas data rusak, save/toggle bersamaan, restart offline, delete lintas-device, edit saat upload, konflik, cache akun, import berulang, dan respons upload setelah account repository disposed.

## Status pengiriman

Pada 28 Oktober 2026, kredensial `.env` berhasil diverifikasi terhadap proyek **storyday** di region **eu-central-1**. Kedua migrasi di atas sudah diterapkan lewat Supabase CLI pada proyek yang sesuai URL `.env`. Dua proyek akun CLI lama tidak digunakan. Token management hanya dipasang pada environment proses deployment; tidak disimpan sebagai login CLI global dan tidak diteruskan ke Flutter.

Verifikasi remote: RLS aktif, akses baca anonim ditolak, direct INSERT authenticated ditolak, RPC authenticated diizinkan. SQL regression dijalankan pada database remote dengan rollback dan fixture auth yang dibuat di transaksi tersebut tidak tersisa.

Pengujian API produksi menggunakan dua akun uji sementara yang dibuat tanpa mengirim email: password login, create, retry mutation yang sama, read pemilik, isolasi akun B, penolakan anonim, edit, konflik PT409, tombstone deletion dan logout semuanya lulus. Akun uji dihapus beserta notes melalui cascade setelah tes. Akses admin untuk membuat/menghapus fixture hanya berada dalam memory proses pengujian, tidak disimpan ke `.env`, file konfigurasi Flutter atau bundle aplikasi. Log ringkas tanpa key tersedia di `output/supabase-tests/live-api-results.json`.

Konfigurasi Auth development: Site URL default localhost:3000 diganti ke `http://127.0.0.1:5177`; redirect allowlist mencakup localhost/127.0.0.1 port 5177. Konfirmasi email tetap diwajibkan. Sebelum hosting produksi, set Site URL dan redirect domain produksi. Pengiriman email nyata, konfirmasi/reset melalui inbox dan callback native belum diuji. OAuth dan sync planner tetap tahap berikutnya.

Verifikasi akhir setelah perbaikan PT409: analyzer bersih, **71 tes lulus**, build web release berhasil. Tes adapter tambahan memakai HTTP server lokal untuk memastikan PT409 diterjemahkan menjadi JournalConflict dalam satu request dan akun yang berbeda diblokir sebelum request. Log terbaru: `output/playwright/audit/supabase-deployed-analyze.log`, `supabase-deployed-tests.log`, `supabase-deployed-build.log`.

Web terbaru tersedia pada `http://127.0.0.1:5177/?build=cloud-deployed-409#/account/login`; pemeriksaan Playwright menunjukkan nol console error. Verifikasi cleanup database menunjukkan nol akun uji, nol catatan uji, dan nol permintaan sync yang menggantung. Tes API remote bukan pengujian seluruh alur klik pada dua browser; perilaku offline diuji pada tes repository dengan remote tiruan.

Referensi implementasi: [Flutter Supabase](https://supabase.com/docs/guides/getting-started/tutorials/with-flutter), [Auth](https://supabase.com/docs/reference/dart/auth-signinwithpassword), [RLS](https://supabase.com/docs/guides/database/postgres/row-level-security).
