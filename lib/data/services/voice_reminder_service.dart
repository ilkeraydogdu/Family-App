import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../domain/models/family_models.dart';

class VoiceReminderService {
  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;
  final Map<int, Timer> _activeRepeatTimers = {};
  final Map<int, int> _remainingRepeats = {};

  Future<void> init() async {
    if (_initialized) return;
    try {
      await _tts.setLanguage('tr-TR');
      await _tts.setSpeechRate(0.48);
      await _tts.setPitch(1.0);
      _initialized = true;
    } catch (e) {
      debugPrint('TTS başlatma uyarısı: $e');
    }
  }

  Future<String> speakReminder(ScheduleBlock block, {int attempt = 1}) async {
    await init();
    final ownerText = block.ownerRole == 'husband'
        ? 'İlker kanka'
        : block.ownerRole == 'wife'
        ? 'Değerli eşim'
        : 'Kanka ortak plan vakti';

    final message =
        '$ownerText, saat ${block.startTime} için "${block.title}" planın var. '
        '${block.remindBeforeMinutes} dakika önceden hatırlatma ($attempt/${block.repeatCount} tekrar). '
        'Başladığında uygulamadan "Geldim / Başladım" butonuna basabilirsin.';

    try {
      await _tts.stop();
      await _tts.speak(message);
    } catch (e) {
      debugPrint('TTS okuma uyarısı: $e');
    }
    return message;
  }

  /// Starts repeating voice reminder cycle until user checks in or repeats finish.
  void startRepeatingReminder({
    required ScheduleBlock block,
    required void Function(String spokenMessage) onSpoken,
  }) {
    final blockId = block.id ?? block.title.hashCode;
    cancelReminder(blockId);

    int currentAttempt = 1;
    _remainingRepeats[blockId] = block.repeatCount;

    speakReminder(block, attempt: currentAttempt).then(onSpoken);

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
        speakReminder(block, attempt: currentAttempt).then(onSpoken);
      },
    );
  }

  void cancelReminder(int blockId) {
    _activeRepeatTimers[blockId]?.cancel();
    _activeRepeatTimers.remove(blockId);
    _remainingRepeats.remove(blockId);
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
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
