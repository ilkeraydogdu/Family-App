# Family-App (Aile Düzeni & Ortak Saatlik Ajanda)

Eşlerin hem kendi kişisel saatlik planlarını hem de ortak aile rutinlerini (05:00 uyanış, canlı namaz vakitleri, servis/iş saatleri, gitar dersi vb.) gerçek zamanlı senkronize olarak yönetebildiği **Flutter (Android & iOS) + Supabase** uygulaması.

## Öne Çıkan Özellikler

1. **Ortak ve Kişisel Saatlik Ajanda (`schedule_blocks`)**
   - **İlker (Ben)**, **Eşim** ve **Ortak Plan** ayrımı ile aynı saatte kimin hangi planda olduğunu yan yana veya birleşik akışta görme.
   - Örnek Akış:
     - `05:00 - 05:45`: Güne Uyanış & Hazırlık (Ortak)
     - `06:00 - 06:30`: Sabah Namazı (Canlı Diyanet vaktine bağlı)
     - `06:45 - 07:45`: Servise Yürüyüş & Servis (İlker - Sabah namazından 45 dk sonraya otomatik ayarlı)
     - `08:00 - 12:00`: İş Başlangıcı & Odak Bloğu (İlker)
     - `08:00 - 09:00`: Sabah Rutini & Planlama (Eşim)
     - `09:00 - 11:00`: Gitar Dersi & Pratik (Eşim - 15 dk kala 3 tekrarlı sesli hatırlatıcı, alt görev tik listesi ve ders sonu özet notu)

2. **Canlı Namaz Vakitleri Entegrasyonu (Diyanet Metodu)**
   - Seçilen şehre göre (`Istanbul`, `Ankara`, `Izmir`, `Eskisehir` vb.) canlı namaz vakitlerini çeker.
   - **"Canlı Namaz Vaktine Bağla"** seçeneği açık olan planları (Sabah namazı, namaz sonrası servis yürüyüşü vb.) değişen namaz saatlerine göre otomatik hizalar.

3. **Sesli Hatırlatıcı (Türkçe TTS) & Tekrarlı Alarm**
   - Her etkinlik için **kaç dakika kala** haber vereceği (`5, 10, 15, 30, 45 dk`), **kaç kez tekrarlayacağı** (`1-10 kez`) ve **kaç dakika arayla** sesli okuyacağı ayarlanır.
   - Kullanıcı **"Derse Geldim / Başladım"** butonuna bastığında tekrarlayan sesli bildirimler otomatik susturulur.

4. **Ders / İş Sonu Özeti, Tik Listesi ve "Atlandı" Takibi**
   - Etkinlik biterken (bir sonraki işe geçmeden önce) alt görevlere tik atılabilir (`checklist_items`) ve *"Bu derste/saatte neler yaptım?"* özeti kaydedilebilir (`completion_notes`).
   - Derse veya plana gidilemediğinde **"Bugün Gitmedim / Atladım"** seçilerek mazeret kaydedilir ve **Takip & Özet** sekmesinde atlanan dersler takip edilir.

5. **Telefon Kısıtlama & Odak Kalkanı (Sadece Aramalar Açık)**
   - Belirlenen saat aralıklarında (`focus_sessions` veya `phone_lock_enabled` açık olan ders/uyku/aile saatlerinde) tam ekran **Kısıtlama Kalkanı** devreye girer; yalnızca gelen aramalara cevap verilmesine izin verir.

## Çalıştırma

```bash
flutter pub get
flutter run
```
