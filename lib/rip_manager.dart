import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'ripper/abstract_ripper.dart';
import 'ripper/ripper_factory.dart';
import 'ui/rip_status_message.dart';
import 'history_provider.dart';
import 'download_history_provider.dart';
import 'utils/utils.dart';

typedef RipperResolver = AbstractRipper? Function(Uri uri);
typedef CompletionSoundPlayer = Future<void> Function();
typedef RipStartNotifier = Future<void> Function(String url);

class QueueSubmissionResult {
  const QueueSubmissionResult({
    required this.accepted,
    this.errors = const [],
  });

  final int accepted;
  final List<String> errors;
}

enum HistoryReripResult {
  queued,
  emptyHistory,
  noneSelected,
}

class RipManager extends ChangeNotifier {
  RipManager({
    RipperResolver? ripperResolver,
    CompletionSoundPlayer? completionSoundPlayer,
    RipStartNotifier? ripStartNotifier,
  })  : _ripperResolver = ripperResolver ?? RipperFactory.getRipper,
        _completionSoundPlayer =
            completionSoundPlayer ?? _playDefaultCompletionSound,
        _ripStartNotifier = ripStartNotifier;

  final List<String> _queue = [];
  final List<RipStatusMessage> _logs = [];
  List<HistoryEntry> _history = [];
  final Set<int> _selectedQueueRows = <int>{};
  final Set<int> _selectedHistoryRows = <int>{};
  final RipperResolver _ripperResolver;
  final CompletionSoundPlayer _completionSoundPlayer;
  final RipStartNotifier? _ripStartNotifier;

  bool _isRipping = false;
  bool _stopRequested = false;
  int _ripRunId = 0;
  AbstractRipper? _currentRipper;
  String _statusText = 'Inactive';
  int _currentProgressPercent = 0;

  List<String> get queue => _queue;
  List<RipStatusMessage> get logs => _logs;
  List<HistoryEntry> get history => _history;
  Set<int> get selectedQueueRows => Set<int>.unmodifiable(_selectedQueueRows);
  Set<int> get selectedHistoryRows =>
      Set<int>.unmodifiable(_selectedHistoryRows);
  bool get isRipping => _isRipping;
  String get statusText => _statusText;
  double get progressValue {
    if (!_isRipping) return 0;
    return (_currentProgressPercent / 100).clamp(0, 1).toDouble();
  }

  int get progressPercent => _isRipping ? _currentProgressPercent : 0;
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
    _queue
      ..clear()
      ..addAll(Utils.getConfigList('queue'));
    notifyListeners();
  }

  bool addUrlToQueue(String url) {
    if (_queue.contains(url)) {
      _reportQueueError('This URL is already in queue: $url');
      return false;
    }

    _queue.add(url);
    _saveNonEmptyQueue();
    notifyListeners();
    if (!_isRipping) {
      _stopRequested = false;
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

  bool? validateUrlInput(String input) {
    var urlText = input.trim();
    if (urlText.isEmpty) return null;
    if (!urlText.startsWith('http')) {
      urlText = 'http://$urlText';
    }

    final uri = Uri.tryParse(urlText);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      _reportUrlValidationError('Invalid URL');
      return false;
    }

    AbstractRipper? ripper;
    try {
      ripper = _ripperResolver(uri);
      if (ripper == null) {
        _reportUrlValidationError('No ripper found');
        return false;
      }
      _statusText = '${ripper.getHost()} album detected';
      notifyListeners();
      return true;
    } on Exception catch (error) {
      _reportUrlValidationError(error.toString());
      return false;
    } finally {
      ripper?.dispose();
    }
  }

  void _reportUrlValidationError(String reason) {
    _statusText = "Can't rip this URL: $reason";
    notifyListeners();
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
      _selectedQueueRows.clear();
      _saveNonEmptyQueue();
      notifyListeners();
    }
  }

  void setQueueRowSelected(int index, bool selected) {
    if (index < 0 || index >= _queue.length) return;
    if (selected) {
      _selectedQueueRows.add(index);
    } else {
      _selectedQueueRows.remove(index);
    }
    notifyListeners();
  }

  void removeSelectedQueueRows() {
    final indices = _selectedQueueRows.toList()..sort();
    for (final index in indices.reversed) {
      if (index >= 0 && index < _queue.length) {
        _queue.removeAt(index);
      }
    }
    _selectedQueueRows.clear();
    _saveNonEmptyQueue();
    notifyListeners();
  }

  void moveQueueItem(int fromIndex, int toIndex) {
    if (fromIndex < 0 || fromIndex >= _queue.length) return;
    if (toIndex < 0 || toIndex >= _queue.length) return;
    final item = _queue.removeAt(fromIndex);
    _queue.insert(toIndex, item);
    _selectedQueueRows.clear();
    _saveNonEmptyQueue();
    notifyListeners();
  }

  void clearQueue() {
    _queue.clear();
    _selectedQueueRows.clear();
    _saveNonEmptyQueue();
    notifyListeners();
  }

  void clearLogs() {
    _logs.clear();
    notifyListeners();
  }

  void stop() {
    _stopRequested = true;
    _currentRipper?.stop();
    _isRipping = false;
    _statusText = 'Download interrupted';
    _currentProgressPercent = 0;
    _addLog(
      RipStatusMessage(RipStatus.ripErrored, 'Download interrupted'),
    );
  }

  Future<void> _ripNext() async {
    unawaited(Utils.setConfigList('queue', _queue));
    if (_queue.isEmpty) {
      _isRipping = false;
      _currentProgressPercent = 0;
      notifyListeners();
      return;
    }

    _isRipping = true;
    _statusText = 'Starting rip...';
    _currentProgressPercent = 0;
    String urlText = _queue.removeAt(0);
    _selectedQueueRows.clear();
    _saveNonEmptyQueue();
    notifyListeners();

    Uri? uri = Uri.tryParse(urlText);
    if (uri == null) {
      _statusText = 'Error: Invalid URL: $urlText';
      _addLog(RipStatusMessage(RipStatus.ripErrored, "Invalid URL: $urlText"));
      _ripNext();
      return;
    }

    final activeRipper = _ripperResolver(uri);
    if (activeRipper == null) {
      _statusText = 'Error: No ripper found for $urlText';
      _addLog(RipStatusMessage(
          RipStatus.ripErrored, "No ripper found for $urlText"));
      _ripNext();
      return;
    }
    final runId = ++_ripRunId;
    _currentRipper = activeRipper;
    var runItemCount = 0;

    await activeRipper.setup();
    activeRipper.statusStream.listen((event) {
      if (activeRipper.isStopped) return;
      if (event.status == RipStatus.queueAdd) {
        _queue.add(event.object.toString());
        _saveNonEmptyQueue();
      }
      if (event.status == RipStatus.downloadStarted ||
          event.status == RipStatus.downloadSkip) {
        runItemCount++;
      }
      _updateProgressFromEvent(event, activeRipper);
      if (event.status == RipStatus.totalBytes ||
          event.status == RipStatus.completedBytes) {
        notifyListeners();
      } else {
        _addLog(event);
      }
      if (event.status == RipStatus.ripComplete) {
        unawaited(_playCompletionSoundIfEnabled());
        _addToHistory(
          activeRipper.url.toString(),
          event.object.toString(),
          activeRipper,
          runItemCount == 0 ? 1 : runItemCount,
        );
      }
    });

    try {
      try {
        await _ripStartNotifier?.call(urlText);
      } catch (_) {
        // Desktop notification failures do not prevent the rip from starting.
      }
      await activeRipper.run();
    } catch (e) {
      _statusText = 'Error: $e';
      _addLog(RipStatusMessage(RipStatus.ripErrored, e.toString()));
    } finally {
      activeRipper.dispose();
      if (identical(_currentRipper, activeRipper)) {
        _currentRipper = null;
      }
      if (!_stopRequested && runId == _ripRunId) {
        _ripNext();
      }
    }
  }

  void _addLog(RipStatusMessage msg) {
    _logs.add(msg);
    notifyListeners();
  }

  void _saveNonEmptyQueue() {
    if (_queue.isNotEmpty) {
      unawaited(Utils.setConfigList('queue', _queue));
    }
  }

  void _updateProgressFromEvent(
    RipStatusMessage msg,
    AbstractRipper activeRipper,
  ) {
    _currentProgressPercent = activeRipper.completionPercentage;
    _statusText = activeRipper.statusText;
    final object = msg.object.toString();
    switch (msg.status) {
      case RipStatus.loadingResource:
      case RipStatus.downloadStarted:
      case RipStatus.downloadComplete:
      case RipStatus.downloadCompleteHistory:
      case RipStatus.downloadErrored:
      case RipStatus.downloadSkip:
      case RipStatus.downloadWarn:
        break;
      case RipStatus.ripErrored:
        _statusText = 'Error: $object';
        _currentProgressPercent = 0;
        break;
      case RipStatus.ripComplete:
      case RipStatus.queueAdd:
      case RipStatus.totalBytes:
      case RipStatus.completedBytes:
        break;
    }
  }

  void _addToHistory(
    String url,
    String dir,
    AbstractRipper ripper,
    int count,
  ) {
    final now = DateTime.now();
    final existingIndex = _history.indexWhere((entry) => entry.url == url);
    if (existingIndex >= 0) {
      final existing = _history[existingIndex];
      existing.count = count;
      existing.modifiedDate = now;
    } else {
      final entry = HistoryEntry(
        url: url,
        dir: dir,
        date: now,
        count: count,
      );
      _history.add(entry);
      unawaited(_populateHistoryTitle(entry, ripper));
    }
    unawaited(HistoryProvider.saveHistory(_history));
    notifyListeners();
  }

  Future<void> _populateHistoryTitle(
    HistoryEntry entry,
    AbstractRipper ripper,
  ) async {
    try {
      entry.title = await ripper.getAlbumTitle(ripper.url);
      await HistoryProvider.saveHistory(_history);
      notifyListeners();
    } on Exception {
      // Java leaves the title empty when album-title resolution fails.
    }
  }

  Future<void> clearHistory() async {
    _history = [];
    _selectedHistoryRows.clear();
    await Future.wait([
      HistoryProvider.clearHistory(),
      DownloadHistoryProvider.clear(),
    ]);
    notifyListeners();
  }

  Future<void> replaceHistory(List<HistoryEntry> history) async {
    _history = List<HistoryEntry>.of(history);
    _selectedHistoryRows.clear();
    await HistoryProvider.saveHistory(_history);
    notifyListeners();
  }

  Future<void> removeHistoryEntry(int index) async {
    if (index < 0 || index >= _history.length) return;
    _history.removeAt(index);
    _selectedHistoryRows.clear();
    await HistoryProvider.saveHistory(_history);
    notifyListeners();
  }

  void setHistoryRowSelected(int index, bool selected) {
    if (index < 0 || index >= _history.length) return;
    if (selected) {
      _selectedHistoryRows.add(index);
    } else {
      _selectedHistoryRows.remove(index);
    }
    notifyListeners();
  }

  Future<void> removeSelectedHistoryRows() async {
    final indices = _selectedHistoryRows.toList()..sort();
    for (final index in indices.reversed) {
      if (index >= 0 && index < _history.length) {
        _history.removeAt(index);
      }
    }
    _selectedHistoryRows.clear();
    await HistoryProvider.saveHistory(_history);
    notifyListeners();
  }

  Future<void> setHistoryEntrySelected(int index, bool selected) async {
    if (index < 0 || index >= _history.length) return;
    _history[index].selected = selected;
    await HistoryProvider.saveHistory(_history);
    notifyListeners();
  }

  Future<void> setAllHistoryEntriesSelected(bool selected) async {
    for (final entry in _history) {
      entry.selected = selected;
    }
    await HistoryProvider.saveHistory(_history);
    notifyListeners();
  }

  Future<void> setSelectedHistoryEntriesChecked(bool selected) async {
    for (final index in _selectedHistoryRows) {
      if (index >= 0 && index < _history.length) {
        _history[index].selected = selected;
      }
    }
    await HistoryProvider.saveHistory(_history);
    notifyListeners();
  }

  HistoryReripResult reripSelectedHistory() {
    if (_history.isEmpty) return HistoryReripResult.emptyHistory;
    final selectedUrls = _history
        .where((entry) => entry.selected)
        .map((entry) => entry.url)
        .toList();
    if (selectedUrls.isEmpty) return HistoryReripResult.noneSelected;

    _queue.addAll(selectedUrls);
    _saveNonEmptyQueue();
    notifyListeners();
    if (!_isRipping) {
      _stopRequested = false;
      _ripNext();
    }
    return HistoryReripResult.queued;
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
  String title;
  int count;
  final DateTime startDate;
  DateTime modifiedDate;
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
