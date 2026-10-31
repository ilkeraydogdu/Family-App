# Family-App Pro — Çift & Aile Zaman Bloklama, Ortak Ajanda, Namaz Odaklı Planlama & Yaşam Düzeni (iOS & Android)

Eşlerin ve partnerlerin kendi telefonlarında kişisel `@kullanici_adi` hesaplarıyla oturum açarak hem **ortak planlarını, alışveriş/ev sorumluluklarını** hem de **birbirinden tamamen izole kişisel planlarını** gerçek zamanlı yönetebildiği; **Cupla**, **TimeTree**, **Structured**, **MyWaqt** ve **Pillars** standartlarını tek çatı altında birleştiren **Flutter + Supabase** mobil uygulaması.

---

## Global Rakip Analizi & Fark Yaratan Özellikler

| Özellik / Modül | Cupla / TimeTree | Structured | MyWaqt / Pillars | **Family-App Pro** |
| :--- | :---: | :---: | :---: | :---: |
| **Sıfır E-posta / Telefon İfşası (`@kullanici_adi`)** | ❌ | ❌ | ❌ | ✅ (`@ilker`, `@neslihan` ekosistemi) |
| **PostgreSQL RLS İle Kişisel Plan İzolasyonu** | Kısmi | Tek Kişilik | Tek Kişilik | ✅ (Kişisel planlar diğer üyeye asla görünmez) |
| **Ortak Bağlantıyı Duraklat / Kaldır / Onayla** | ❌ | ❌ | ❌ | ✅ (`Paylaşımı Duraklat`, `Bağlantıyı Kaldır / Sil`) |
| **Canlı Diyanet Namaz Vaktine Hizalı Saatlik Bloklar** | ❌ | ❌ | ✅ | ✅ (Sabah namazı, servis ve iş saatleri otomatik kayar) |
| **5 Vakit Günlük Namaz Eda Çetelesi (`0/5 Vakit`)** | ❌ | ❌ | ✅ | ✅ (`daily_prayer_logs` ile tek dokunuşla vakit işaretleme) |
| **Açık Kaynak Canlı Hadis & Dua + Ana Ekran Widget** | ❌ | ❌ | Kısmi | ✅ (`Sahîh-i Buhârî` & `Kur'an/Diyanet Meal API` + Native Widget) |
| **Polifonik Tam Ekran Çalan Saat Alarmı & Snooze** | ❌ | ❌ | ❌ | ✅ (16-bit PCM WAV polifonik melodi + Tam Ekran Alarm) |
| **+15 dk Akıllı Kaydır (Replan) & Hızlı Şablonlar** | ❌ | ✅ | ❌ | ✅ (Tek dokunuşla `+15 dk Kaydır` ve hazır rutin şablonları) |
| **Ortak Ev, Alışveriş & Eşe Anlık Not Panosu** | ✅ | ❌ | ❌ | ✅ (`shared_chores_and_notes` gerçek zamanlı ortak pano) |
| **İlaç & Su Hatırlatıcı + Telefon Kısıtlama Kalkanı** | ❌ | ❌ | ❌ | ✅ (`medication_reminders`, `water_trackers`, `focus_sessions`) |
| **KVKK / GDPR & App Store 5.1.1(v) Veri Silme** | ✅ | ✅ | ✅ | ✅ (Uygulama içi tek tuşla kişisel veri temizleme) |

---

## Mimari & Veritabanı Yapısı (Supabase PostgreSQL + RLS)

- **`public.families` & `public.family_members`:** Aile/çift çalışma alanı, `@username` kimlikleri ve `connection_status` (`connected` | `paused` | `removed`).
- **`public.schedule_blocks`:** Saatlik zaman blokları, canlı namaz vakti çapası (`is_prayer_anchored`, `prayer_name`, `prayer_offset_minutes`), tekrarlayan polifonik alarm ayarları (`remind_before_minutes`, `repeat_count`), alt görev tik listesi (`checklist_items`), ders sonu özeti (`completion_notes`) ve atlama nedeni (`skipReason`).
- **`public.shared_chores_and_notes`:** Eşler arası ortak market/alışveriş listesi, ev sorumlulukları, birlikte etkinlik fikirleri ve eşe anlık not panosu.
- **`public.daily_prayer_logs`:** Her üyenin kendi günlük 5 vakit namaz eda takibi (`Fajr`, `Dhuhr`, `Asr`, `Maghrib`, `Isha`).
- **`public.medication_reminders` & `public.water_trackers`:** Kişisel veya ortak ilaç/vitamin hatırlatıcıları ve günlük su tüketim takibi.
- **`public.focus_sessions`:** Belirlenen saatlerde telefonu kullanım dışı bırakan (yalnızca gelen aramalara izin veren) odak kalkanı kuralları.
- **`public.partner_invitations`:** `@kullanici_adi` tabanlı ortak ajanda davetleri, onaylama, geçici paylaşım duraklatma ve bağlantı silme.

---

## Çalıştırma & Doğrulama (iOS & Android)

```bash
flutter pub get
dart analyze --fatal-infos
flutter test test/widget_test.dart
flutter run
```
