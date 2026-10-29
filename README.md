# Family-App (Aile Düzeni, Ortak Ajanda, İlaç & Su Hatırlatıcı)

Eşlerin ve partnerlerin kendi telefonlarında kişisel hesaplarıyla oturum açarak hem **ortak planlarını** hem de **birbirinden bağımsız kişisel planlarını** gerçek zamanlı yönetebildiği, **yalnızca Android (`android/`) ve iOS (`ios/`)** platformları için optimize edilmiş **Flutter + Supabase** yaşam düzeni uygulaması.

## Öne Çıkan Özellikler

1. **Kişisel Üyelik (`Üye Ol / Giriş Yap`) ve Eş / Arkadaş Davet Sistemi (`partner_invitations`)**
   - Her kullanıcı kendi telefonunda bireysel hesabını oluşturabilir veya giriş yapabilir.
   - Aile davet kodu (`AYDOGDU26`) veya özel davet bağlantısıyla eşini, arkadaşını ya da aile üyesini davet ederek **Ortak Planlar** ve **Bağımsız Kişisel Planlar** oluşturabilir.

2. **İlaç & Vitamin Hatırlatıcı (`medication_reminders`) ve Su Takip Sistemi (`water_trackers`)**
   - **İlaç Hatırlatıcı:** Günlük ilaç ve takviyeleri (`Omega-3 & D3`, `Magnezyum`, `Demir & Folik Asit` vb.) saat, dozaj ve kullanım şekline (`Aç Karnına`, `Tok Karnına`, `Bol Su İle`) göre takip eder, cihaz bildirimi gönderir.
   - **Su Hatırlatıcı:** Günlük su hedefi (`2500 ml`), `+250 ml (1 Bardak)` / `+500 ml (Şişe)` hızlı ekleme butonları, ilerleme çubuğu ve periyodik su içme cihaz bildirimi sunar.

3. **Gerçek Cihaz Bildirimleri (`flutter_local_notifications`) ve İzin Yönetimi**
   - Uygulama içi uyarıların yanı sıra doğrudan **iOS ve Android işletim sistemi bildirim merkezine** (`UNUserNotificationCenter` / Android Notification Channel) bildirim gönderir ve gerekli bildirim/alarm izinlerini ister.

4. **Canlı Diyanet Namaz Vakitleri & Saatlik Ajanda (`schedule_blocks`)**
   - `05:00` uyanış, canlı Diyanet namaz vakitleri (`Sabah`, `Öğle`, `İkindi`, `Akşam`, `Yatsı`), namaz sonrası servis yürüyüşü (`06:45`), iş başlangıcı (`08:00`) ve gitar dersi (`09:00 - 11:00`) gibi saatlik blokları yönetir.
   - **"Derse Geldim / Başladım"** seçildiğinde tekrarlayan sesli (Türkçe TTS) ve cihaz bildirimlerini susturur.
   - Ders sonunda bir sonraki işe geçmeden önce **alt görev tik listesi (`checklist_items`)**, **neler yapıldığı özeti (`completion_notes`)** ve gidilemeyen dersler için **Atlanan Ders Takibi (`skipped`) + Telafi Et** akışı sunar.

5. **Minimal, Göz Yormayan Modern Tasarım & Özel Vektörel SVG İkonlar (`flutter_svg`)**
   - Emoji kullanılmadan tamamen özel tasarım vektörel SVG ikonlar (`AppSvgIcon`) ve göz yormayan minimal renk paletiyle tasarlanmıştır.

6. **Telefon Kısıtlama & Odak Kalkanı (`focus_sessions`)**
   - Belirlenen saat aralıklarında telefonu kullanım dışı bırakarak yalnızca gelen telefon aramalarına cevap verilmesine izin verir.

## Çalıştırma (Android & iOS)

```bash
flutter pub get
flutter run
```
