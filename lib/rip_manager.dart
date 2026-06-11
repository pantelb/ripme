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

class QueueSubmissionResult {
  const QueueSubmissionResult({
    required this.accepted,
    this.errors = const [],
  });

  final int accepted;
  final List<String> errors;
}

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

  bool addUrlToQueue(String url) {
    if (_queue.contains(url)) {
      _reportQueueError('This URL is already in queue: $url');
      return false;
    }

    _queue.add(url);
    notifyListeners();
    if (!_isRipping) {
      _ripNext();
    }
    return true;
  }

  QueueSubmissionResult submitManualUrl(String input) {
    final url = input.trim();
    if (url.isEmpty) {
      return const QueueSubmissionResult(accepted: 0);
    }
    if (!url.contains('{')) {
      final accepted = addUrlToQueue(url);
      return QueueSubmissionResult(
        accepted: accepted ? 1 : 0,
        errors: accepted ? const [] : [_statusText],
      );
    }

    final bracePattern = RegExp(r'\{[^{}]*\}');
    final braceMatches = bracePattern.allMatches(url).toList();
    final withoutGroups = url.replaceAll(bracePattern, '');
    if (braceMatches.isEmpty ||
        withoutGroups.contains('{') ||
        withoutGroups.contains('}')) {
      return _invalidRange(url);
    }

    final rangeParts = braceMatches.first
        .group(0)!
        .substring(1, braceMatches.first.group(0)!.length - 1)
        .split('-');
    if (rangeParts.length != 2) {
      return _invalidRange(url);
    }
    final rangeStart = int.tryParse(rangeParts[0]);
    final rangeEnd = int.tryParse(rangeParts[1]);
    if (rangeStart == null || rangeEnd == null || rangeStart > rangeEnd) {
      return _invalidRange(url);
    }

    var accepted = 0;
    final errors = <String>[];
    for (var value = rangeStart; value <= rangeEnd; value++) {
      final expanded = url.replaceAll(bracePattern, value.toString());
      if (!_canRip(expanded)) {
        final error = "Can't find ripper for $expanded";
        _reportQueueError(error);
        errors.add(error);
        continue;
      }
      if (addUrlToQueue(expanded)) {
        accepted++;
      } else {
        errors.add(_statusText);
      }
    }
    return QueueSubmissionResult(accepted: accepted, errors: errors);
  }

  QueueSubmissionResult _invalidRange(String url) {
    final error = 'Invalid URL range: $url';
    _reportQueueError(error);
    return QueueSubmissionResult(accepted: 0, errors: [error]);
  }

  bool _canRip(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return false;
    final ripper = _ripperResolver(uri);
    if (ripper == null) return false;
    ripper.dispose();
    return true;
  }

  void _reportQueueError(String error) {
    _statusText = error;
    _addLog(RipStatusMessage(RipStatus.ripErrored, error));
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

  Future<void> setHistoryEntrySelected(int index, bool selected) async {
    if (index < 0 || index >= _history.length) return;
    _history[index].selected = selected;
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
  final String title;
  final int count;
  final DateTime startDate;
  final DateTime modifiedDate;
  bool selected;

  HistoryEntry({
    required this.url,
    required this.dir,
    required this.date,
    this.title = '',
    this.count = 0,
    DateTime? startDate,
    DateTime? modifiedDate,
    this.selected = false,
  })  : startDate = startDate ?? date,
        modifiedDate = modifiedDate ?? date;

  Map<String, dynamic> toJson() => {
        'url': url,
        'dir': dir,
        'date': date.toIso8601String(),
        'startDate': startDate.millisecondsSinceEpoch,
        'modifiedDate': modifiedDate.millisecondsSinceEpoch,
        'title': title,
        'count': count,
        'selected': selected,
      };

  factory HistoryEntry.fromJson(Map<dynamic, dynamic> json) {
    final startDate = _historyDate(json['startDate']);
    final modifiedDate = _historyDate(json['modifiedDate']);
    final flutterDate = _historyDate(json['date']);
    final date = flutterDate ??
        modifiedDate ??
        startDate ??
        DateTime.fromMillisecondsSinceEpoch(0);

    return HistoryEntry(
      url: json['url']?.toString() ?? '',
      dir: json['dir']?.toString() ?? '',
      date: date,
      title: json['title']?.toString() ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
      startDate: startDate ?? date,
      modifiedDate: modifiedDate ?? date,
      selected: json['selected'] == true,
    );
  }

  static DateTime? _historyDate(Object? value) {
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
