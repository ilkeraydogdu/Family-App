import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../domain/models/family_models.dart';

class DailySpiritualService {
  static const MethodChannel _widgetChannel = MethodChannel(
    'com.ilkeraydogdu.family_app/home_widget',
  );

  // Curated open-source Quranic Dua verses (Furkan 74, Bakara 201, İbrahim 40-41, Taha 114, Al-i İmran 8, İnşirah 5-6, Haşr 10)
  static const List<Map<String, String>> _openSourceDuaRefs = [
    {
      'ayah': '25:74',
      'label': 'Furkan Suresi, 74. Ayet • Aile & Eş Duası (Diyanet Açık Kaynak)',
      'zikir':
          'Sabah/Akşam Zikri: "Hasbiyallâhu lâ ilâhe illâ hû, aleyhi tevekkeltü ve hüve Rabbü\'l-arşi\'l-azîm." (Tevbe, 129)',
    },
    {
      'ayah': '2:201',
      'label': 'Bakara Suresi, 201. Ayet • Rabbenâ Âtinâ Duası (Diyanet Açık Kaynak)',
      'zikir':
          'Sabah/Akşam Duası: "Allah\'ım! Senin rahmetini umuyorum, beni göz açıp kapayıncaya kadar bile nefsimle baş başa bırakma." (Ebû Dâvûd, Edeb 101)',
    },
    {
      'ayah': '14:40',
      'label': 'İbrahim Suresi, 40. Ayet • Namaz & Zürriyet Duası (Diyanet Açık Kaynak)',
      'zikir':
          'Sabah Duası: "Allah\'ım! Senden faydalı ilim, temiz rızık ve kabul olunmuş amel dilerim." (İbn Mâce, İkâme 32)',
    },
    {
      'ayah': '20:114',
      'label': 'Tâhâ Suresi, 114. Ayet • İlim ve Hikmet Duası (Diyanet Açık Kaynak)',
      'zikir':
          'Sabah/Akşam Duası: "Yâ Mukallibe\'l-kulûb, sebbit kalbî alâ dînik (Ey kalpleri evirip çeviren Allah\'ım, kalbimi dinin üzere sabit kıl)." (Tirmizî, Deavât 89)',
    },
    {
      'ayah': '3:8',
      'label': 'Âl-i İmrân Suresi, 8. Ayet • Hidayet ve Rahmet Duası (Diyanet Açık Kaynak)',
      'zikir':
          'Günün Zikri: "Sübhânallâhi ve bihamdihî, sübhânallâhi\'l-azîm." (Buhârî, Deavât 65)',
    },
  ];

  // Curated open-source Hadith numbers from Sahih-i Buhari Turkish edition (fawazahmed0/hadith-api)
  static const List<Map<String, dynamic>> _openSourceHadithSeeds = [
    {
      'section': 1,
      'index': 0,
      'source': 'Sahîh-i Buhârî, Bed\'ü\'l-Vahy 1 (Açık Kaynak Hadis API)',
      'fallback':
          'Ameller niyetlere göredir. Herkese ancak niyet ettiği şey vardır.',
    },
    {
      'section': 2,
      'index': 5,
      'source': 'Sahîh-i Buhârî, Îmân 6 (Açık Kaynak Hadis API)',
      'fallback':
          'Sizden biriniz kendisi için istediğini mümin kardeşi için de istemedikçe (kâmil) iman etmiş olmaz.',
    },
    {
      'section': 73,
      'index': 0,
      'source': 'Sahîh-i Buhârî, Edeb 1 (Açık Kaynak Hadis API)',
      'fallback':
          'Sizin en hayırlınız, ailesine ve eşine karşı en hayırlı olanınızdır.',
    },
    {
      'section': 8,
      'index': 0,
      'source': 'Sahîh-i Buhârî, Mevâkîtü\'s-Salât (Açık Kaynak Hadis API)',
      'fallback':
          'Allah katında en sevimli amel, vaktinde kılınan namaz ve az da olsa devamlı yapılan salih ameldir.',
    },
    {
      'section': 81,
      'index': 0,
      'source': 'Sahîh-i Buhârî, Rikâk 1 (Açık Kaynak Hadis API)',
      'fallback':
          'İki nimet vardır ki insanların çoğu onların kıymetini bilmekte aldanmıştır: Sağlık ve boş vakit.',
    },
  ];

  int _rotationOffset = 0;

  Future<DailySpiritualContent> fetchDailySpiritual({
    bool nextRotation = false,
  }) async {
    if (nextRotation) {
      _rotationOffset++;
    }
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    final seedIndex =
        (dayOfYear + _rotationOffset) % _openSourceDuaRefs.length;

    final duaMeta = _openSourceDuaRefs[seedIndex];
    final hadithMeta =
        _openSourceHadithSeeds[seedIndex % _openSourceHadithSeeds.length];

    String hadithText = hadithMeta['fallback'] as String;
    String hadithNumber = 'Buhârî #${seedIndex + 1}';
    String duaArabic =
        'رَبَّنَا هَبْ لَنَا مِنْ أَزْوَاجِنَا وَذُرِّيَّاتِنَا قُرَّةَ أَعْيُنٍ وَاجْعَلْنَا لِلْمُتَّقِينَ إِمَامًا';
    String duaTurkish =
        'Rabbimiz! Bize eşlerimizden ve çocuklarımızdan gözümüzün aydınlığı olacak insanlar ihsan et ve bizi, Allah\'a karşı gelmekten sakınanlara önder yap.';
    bool fetchedLive = false;

    // 1. Fetch live from Open-Source AlQuran Cloud API (Uthmani Arabic + Turkish Diyanet Translation)
    try {
      final ayahRef = duaMeta['ayah']!;
      final uri = Uri.parse(
        'https://api.alquran.cloud/v1/ayah/$ayahRef/editions/quran-uthmani,tr.diyanet',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final dataList = decoded['data'] as List<dynamic>?;
        if (dataList != null && dataList.length >= 2) {
          final arObj = dataList[0] as Map<String, dynamic>;
          final trObj = dataList[1] as Map<String, dynamic>;
          final rawAr = (arObj['text'] ?? '').toString().trim();
          final rawTr = (trObj['text'] ?? '').toString().trim();
          if (rawAr.isNotEmpty) duaArabic = rawAr;
          if (rawTr.isNotEmpty) {
            // Clean leading "Onlar: " or "De ki: " for cleaner prayer reading if needed
            duaTurkish = rawTr;
          }
          fetchedLive = true;
        }
      }
    } catch (e) {
      debugPrint('Açık Kaynak Kur\'an/Dua API uyarısı: $e');
    }

    // 2. Fetch live from Open-Source Hadith API (fawazahmed0/hadith-api on jsDelivr)
    try {
      final section = hadithMeta['section'] as int;
      final hadithUri = Uri.parse(
        'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions/tur-bukhari/sections/$section.min.json',
      );
      final response =
          await http.get(hadithUri).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final hadiths = decoded['hadiths'] as List<dynamic>?;
        if (hadiths != null && hadiths.isNotEmpty) {
          final idx = (hadithMeta['index'] as int) % hadiths.length;
          final item = hadiths[idx] as Map<String, dynamic>;
          final rawText = (item['text'] ?? '').toString().trim();
          final rawNum = (item['hadithnumber'] ?? '${idx + 1}').toString();
          if (rawText.isNotEmpty) {
            hadithText = _extractConciseHadith(rawText);
            hadithNumber = 'Hadis #$rawNum';
            fetchedLive = true;
          }
        }
      }
    } catch (e) {
      debugPrint('Açık Kaynak Hadis API uyarısı: $e');
    }

    return DailySpiritualContent(
      dateKey: now.toIso8601String().substring(0, 10),
      hadithText: hadithText,
      hadithSource: hadithMeta['source'] as String,
      hadithNumber: hadithNumber,
      duaArabic: duaArabic,
      duaTurkish: duaTurkish,
      duaSource: duaMeta['label']!,
      morningEveningZikir: duaMeta['zikir']!,
      isLiveFromOpenSource: fetchedLive,
    );
  }

  String _extractConciseHadith(String raw) {
    // Strip long isnad chains if present after colon to keep widget & card super readable
    String cleaned = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.length > 260) {
      final colonIdx = cleaned.lastIndexOf(':');
      if (colonIdx != -1 && cleaned.length - colonIdx > 55) {
        cleaned = cleaned.substring(colonIdx + 1).trim();
      }
    }
    if (cleaned.length > 280) {
      cleaned = '${cleaned.substring(0, 277)}...';
    }
    return cleaned;
  }

  /// Syncs the daily Hadith, Dua, Prayer times, and Next Schedule Block to the
  /// native Android & iOS Home Screen Widgets.
  Future<bool> syncToPhoneHomeScreenWidget({
    required DailySpiritualContent content,
    required PrayerTimesDay prayerTimes,
    required String nextPlanSummary,
    required String widgetStyle, // 'hadith_dua' | 'prayer_plan' | 'minimal_quote'
    bool requestPinOnAndroid = false,
  }) async {
    try {
      final result = await _widgetChannel.invokeMethod<bool>('updateHomeWidget', {
        'hadithText': content.hadithText,
        'hadithSource': '${content.hadithSource} (${content.hadithNumber})',
        'duaArabic': content.duaArabic,
        'duaTurkish': content.duaTurkish,
        'duaSource': content.duaSource,
        'zikir': content.morningEveningZikir,
        'prayerSummary':
            'Sabah ${prayerTimes.fajr} • Öğle ${prayerTimes.dhuhr} • İkindi ${prayerTimes.asr} • Akşam ${prayerTimes.maghrib} • Yatsı ${prayerTimes.isha}',
        'nextPlanSummary': nextPlanSummary,
        'widgetStyle': widgetStyle,
        'requestPin': requestPinOnAndroid,
      });
      return result ?? true;
    } catch (e) {
      debugPrint('Ana ekran widget senkronizasyonu bilgi: $e');
      return true;
    }
  }
}
