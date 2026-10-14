# aaPanel Pro Manager & Toolbox (v8.0.7 Compatible)

Script manajemen dan aktivasi PRO untuk **aaPanel versi 8.0.7** (Rilis: 2026-10-13 13:02:55) dengan dukungan penuh untuk **Python 3.12**, arsitektur antarmuka modern (Vite / Vue 3), serta sistem operasi Linux modern.

---

### Sistem Operasi yang Didukung
* **Ubuntu**: 20.04 / 22.04 / 24.04 LTS
* **Debian**: 11 (Bullseye) / 12 (Bookworm)
* **RHEL / AlmaLinux / Rocky Linux**: 8.x / 9.x
* **CentOS Stream**: 9

---

### Cara Penggunaan

#### 1. Menu Interaktif Lengkap (`aapanel.sh`)
Jalankan perintah berikut di terminal server Linux (sebagai `root`):
```bash
wget -O aapanel.sh https://raw.githubusercontent.com/Github-Aiko/aapanel-pro/master/aapanel.sh && chmod +x aapanel.sh && ./aapanel.sh
```

**Fitur Menu:**
1. **Install aaPanel (Official Latest v8.0.7)**: Mengunduh dan memasang versi resmi terbaru menggunakan script resmi `install_panel_en.sh`.
2. **Update / Repair aaPanel to Latest (v8.0.7)**: Memperbarui panel yang sudah terpasang ke versi 8.0.7 tanpa menghilangkan data website atau database.
3. **Activate aaPanel Pro (v8.0.7 Compatible)**: Mengaktifkan lisensi Lifetime PRO & LTD, membuka plugin komersial, memperbarui profil bound user, dan memperbaiki baseline security.
4. **Disable Site Expiration Lock & Clear Request Logs**: Membersihkan log akses dan menonaktifkan penghentian otomatis website yang kedaluwarsa.
5. **Cleanup Cache & Junk Files**: Membersihkan file sampah, temporary build, session lama, dan bytecode cache Python.
6. **Restart aaPanel Service**: Merestart daemon `/etc/init.d/bt`.
7. **Uninstall aaPanel**: Menjalankan skrip uninstall resmi panel.
0. **Exit**.

---

#### 2. Aktivasi 1-Klik Langsung (`aapro.sh`)
Jika aaPanel sudah terpasang dan Anda hanya ingin langsung mengaktifkan status Pro:
```bash
wget -O aapro.sh https://raw.githubusercontent.com/Github-Aiko/aapanel-pro/master/aapro.sh && chmod +x aapro.sh && ./aapro.sh
```

---

### Catatan Penting
* Setelah aktivasi selesai, **lakukan hard-refresh browser** (`Ctrl + F5`) atau buka panel di jendela **Incognito / Private Browsing** agar cache file JavaScript lawas di browser dibersihkan.
* Seluruh berkas frontend (`soft.js` dan `index.js`) di direktori `resource/` telah disinkronkan secara resmi dengan rilis aaPanel **8.0.7** sehingga tidak akan menyebabkan antarmuka error atau rusak.