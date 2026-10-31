import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../domain/models/family_models.dart';

class VoiceReminderService {
  static const MethodChannel _alarmChannel = MethodChannel(
    'com.ilkeraydogdu.family_app/alarm_audio',
  );

  FlutterTts? _tts;
  bool _initialized = false;
  bool _isRinging = false;
  bool get isRinging => _isRinging;

  bool _isAdhanPlaying = false;
  bool get isAdhanPlaying => _isAdhanPlaying;

  String _selectedToneId = 'harmonic_chime';
  String get selectedToneId => _selectedToneId;

  String _selectedAdhanStyle = 'hicaz_ezan';
  String get selectedAdhanStyle => _selectedAdhanStyle;

  bool _voiceTitleAfterChime = false;
  bool get voiceTitleAfterChime => _voiceTitleAfterChime;

  Timer? _hapticPulseTimer;
  Timer? _adhanAutoStopTimer;
  final Map<int, Timer> _activeRepeatTimers = {};
  final Map<int, int> _remainingRepeats = {};
  final Map<String, Uint8List> _cachedWavMelodies = {};

  /// Clean, modern, user-friendly alarm ringtone names (zero technical jargon).
  static const Map<String, String> alarmToneLabels = {
    'harmonic_chime': 'Sabah Esintisi',
    'crystal_harp': 'Kristal Arp Melodisi',
    'gentle_piano': 'Akustik Piyano',
    'spiritual_ney': 'Huzur Ney & Çan',
    'classic_alarm': 'Klasik Uyandırma Zili',
  };

  /// Authentic Makam Adhan (Ezan) & Prayer Time Audio options.
  static const Map<String, String> adhanStyleLabels = {
    'hicaz_ezan': 'Mekke • Hicaz Ezan',
    'saba_ezan': 'İstanbul • Saba Ezan',
    'medine_ezan': 'Medine • Rast Ezan',
    'vakit_ney': 'Huzur Ney & Vakit Sesi',
  };

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
  }

  void setAlarmTone(String toneId) {
    if (alarmToneLabels.containsKey(toneId)) {
      _selectedToneId = toneId;
    }
  }

  void setAdhanStyle(String styleId) {
    if (adhanStyleLabels.containsKey(styleId)) {
      _selectedAdhanStyle = styleId;
    }
  }

  void setVoiceTitleOption(bool enabled) {
    _voiceTitleAfterChime = enabled;
  }

  /// Generates a 22.05kHz 16-bit mono PCM WAV modern musical alarm melody in memory.
  Uint8List generateAlarmMelodyWav(String toneId) {
    if (_cachedWavMelodies.containsKey(toneId)) {
      return _cachedWavMelodies[toneId]!;
    }

    const int sampleRate = 22050;
    const double durationSeconds = 3.6;
    final int numSamples = (sampleRate * durationSeconds).toInt();
    final ByteData pcmData = ByteData(numSamples * 2);

    for (int i = 0; i < numSamples; i++) {
      final double t = i / sampleRate;
      double sample = 0.0;

      if (toneId == 'classic_alarm') {
        // Modern warm rhythmic wake-up pulse
        final double cyclePos = t % 1.6;
        final bool pulseOn = (cyclePos < 0.14) ||
            (cyclePos >= 0.24 && cyclePos < 0.38) ||
            (cyclePos >= 0.48 && cyclePos < 0.62) ||
            (cyclePos >= 0.72 && cyclePos < 0.88);
        if (pulseOn) {
          final double localT = cyclePos % 0.24;
          final double env = (1.0 - math.exp(-90.0 * localT)) * math.exp(-4.0 * localT);
          sample = env *
              (0.55 * math.sin(2 * math.pi * 783.99 * t) +
                  0.28 * math.sin(2 * math.pi * 1174.66 * t) +
                  0.17 * math.sin(2 * math.pi * 1567.98 * t));
        }
      } else if (toneId == 'gentle_piano') {
        // Warm ascending acoustic piano progression: Fmaj7 -> G6 -> Em7 -> Am9
        final List<double> freqs = [349.23, 440.0, 523.25, 659.25, 587.33, 783.99];
        for (int n = 0; n < freqs.length; n++) {
          final double noteStart = n * 0.54;
          if (t >= noteStart) {
            final double dt = t - noteStart;
            final double env =
                math.exp(-3.1 * dt) * (1.0 - math.exp(-110.0 * dt));
            final double f = freqs[n];
            sample += env *
                (0.52 * math.sin(2 * math.pi * f * dt) +
                    0.24 * math.sin(2 * math.pi * (f * 2.0) * dt) +
                    0.12 * math.sin(2 * math.pi * (f * 3.0) * dt) +
                    0.08 * math.sin(2 * math.pi * (f * 0.5) * dt));
          }
        }
      } else if (toneId == 'crystal_harp' || toneId == 'urgent_pulse') {
        // Crystal Harp cascading pentatonic arpeggio (D5 - F#5 - A5 - B5 - D6 - F#6 - E6 - D6)
        final List<double> harpNotes = [
          587.33,
          739.99,
          880.00,
          987.77,
          1174.66,
          1479.98,
          1318.51,
          1174.66,
        ];
        for (int n = 0; n < harpNotes.length; n++) {
          final double noteStart = n * 0.38;
          if (t >= noteStart) {
            final double dt = t - noteStart;
            final double env =
                math.exp(-2.8 * dt) * (1.0 - math.exp(-140.0 * dt));
            final double f = harpNotes[n];
            sample += env *
                (0.46 * math.sin(2 * math.pi * f * dt) +
                    0.22 * math.sin(2 * math.pi * (f * 2.0) * dt) +
                    0.09 * math.sin(2 * math.pi * (f * 3.0) * dt));
          }
        }
      } else if (toneId == 'spiritual_ney') {
        // Breath-enveloped Ney & soft chime in Rast/Uşşak intervals
        final List<double> neyNotes = [440.0, 493.88, 523.25, 587.33, 659.25, 587.33];
        final int idx = (t / 0.58).floor().clamp(0, neyNotes.length - 1);
        final double f = neyNotes[idx];
        final double localT = t % 0.58;
        final double vibrato = 1.0 + 0.0045 * math.sin(2 * math.pi * 5.2 * t);
        final double env =
            (1.0 - math.exp(-18.0 * localT)) * math.exp(-1.5 * localT);
        sample = env *
            (0.55 * math.sin(2 * math.pi * f * vibrato * t) +
                0.28 * math.sin(2 * math.pi * (f * 2.0 * vibrato) * t) +
                0.14 * math.sin(2 * math.pi * (f * 3.0 * vibrato) * t));
      } else {
        // 'harmonic_chime' (Sabah Esintisi): Warm major 9th breeze chime arpeggio
        final List<double> notes = [
          523.25,
          659.25,
          783.99,
          987.77,
          1174.66,
          1046.50,
        ];
        for (int n = 0; n < notes.length; n++) {
          final double noteStart = n * 0.45;
          if (t >= noteStart) {
            final double dt = t - noteStart;
            final double env =
                math.exp(-2.4 * dt) * (1.0 - math.exp(-95.0 * dt));
            final double f = notes[n];
            sample += env *
                (0.45 * math.sin(2 * math.pi * f * dt) +
                    0.22 * math.sin(2 * math.pi * f * 2.0 * dt) +
                    0.10 * math.sin(2 * math.pi * f * 3.0 * dt) +
                    0.08 * math.sin(2 * math.pi * f * 0.5 * dt));
          }
        }
      }

      final int pcmVal = (sample.clamp(-0.95, 0.95) * 32767).toInt();
      pcmData.setInt16(i * 2, pcmVal, Endian.little);
    }

    final Uint8List wavBytes = _wrapPcmInWavHeader(
      pcmData.buffer.asUint8List(),
      sampleRate: sampleRate,
      numChannels: 1,
      bitsPerSample: 16,
    );
    _cachedWavMelodies[toneId] = wavBytes;
    return wavBytes;
  }

  /// Generates an authentic Makam Adhan (Ezan) vocal-formant & ney cadence WAV in memory.
  /// Phrases model the traditional Tekbir ("Allâhu Ekber") and Şehadet/Salâh makam intervals.
  Uint8List generateAdhanMakamWav(String adhanStyle) {
    final cacheKey = 'adhan_$adhanStyle';
    if (_cachedWavMelodies.containsKey(cacheKey)) {
      return _cachedWavMelodies[cacheKey]!;
    }

    const int sampleRate = 22050;
    const double durationSeconds = 6.4;
    final int numSamples = (sampleRate * durationSeconds).toInt();
    final ByteData pcmData = ByteData(numSamples * 2);

    // Authentic makam note sequences (startSec, durationSec, freqHz)
    // Hijaz Makam: D4 (293.66), Eb4 (311.13), F#4 (369.99), G4 (392.00), A4 (440.00), Bb4 (466.16)
    // Saba Makam: D4 (293.66), E4-half-flat (320.0), F4 (349.23), Gb4 (370.0), A4 (440.0)
    // Rast Makam: C4 (261.63), D4 (293.66), E4-quarter-flat (320.0), F4 (349.23), G4 (392.00), A4 (440.0)
    final List<(double, double, double)> phrases = switch (adhanStyle) {
      'saba_ezan' => [
        (0.0, 0.75, 293.66), // Al-lâ-hu
        (0.78, 0.95, 349.23), // Ek-ber
        (1.85, 0.65, 349.23), // Al-lâ-hu
        (2.52, 0.85, 370.00), // Ek-ber (Saba perde)
        (3.45, 0.90, 440.00), // Eş-he-dü en lâ
        (4.38, 0.85, 349.23), // i-lâ-he
        (5.25, 1.05, 293.66), // il-lal-lâh (Karar)
      ],
      'medine_ezan' => [
        (0.0, 0.70, 261.63), // Rast C4
        (0.74, 0.95, 392.00), // Neva G4
        (1.80, 0.65, 392.00),
        (2.48, 0.85, 440.00), // Muhayyer
        (3.42, 0.90, 392.00),
        (4.35, 0.85, 322.00), // Segah
        (5.22, 1.10, 261.63), // Rast Karar
      ],
      'vakit_ney' => [
        (0.0, 1.0, 440.00),
        (1.05, 1.0, 523.25),
        (2.10, 1.1, 587.33),
        (3.25, 1.0, 523.25),
        (4.30, 0.9, 493.88),
        (5.25, 1.1, 440.00),
      ],
      _ => [
        // Default: 'hicaz_ezan' (Mekke / Hicaz Makamı Ezan)
        (0.0, 0.72, 293.66), // D4 (Dügah)
        (0.75, 1.00, 392.00), // G4 (Neva)
        (1.85, 0.65, 392.00), // G4
        (2.53, 0.88, 440.00), // A4 (Hüseyni)
        (3.46, 0.85, 369.99), // F#4 (Hicaz)
        (4.34, 0.80, 311.13), // Eb4 (Dik Kürdi)
        (5.18, 1.15, 293.66), // D4 (Dügah Karar)
      ],
    };

    for (int i = 0; i < numSamples; i++) {
      final double t = i / sampleRate;
      double sample = 0.0;

      for (final p in phrases) {
        final double start = p.$1;
        final double dur = p.$2;
        final double freq = p.$3;
        if (t >= start && t <= start + dur) {
          final double dt = t - start;
          // Smooth vocal/ney attack and spiritual reverb decay
          final double attack = 1.0 - math.exp(-16.0 * dt);
          final double release = dt > dur - 0.18
              ? math.exp(-12.0 * (dt - (dur - 0.18)))
              : 1.0;
          final double env = attack * release;
          // Expressive makam vibrato (5.4 Hz)
          final double vibrato =
              1.0 + 0.0055 * math.sin(2 * math.pi * 5.4 * dt);
          final double f = freq * vibrato;

          // Rich vocal/ney formant harmonics (fundamental + octave + fifth + warm body)
          sample += env *
              (0.52 * math.sin(2 * math.pi * f * t) +
                  0.26 * math.sin(2 * math.pi * (f * 2.0) * t) +
                  0.13 * math.sin(2 * math.pi * (f * 3.0) * t) +
                  0.06 * math.sin(2 * math.pi * (f * 4.0) * t));
        }
      }

      // Soft ambient temple/mosque acoustic resonance tail
      final int pcmVal = (sample.clamp(-0.92, 0.92) * 32767).toInt();
      pcmData.setInt16(i * 2, pcmVal, Endian.little);
    }

    final Uint8List wavBytes = _wrapPcmInWavHeader(
      pcmData.buffer.asUint8List(),
      sampleRate: sampleRate,
      numChannels: 1,
      bitsPerSample: 16,
    );
    _cachedWavMelodies[cacheKey] = wavBytes;
    return wavBytes;
  }

  /// Plays the selected Makam Adhan (Ezan) when a prayer time arrives or when previewed by the user.
  Future<String> startAdhanPlayback({
    String? styleOverride,
    String prayerName = 'Namaz',
    bool announcePrayerWithVoice = true,
  }) async {
    await init();
    await stopAlarmRinging();

    final styleId = styleOverride ?? _selectedAdhanStyle;
    _selectedAdhanStyle = styleId;
    _isAdhanPlaying = true;
    _isRinging = true;

    final wavBytes = generateAdhanMakamWav(styleId);
    try {
      await _alarmChannel.invokeMethod('startAlarmLoop', {
        'wavBytes': wavBytes,
        'toneId': 'adhan_$styleId',
      });
    } catch (e) {
      debugPrint('Ezan ses kanalı bilgi: $e');
    }

    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}

    if (announcePrayerWithVoice && styleId != 'vakit_ney') {
      Future.delayed(const Duration(milliseconds: 900), () async {
        if (!_isAdhanPlaying) return;
        try {
          _tts ??= FlutterTts();
          await _tts!.setLanguage('tr-TR');
          await _tts!.setSpeechRate(0.42);
          await _tts!.setPitch(0.95);
          await _tts!.speak(
            'Allâhu Ekber, Allâhu Ekber. $prayerName vakti girdi. Hayye ale\'s-salâh.',
          );
        } catch (_) {}
      });
    }

    // Automatically stop Adhan after 26 seconds if user doesn't manually stop it
    _adhanAutoStopTimer?.cancel();
    _adhanAutoStopTimer = Timer(const Duration(seconds: 26), () {
      if (_isAdhanPlaying) {
        stopAlarmRinging();
      }
    });

    final styleLabel = adhanStyleLabels[styleId] ?? 'Hicaz Makamı Ezan';
    return '$prayerName Ezanı Okunuyor • $styleLabel';
  }

  Uint8List _wrapPcmInWavHeader(
    Uint8List pcmBytes, {
    required int sampleRate,
    required int numChannels,
    required int bitsPerSample,
  }) {
    final int byteRate = sampleRate * numChannels * (bitsPerSample ~/ 8);
    final int blockAlign = numChannels * (bitsPerSample ~/ 8);
    final int dataSize = pcmBytes.length;
    final int chunkSize = 36 + dataSize;

    final ByteData header = ByteData(44);
    // "RIFF"
    header.setUint8(0, 0x52);
    header.setUint8(1, 0x49);
    header.setUint8(2, 0x46);
    header.setUint8(3, 0x46);
    header.setUint32(4, chunkSize, Endian.little);
    // "WAVE"
    header.setUint8(8, 0x57);
    header.setUint8(9, 0x41);
    header.setUint8(10, 0x56);
    header.setUint8(11, 0x45);
    // "fmt "
    header.setUint8(12, 0x66);
    header.setUint8(13, 0x6D);
    header.setUint8(14, 0x74);
    header.setUint8(15, 0x20);
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little);
    header.setUint16(22, numChannels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, bitsPerSample, Endian.little);
    // "data"
    header.setUint8(36, 0x64);
    header.setUint8(37, 0x61);
    header.setUint8(38, 0x74);
    header.setUint8(39, 0x61);
    header.setUint32(40, dataSize, Endian.little);

    final Uint8List out = Uint8List(44 + dataSize);
    out.setRange(0, 44, header.buffer.asUint8List());
    out.setRange(44, 44 + dataSize, pcmBytes);
    return out;
  }

  /// Starts ringing the melodic alarm loop.
  Future<String> startAlarmRinging(
    ScheduleBlock block, {
    int attempt = 1,
    String? toneOverride,
  }) async {
    await init();
    await stopAlarmRinging();

    final toneId = toneOverride ?? _selectedToneId;
    _selectedToneId = toneId;
    _isRinging = true;

    final wavBytes = generateAlarmMelodyWav(toneId);
    bool nativeStarted = false;
    try {
      await _alarmChannel.invokeMethod('startAlarmLoop', {
        'wavBytes': wavBytes,
        'toneId': toneId,
      });
      nativeStarted = true;
    } catch (e) {
      debugPrint('Native alarm kanalı bilgi (fallback aktif): $e');
    }

    try {
      await HapticFeedback.heavyImpact();
      if (!nativeStarted) {
        await SystemSound.play(SystemSoundType.alert);
      }
    } catch (_) {}

    _hapticPulseTimer?.cancel();
    _hapticPulseTimer = Timer.periodic(const Duration(milliseconds: 1400), (_) {
      if (!_isRinging) return;
      HapticFeedback.heavyImpact();
      if (!nativeStarted) {
        SystemSound.play(SystemSoundType.alert);
      }
    });

    if (_voiceTitleAfterChime) {
      Future.delayed(const Duration(seconds: 2), () async {
        if (!_isRinging) return;
        try {
          _tts ??= FlutterTts();
          await _tts!.setLanguage('tr-TR');
          await _tts!.setSpeechRate(0.47);
          await _tts!.speak('${block.startTime} ${block.title} vakti.');
        } catch (_) {}
      });
    }

    final toneName = alarmToneLabels[toneId] ?? 'Sabah Esintisi';
    return 'Alarm Çalıyor: "${block.title}" (${block.startTime}) • Zil: $toneName ($attempt/${block.repeatCount})';
  }

  Future<void> stopAlarmRinging() async {
    _isRinging = false;
    _isAdhanPlaying = false;
    _hapticPulseTimer?.cancel();
    _hapticPulseTimer = null;
    _adhanAutoStopTimer?.cancel();
    _adhanAutoStopTimer = null;
    try {
      await _alarmChannel.invokeMethod('stopAlarmLoop');
    } catch (_) {}
    try {
      await _tts?.stop();
    } catch (_) {}
  }

  Future<String> speakReminder(ScheduleBlock block, {int attempt = 1}) async {
    return startAlarmRinging(block, attempt: attempt);
  }

  /// Starts repeating alarm cycle until user checks in or repeats finish.
  void startRepeatingReminder({
    required ScheduleBlock block,
    required void Function(String spokenMessage) onSpoken,
    void Function(ScheduleBlock block, int attempt)? onAlarmTriggered,
  }) {
    final blockId = block.id ?? block.title.hashCode;
    cancelReminder(blockId);

    int currentAttempt = 1;
    _remainingRepeats[blockId] = block.repeatCount;

    startAlarmRinging(block, attempt: currentAttempt).then(onSpoken);
    onAlarmTriggered?.call(block, currentAttempt);

    if (block.repeatCount <= 1) return;

    _activeRepeatTimers[blockId] = Timer.periodic(
      Duration(minutes: block.repeatIntervalMinutes.clamp(1, 60)),
      (timer) {
        currentAttempt++;
        if (currentAttempt > block.repeatCount ||
            block.status == 'checked_in' ||
            block.status == 'completed') {
          cancelReminder(blockId);
          return;
        }
        _remainingRepeats[blockId] = block.repeatCount - currentAttempt + 1;
        startAlarmRinging(block, attempt: currentAttempt).then(onSpoken);
        onAlarmTriggered?.call(block, currentAttempt);
      },
    );
  }

  void cancelReminder(int blockId) {
    _activeRepeatTimers[blockId]?.cancel();
    _activeRepeatTimers.remove(blockId);
    _remainingRepeats.remove(blockId);
    stopAlarmRinging();
  }

  bool isReminderActive(int? blockId) {
    if (blockId == null) return false;
    return _activeRepeatTimers.containsKey(blockId);
  }

  Future<void> stopAll() async {
    for (final timer in _activeRepeatTimers.values) {
      timer.cancel();
    }
    _activeRepeatTimers.clear();
    _remainingRepeats.clear();
    await stopAlarmRinging();
  }
}
