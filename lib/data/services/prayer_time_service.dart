import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/models/family_models.dart';

class PrayerTimeService {
  final http.Client _client;

  PrayerTimeService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetches live prayer times using Turkey Diyanet İşleri Başkanlığı method (method=13).
  Future<PrayerTimesDay> fetchLivePrayerTimes({
    required String city,
    String country = 'Turkey',
    DateTime? date,
  }) async {
    final targetDate = date ?? DateTime.now();
    final dd = targetDate.day.toString().padLeft(2, '0');
    final mm = targetDate.month.toString().padLeft(2, '0');
    final yyyy = targetDate.year.toString();

    final uri =
        Uri.parse('https://api.aladhan.com/v1/timingsByCity/$dd-$mm-$yyyy')
            .replace(
              queryParameters: {
                'city': city,
                'country': country,
                'method': '13', // Diyanet İşleri Başkanlığı
              },
            );

    final response = await _client
        .get(uri, headers: const {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) {
      throw Exception(
        'Canlı namaz vakitleri alınamadı (HTTP ${response.statusCode})',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw const FormatException('Namaz vakti verisi boş döndü.');
    }

    final timings = data['timings'] as Map<String, dynamic>? ?? {};
    final dateNode = data['date'] as Map<String, dynamic>? ?? {};

    String cleanTime(dynamic raw, String fallback) {
      if (raw == null) return fallback;
      final str = raw.toString().trim();
      if (str.length >= 5) {
        return str.substring(0, 5);
      }
      return fallback;
    }

    return PrayerTimesDay(
      city: city,
      country: country,
      dateReadable: (dateNode['readable'] ?? '$dd.$mm.$yyyy').toString(),
      fajr: cleanTime(timings['Fajr'], '05:52'),
      sunrise: cleanTime(timings['Sunrise'], '07:18'),
      dhuhr: cleanTime(timings['Dhuhr'], '13:06'),
      asr: cleanTime(timings['Asr'], '16:08'),
      maghrib: cleanTime(timings['Maghrib'], '18:39'),
      isha: cleanTime(timings['Isha'], '19:59'),
    );
  }

  /// Adds [offsetMinutes] to an HH:mm time string and returns HH:mm.
  static String addMinutesToTime(String hhmm, int offsetMinutes) {
    final parts = hhmm.split(':');
    if (parts.length < 2) return hhmm;
    final hour = int.tryParse(parts[0]) ?? 6;
    final minute = int.tryParse(parts[1]) ?? 0;
    final totalMinutes = (hour * 60 + minute + offsetMinutes) % (24 * 60);
    final normalized = totalMinutes < 0 ? totalMinutes + 24 * 60 : totalMinutes;
    final newHour = (normalized ~/ 60).toString().padLeft(2, '0');
    final newMin = (normalized % 60).toString().padLeft(2, '0');
    return '$newHour:$newMin';
  }

  /// Calculates duration in minutes between startTime and endTime.
  static int durationMinutes(String startHhmm, String endHhmm) {
    final sParts = startHhmm.split(':');
    final eParts = endHhmm.split(':');
    if (sParts.length < 2 || eParts.length < 2) return 30;
    final sTotal =
        (int.tryParse(sParts[0]) ?? 0) * 60 + (int.tryParse(sParts[1]) ?? 0);
    final eTotal =
        (int.tryParse(eParts[0]) ?? 0) * 60 + (int.tryParse(eParts[1]) ?? 0);
    final diff = eTotal - sTotal;
    return diff > 0 ? diff : 30;
  }
}
