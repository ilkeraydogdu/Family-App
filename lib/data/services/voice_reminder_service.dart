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

  String _selectedToneId = 'harmonic_chime';
  String get selectedToneId => _selectedToneId;

  bool _voiceTitleAfterChime = false;
  bool get voiceTitleAfterChime => _voiceTitleAfterChime;

  Timer? _hapticPulseTimer;
  final Map<int, Timer> _activeRepeatTimers = {};
  final Map<int, int> _remainingRepeats = {};
  final Map<String, Uint8List> _cachedWavMelodies = {};

  static const Map<String, String> alarmToneLabels = {
    'harmonic_chime': 'Huzur Melodisi (Polifonik Çan)',
    'classic_alarm': 'Klasik Dijital Sabah Alarmı',
    'gentle_piano': 'Akustik Piyano Uyandırma',
    'urgent_pulse': 'Servis & Ders Acil Zil Sesi',
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

  void setVoiceTitleOption(bool enabled) {
    _voiceTitleAfterChime = enabled;
  }

  /// Generates a 44.1kHz 16-bit mono PCM WAV polyphonic alarm melody in memory.
  Uint8List generateAlarmMelodyWav(String toneId) {
    if (_cachedWavMelodies.containsKey(toneId)) {
      return _cachedWavMelodies[toneId]!;
    }

    const int sampleRate = 22050;
    const double durationSeconds = 3.2;
    final int numSamples = (sampleRate * durationSeconds).toInt();
    final ByteData pcmData = ByteData(numSamples * 2);

    for (int i = 0; i < numSamples; i++) {
      final double t = i / sampleRate;
      double sample = 0.0;

      if (toneId == 'classic_alarm') {
        // Classic digital rhythmic alarm: 4 crisp pulses of 880Hz + 1760Hz per 1.6s cycle
        final double cyclePos = t % 1.6;
        final bool pulseOn = (cyclePos < 0.14) ||
            (cyclePos >= 0.24 && cyclePos < 0.38) ||
            (cyclePos >= 0.48 && cyclePos < 0.62) ||
            (cyclePos >= 0.72 && cyclePos < 0.88);
        if (pulseOn) {
          sample = 0.55 * math.sin(2 * math.pi * 880.0 * t) +
              0.30 * math.sin(2 * math.pi * 1760.0 * t) +
              0.15 * math.sin(2 * math.pi * 1320.0 * t);
        }
      } else if (toneId == 'gentle_piano') {
        // Warm ascending piano chords: Fmaj7 -> G6 -> Cmaj9
        final int step = (t / 0.52).floor() % 6;
        final List<double> freqs = [349.23, 440.0, 523.25, 587.33, 659.25, 783.99];
        final double f = freqs[step];
        final double localT = t % 0.52;
        final double env = math.exp(-3.8 * localT) * (1.0 - math.exp(-80.0 * localT));
        sample = env *
            (0.60 * math.sin(2 * math.pi * f * t) +
                0.25 * math.sin(2 * math.pi * (f * 1.5) * t) +
                0.15 * math.sin(2 * math.pi * (f * 2.0) * t));
      } else if (toneId == 'urgent_pulse') {
        // High-clarity dual chime for commute/class alert
        final int step = (t / 0.25).floor() % 8;
        if (step < 6) {
          final double f = (step % 2 == 0) ? 783.99 : 1046.50;
          final double localT = t % 0.25;
          final double env = math.exp(-4.5 * localT);
          sample = env *
              (0.65 * math.sin(2 * math.pi * f * t) +
                  0.35 * math.sin(2 * math.pi * (f * 2.0) * t));
        }
      } else {
        // 'harmonic_chime' (Default): Polyphonic C-major 9th bell arpeggio (C5 - E5 - G5 - B5 - D6 - C6)
        final List<double> notes = [523.25, 659.25, 783.99, 987.77, 1174.66, 1046.50];
        for (int n = 0; n < notes.length; n++) {
          final double noteStart = n * 0.42;
          if (t >= noteStart) {
            final double dt = t - noteStart;
            final double env = math.exp(-2.6 * dt) * (1.0 - math.exp(-90.0 * dt));
            final double f = notes[n];
            sample += env *
                (0.45 * math.sin(2 * math.pi * f * dt) +
                    0.22 * math.sin(2 * math.pi * f * 2.0 * dt) +
                    0.10 * math.sin(2 * math.pi * f * 3.0 * dt));
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
    header.setUint32(16, 16, Endian.little); // PCM chunk size
    header.setUint16(20, 1, Endian.little); // AudioFormat = 1 (PCM)
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

  /// Starts ringing the real melodic alarm loop (NO robotic paragraph reading!).
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

    // Immediate haptic + system alert pulse fallback
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

    // Optional short voice title announcement ONLY if explicitly enabled by user
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

    final toneName = alarmToneLabels[toneId] ?? 'Huzur Melodisi';
    return 'Alarm Çalıyor: "${block.title}" (${block.startTime}) • Melodi: $toneName ($attempt/${block.repeatCount})';
  }

  Future<void> stopAlarmRinging() async {
    _isRinging = false;
    _hapticPulseTimer?.cancel();
    _hapticPulseTimer = null;
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

  /// Starts repeating alarm cycle until user checks in ("Derse Geldim") or repeats finish.
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
