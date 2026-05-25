import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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
  String _statusText = 'Inactive';
  int _currentRipTotal = 0;
  int _currentRipFinished = 0;

  List<String> get queue => _queue;
  List<RipStatusMessage> get logs => _logs;
  List<HistoryEntry> get history => _history;
  bool get isRipping => _isRipping;
  String get statusText => _statusText;
  double get progressValue {
    if (!_isRipping || _currentRipTotal == 0) return 0;
    final value = _currentRipFinished / _currentRipTotal;
    return value.clamp(0, 1).toDouble();
  }

  int get progressPercent => (progressValue * 100).round();
  int get completedDownloads =>
      _logs.where((msg) => msg.status == RipStatus.downloadComplete).length;
  int get failedDownloads =>
      _logs.where((msg) => msg.status == RipStatus.downloadErrored).length;
  int get skippedDownloads =>
      _logs.where((msg) => msg.status == RipStatus.downloadSkip).length;
  int get activeDownloads {
    final active =
        _logs.where((msg) => msg.status == RipStatus.downloadStarted).length -
            completedDownloads -
            failedDownloads;
    return active < 0 ? 0 : active;
  }

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

  void moveQueueItem(int fromIndex, int toIndex) {
    if (fromIndex < 0 || fromIndex >= _queue.length) return;
    if (toIndex < 0 || toIndex >= _queue.length) return;
    final item = _queue.removeAt(fromIndex);
    _queue.insert(toIndex, item);
    notifyListeners();
  }

  void clearQueue() {
    _queue.clear();
    notifyListeners();
  }

  void clearLogs() {
    _logs.clear();
    notifyListeners();
  }

  void stop() {
    _currentRipper?.stop();
    _isRipping = false;
    _statusText = 'Download interrupted';
    _currentRipTotal = 0;
    _currentRipFinished = 0;
    notifyListeners();
  }

  Future<void> _ripNext() async {
    if (_queue.isEmpty) {
      _isRipping = false;
      _currentRipTotal = 0;
      _currentRipFinished = 0;
      notifyListeners();
      return;
    }

    _isRipping = true;
    _statusText = 'Starting rip...';
    _currentRipTotal = 0;
    _currentRipFinished = 0;
    String urlText = _queue.removeAt(0);
    notifyListeners();

    Uri? uri = Uri.tryParse(urlText);
    if (uri == null) {
      _statusText = 'Error: Invalid URL: $urlText';
      _addLog(RipStatusMessage(RipStatus.ripErrored, "Invalid URL: $urlText"));
      _ripNext();
      return;
    }

    _currentRipper = _ripperResolver(uri);
    if (_currentRipper == null) {
      _statusText = 'Error: No ripper found for $urlText';
      _addLog(RipStatusMessage(
          RipStatus.ripErrored, "No ripper found for $urlText"));
      _ripNext();
      return;
    }

    await _currentRipper!.setup();
    _currentRipper!.statusStream.listen((event) {
      if (event.status == RipStatus.queueAdd) {
        _queue.add(event.object.toString());
      }
      _updateProgressFromEvent(event);
      _addLog(event);
      if (event.status == RipStatus.ripComplete) {
        unawaited(_playCompletionSoundIfEnabled());
        _addToHistory(urlText, event.object.toString());
      }
    });

    try {
      await _currentRipper!.rip();
    } catch (e) {
      _statusText = 'Error: $e';
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

  void _updateProgressFromEvent(RipStatusMessage msg) {
    final object = msg.object.toString();
    switch (msg.status) {
      case RipStatus.loadingResource:
        _statusText = 'Loading $object';
        break;
      case RipStatus.downloadStarted:
        _statusText = 'Downloading $object';
        _currentRipTotal++;
        break;
      case RipStatus.downloadComplete:
        _statusText = 'Downloaded $object';
        _currentRipFinished++;
        if (_currentRipFinished > _currentRipTotal) {
          _currentRipTotal = _currentRipFinished;
        }
        break;
      case RipStatus.downloadErrored:
        _statusText = 'Error: $object';
        _currentRipFinished++;
        if (_currentRipFinished > _currentRipTotal) {
          _currentRipTotal = _currentRipFinished;
        }
        break;
      case RipStatus.downloadSkip:
        _statusText = object;
        _currentRipTotal++;
        _currentRipFinished++;
        break;
      case RipStatus.downloadWarn:
        _statusText = object;
        break;
      case RipStatus.ripErrored:
        _statusText = 'Error: $object';
        _currentRipTotal = 0;
        _currentRipFinished = 0;
        break;
      case RipStatus.ripComplete:
        _statusText = 'Rip complete, saved to $object';
        if (_currentRipTotal > 0) {
          _currentRipFinished = _currentRipTotal;
        }
        break;
      case RipStatus.queueAdd:
        _statusText = 'Queued $object';
        break;
    }
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

  Future<void> replaceHistory(List<HistoryEntry> history) async {
    _history = List<HistoryEntry>.of(history);
    await HistoryProvider.saveHistory(_history);
    notifyListeners();
  }

  Future<void> removeHistoryEntry(int index) async {
    if (index < 0 || index >= _history.length) return;
    _history.removeAt(index);
    await HistoryProvider.saveHistory(_history);
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
    await SystemSound.play(SystemSoundType.alert);
  }
}

class HistoryEntry {
  final String url;
  final String dir;
  final DateTime date;

  HistoryEntry({required this.url, required this.dir, required this.date});

  Map<String, dynamic> toJson() => {
        'url': url,
        'dir': dir,
        'date': date.toIso8601String(),
      };

  factory HistoryEntry.fromJson(Map<dynamic, dynamic> json) {
    return HistoryEntry(
      url: json['url']?.toString() ?? '',
      dir: json['dir']?.toString() ?? '',
      date: DateTime.parse(json['date']?.toString() ??
          DateTime.fromMillisecondsSinceEpoch(
                  (json['modifiedDate'] as num?)?.toInt() ??
                      (json['startDate'] as num?)?.toInt() ??
                      0)
              .toIso8601String()),
    );
  }
}
