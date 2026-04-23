TrustPositif CDB (Constant Database)
====================================

Proyek ini menyediakan sistem otomasi untuk mengunduh, memvalidasi, dan mengonversi daftar blokir domain **TrustPositif (Komdigi)** ke dalam format **CDB (Constant Database)**. Format ini dioptimalkan untuk penggunaan pada DNS distributor atau resolver seperti **dnsdist**, karena menawarkan pencarian data yang instan dengan penggunaan memori (RAM) yang minimal.

Fitur Utama
-----------

-   **Zero-Downtime Update**: Menggunakan `cdbmake` yang menjamin pembuatan database atomik melalui file temporer.

-   **Smart Update**: `auto-update.sh` hanya akan melakukan pembaruan jika terdeteksi perubahan ukuran file (`Content-Length`) pada server Komdigi.

-   **Concurrency Protection**: Mekanisme *file locking* (`flock`) mencegah duplikasi proses saat pembaruan sedang berjalan.

-   **System Logging**: Seluruh aktivitas pembaruan otomatis dicatat ke dalam *system logs* (syslog) dengan tag `trustpositif-cdb`.

-   **Integrasi dnsdist**: Pengaturan kepemilikan file otomatis diatur untuk pengguna `_dnsdist`.

Dependensi
----------

Pastikan sistem Anda memiliki utilitas berikut:

-   `wget` & `curl`: Untuk mengunduh data dan mengecek header HTTP.

-   `awk`: Untuk transformasi data ke format input CDB.

-   `cdbmake`: Bagian dari paket `freecdb` atau `tinycdb`.

-   `flock`: Untuk managemen *lock file*.

-   `chown`: Untuk pengaturan izin akses file.

Di Debian/Ubuntu:


```
sudo apt update && sudo apt install git freecdb mawk curl wget coreutils
```

Struktur Direktori
------------------

Default instalasi berada di `/opt/trustpositif-cdb/`:

-   `scripts/update.sh`: Skrip pembaruan manual dengan *verbose output* ke konsol.

-   `scripts/auto-update.sh`: Skrip pembaruan otomatis yang dioptimalkan untuk Cron.

-   `domains.cdb`: File database akhir yang akan dibaca oleh aplikasi DNS.

-   `.domains.size`: File cache untuk menyimpan ukuran data terakhir.

Cara Penggunaan
---------------

### 1\. Persiapan Lingkungan

```
sudo git clone https://github.com/frizanwr/trustpositif-cdb /opt/trustpositif-cdb
cd /opt/trustpositif-cdb
sudo chmod +x scripts/*.sh
```

### 2\. Pembaruan Manual

Gunakan skrip ini untuk melakukan sinkronisasi paksa dan melihat statistik proses (jumlah domain & durasi):

```
/opt/trustpositif-cdb/scripts/update.sh
```

### 3\. Otomatisasi (Cron)

Skrip `auto-update.sh` sangat efisien untuk dijalankan secara berkala karena tidak akan mengunduh ulang file jika data di server belum berubah. Tambahkan ke crontab (misal: setiap 30 menit):


```
*/30 * * * * /opt/trustpositif-cdb/scripts/auto-update.sh
```

### 4\. Monitoring

Anda dapat memantau hasil eksekusi otomatis melalui syslog:


```
tail -f /var/log/syslog | grep trustpositif-cdb
```

Detail Teknis Konversi
----------------------

Skrip ini menggunakan format transformasi `awk` untuk menghasilkan skema CDB `+klen,dlen:key->data`:


```
awk '{ print "+" length($0) ",1:" $0 "->1" } END { print "" }'
```

Setiap domain disimpan sebagai **key** dengan **value** string `"1"`, memudahkan pengecekan eksistensi domain dalam *ruleset* DNS Anda.