import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'ripper/abstract_ripper.dart';
import 'ripper/ripper_factory.dart';
import 'ui/rip_status_message.dart';
import 'history_provider.dart';
import 'utils/utils.dart';

typedef RipperResolver = AbstractRipper? Function(Uri uri);
typedef CompletionSoundPlayer = Future<void> Function();

class RipManager extends ChangeNotifier {
  RipManager({
    RipperResolver? ripperResolver,
    CompletionSoundPlayer? completionSoundPlayer,
  })  : _ripperResolver = ripperResolver ?? RipperFactory.getRipper,
        _completionSoundPlayer =
            completionSoundPlayer ?? _playDefaultCompletionSound;

  final List<String> _queue = [];
  final List<RipStatusMessage> _logs = [];
  List<HistoryEntry> _history = [];
  final RipperResolver _ripperResolver;
  final CompletionSoundPlayer _completionSoundPlayer;

  bool _isRipping = false;
  AbstractRipper? _currentRipper;

  List<String> get queue => _queue;
  List<RipStatusMessage> get logs => _logs;
  List<HistoryEntry> get history => _history;
  bool get isRipping => _isRipping;

  Future<void> init() async {
    _history = await HistoryProvider.loadHistory();
    notifyListeners();
  }

  void addUrlToQueue(String url) {
    _queue.add(url);
    notifyListeners();
    if (!_isRipping) {
      _ripNext();
    }
  }

  void removeFromQueue(int index) {
    if (index >= 0 && index < _queue.length) {
      _queue.removeAt(index);
      notifyListeners();
    }
  }

  void stop() {
    _currentRipper?.stop();
    _isRipping = false;
    notifyListeners();
  }

  Future<void> _ripNext() async {
    if (_queue.isEmpty) {
      _isRipping = false;
      notifyListeners();
      return;
    }

    _isRipping = true;
    String urlText = _queue.removeAt(0);
    notifyListeners();

    Uri? uri = Uri.tryParse(urlText);
    if (uri == null) {
      _addLog(RipStatusMessage(RipStatus.ripErrored, "Invalid URL: $urlText"));
      _ripNext();
      return;
    }

    _currentRipper = _ripperResolver(uri);
    if (_currentRipper == null) {
      _addLog(RipStatusMessage(
          RipStatus.ripErrored, "No ripper found for $urlText"));
      _ripNext();
      return;
    }

    await _currentRipper!.setup();
    _currentRipper!.statusStream.listen((event) {
      _addLog(event);
      if (event.status == RipStatus.ripComplete) {
        unawaited(_playCompletionSoundIfEnabled());
        _addToHistory(urlText, event.object.toString());
      }
    });

    try {
      await _currentRipper!.rip();
    } catch (e) {
      _addLog(RipStatusMessage(RipStatus.ripErrored, e.toString()));
    } finally {
      _currentRipper!.dispose();
      _ripNext();
    }
  }

  void _addLog(RipStatusMessage msg) {
    _logs.add(msg);
    notifyListeners();
  }

  void _addToHistory(String url, String dir) {
    _history.insert(0, HistoryEntry(url: url, dir: dir, date: DateTime.now()));
    HistoryProvider.saveHistory(_history);
    notifyListeners();
  }

  Future<void> clearHistory() async {
    _history = [];
    await HistoryProvider.clearHistory();
    notifyListeners();
  }

  Future<void> _playCompletionSoundIfEnabled() async {
    if (!Utils.getConfigBoolean('play.sound', false)) return;
    try {
      await _completionSoundPlayer();
    } catch (e) {
      _addLog(RipStatusMessage(
          RipStatus.downloadWarn, 'Failed to play completion sound: $e'));
    }
  }

  static Future<void> _playDefaultCompletionSound() async {
    final player = AudioPlayer();
    await player.play(AssetSource('sounds/camera.wav'));
    unawaited(player.onPlayerComplete.first.then((_) => player.dispose()));
  }
}

class HistoryEntry {
  final String url;
  final String dir;
  final DateTime date;

  HistoryEntry({required this.url, required this.dir, required this.date});
}
