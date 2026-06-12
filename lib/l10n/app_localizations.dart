import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  AppLocalizations(this.locale, this._labels);

  final Locale locale;
  final Map<String, String> _labels;

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const supportedLocales = <Locale>[
    Locale('en'),
    Locale('ar'),
    Locale('de'),
    Locale('el'),
    Locale('es'),
    Locale('fi'),
    Locale('fr', 'CH'),
    Locale('id'),
    Locale('it'),
    Locale('ko'),
    Locale('nl'),
    Locale('pl'),
    Locale('pt'),
    Locale('pt', 'BR'),
    Locale('ru'),
    Locale('zh', 'CN'),
  ];

  static const supportedLanguageTags = <String>[
    'en-US',
    'ar-AR',
    'de-DE',
    'el-GR',
    'es-ES',
    'fi-FI',
    'fr-CH',
    'in-ID',
    'it-IT',
    'kr-KR',
    'nl-NL',
    'pl-PL',
    'pt-PT',
    'pt-BR',
    'ru-RU',
    'zh-CN',
  ];

  static Locale localeFromLanguageTag(String? tag) {
    if (tag == null || tag.trim().isEmpty) {
      return WidgetsBinding.instance.platformDispatcher.locale;
    }
    final parts = tag.replaceAll('_', '-').split('-');
    final language = switch (parts.first.toLowerCase()) {
      'in' => 'id',
      'kr' => 'ko',
      final language => language,
    };
    return Locale(language, parts.length > 1 ? parts[1].toUpperCase() : null);
  }

  static String languageTagForLocale(Locale locale) {
    for (final tag in supportedLanguageTags) {
      final candidate = localeFromLanguageTag(tag);
      if (candidate.languageCode == locale.languageCode &&
          candidate.countryCode == locale.countryCode) {
        return tag;
      }
    }
    for (final tag in supportedLanguageTags) {
      if (localeFromLanguageTag(tag).languageCode == locale.languageCode) {
        return tag;
      }
    }
    return 'en-US';
  }

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  String _label(String key, String fallback) => _labels[key] ?? fallback;

  String get appTitle => 'RipMe';
  String get enterUrlToRip => 'Enter URL to rip';
  String get rip => 'Rip';
  String get stopRipping => 'Stop Ripping';
  String get queue => _label('queue', 'Queue');
  String get active => 'Active';
  String get done => 'Done';
  String get skipped => 'Skipped';
  String get failed => 'Failed';
  String get log => _label('Log', 'Log');
  String get history => _label('History', 'History');
  String get created => _label('created', 'Created');
  String get modified => _label('modified', 'Modified');
  String get config => _label('Configuration', 'Config');
  String get filterLog => 'Filter log';
  String get copy => 'Copy';
  String get clear => _label('clear', 'Clear');
  String get copyLogLine => 'Copy log line';
  String get clearHistory => 'Clear history';
  String get import => 'Import';
  String get export => 'Export';
  String get copyUrl => 'Copy URL';
  String get ripAgain => 'Rip again';
  String get reripChecked => _label('re-rip.checked', 'Re-rip Checked');
  String get historyCheckAll => _label('history.check.all', 'Check All');
  String get historyCheckNone => _label('history.check.none', 'Check None');
  String get historyCheckSelected =>
      _label('history.check.selected', 'Check Selected');
  String get historyUncheckSelected =>
      _label('history.uncheck.selected', 'Uncheck Selected');
  String get noHistoryToRerip => _label('history.load.none',
      'There are no history entries to re-rip. Rip some albums first');
  String get noCheckedHistoryToRerip => _label(
      'history.load.none.checked',
      "No history entries have been 'Checked' Check an entry by clicking the "
          'checkbox to the right of the URL or Right-click a URL to '
          'check/uncheck all items');
  String get remove => _label('remove', 'Remove');
  String get historyImported => 'History imported';
  String historyImportFailed(Object error) => 'History import failed: $error';
  String get historyExported => 'History exported';
  String historyExportFailed(Object error) => 'History export failed: $error';
  String get clearQueue => _label('queue.remove.all', 'Clear queue');
  String get clearQueueConfirmation => _label('queue.validation',
      'Are you sure you want to remove all elements from the queue?');
  String get moveUp => 'Move up';
  String get moveDown => 'Move down';
  String get removeFromQueue => 'Remove from queue';
  String get files => 'Files';
  String get saveDirectory => _label('select.save.dir', 'Save directory');
  String get defaultSaveDirectory => 'Default (Documents/rips)';
  String get storageAccessWasNotGranted => 'Storage access was not granted';
  String get overwriteExistingFiles =>
      _label('overwrite.existing.files', 'Overwrite existing files');
  String get preserveDownloadOrder =>
      _label('preserve.order', 'Preserve download order');
  String get saveAlbumTitlesAsFolders =>
      _label('save.album.titles', 'Save album titles as folders');
  String get saveUrlsOnly => _label('save.urls.only', 'Save URLs only');
  String get preferMp4OverGif =>
      _label('prefer.mp4.over.gif', 'Prefer MP4 over GIF');
  String get downloads => 'Downloads';
  String get maximumDownloadThreads =>
      _label('max.download.threads', 'Maximum download threads');
  String get retryDownloadCount =>
      _label('retry.download.count', 'Retry download count');
  String get waitBetweenRetriesMs =>
      _label('retry.sleep.mill', 'Wait between retries (ms)');
  String get pageTimeoutMs => _label('timeout.mill', 'Page timeout (ms)');
  String get downloadTimeoutMs => 'Download timeout (ms)';
  String get maximumFileSizeBytes => 'Maximum file size (bytes)';
  String get skipRetriesAfter404 => 'Skip retries after 404';
  String get ignoredExtensions => 'Ignored extensions';
  String get commaSeparatedExtensions => 'Comma-separated extensions';
  String get network => 'Network';
  String get useProxy => 'Use proxy';
  String get proxyHost => 'Proxy host';
  String get hostnameOrIpAddress => 'Hostname or IP address';
  String get proxyPort => 'Proxy port';
  String get proxyUsername => 'Proxy username';
  String get proxyPassword => 'Proxy password';
  String get optional => 'Optional';
  String get redditCookies => 'Reddit cookies';
  String get imgurCookies => 'Imgur cookies';
  String get eromeCookies => 'Erome cookies';
  String get soundgasmCookies => 'Soundgasm cookies';
  String get vidbleCookies => 'Vidble cookies';
  String get cookieHint => 'key=value; other=value';
  String get disableSslVerification =>
      _label('ssl.verify.off', 'Disable SSL verification');
  String get skipAlreadyDownloadedUrls => 'Skip already downloaded URLs';
  String get apiKeys => 'API Keys';
  String get twitterAuth => 'Twitter auth';
  String get configuredAuthToken => 'Configured auth token';
  String get twitterMaxRequests => 'Twitter max requests';
  String get ripRetweets => 'Rip retweets';
  String get excludeReplies => 'Exclude replies';
  String get tumblrApiKey => 'Tumblr API key';
  String get configuredApiKey => 'Configured API key';
  String get goneWildApiKey => 'GoneWild API key';
  String get eromeSession => 'Erome session';
  String get laravelSessionCookieValue => 'Laravel session cookie value';
  String get rememberUrlHistory => 'Remember URL history';
  String get warnBeforeDeletingHistory =>
      _label('history.warn.before.delete', 'Warn before deleting history');
  String get stopAfterAlreadySeenCount => 'Stop after already-seen count';
  String get clearDownloadedUrlHistory => 'Clear downloaded URL history';
  String get downloadedUrlHistoryCleared => 'Downloaded URL history cleared';
  String get importDownloadedUrlHistory => 'Import downloaded URL history';
  String get exportDownloadedUrlHistory => 'Export downloaded URL history';
  String get downloadedUrlHistoryImported => 'Downloaded URL history imported';
  String downloadedUrlHistoryImportFailed(Object error) =>
      'Downloaded URL history import failed: $error';
  String get downloadedUrlHistoryExported => 'Downloaded URL history exported';
  String downloadedUrlHistoryExportFailed(Object error) =>
      'Downloaded URL history export failed: $error';
  String get reddit => 'Reddit';
  String get filterByUpvotes => 'Filter by upvotes';
  String get minimumUpvotes => 'Minimum upvotes';
  String get maximumUpvotes => 'Maximum upvotes';
  String get useRedditPostSubfolders => 'Use Reddit post subfolders';
  String get app => 'App';
  String get language => 'Language';
  String get clipboardAutorip => 'Clipboard autorip';
  String get playSoundWhenRipCompletes =>
      _label('sound.when.rip.completes', 'Play sound when rip completes');
  String get currentVersion => _label('current.version', 'Current version');
  String get checkForUpdates =>
      _label('check.for.updates', 'Check for updates');
  String get autoUpdateNotAvailable =>
      'Auto-update has been replaced by GitHub releases';
  String get latestVersion => 'Latest version';
  String get updateAvailable => 'Update available';
  String get noUpdateAvailable => 'You are running the latest version';
  String get updateCheckFailed => 'Update check failed';
  String get openReleasePage => 'Open release page';
  String get cancel => 'Cancel';
  String get save => 'Save';
  String get none => 'None';
  String range(int min, int max) => 'Range: $min-$max';
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales
        .any((supported) => supported.languageCode == locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final labels = <String, String>{};
    labels.addAll(await _loadProperties('LabelsBundle.properties'));
    final localizedBundle = _bundleFor(locale);
    if (localizedBundle != null) {
      labels.addAll(await _loadProperties(localizedBundle));
    }
    return AppLocalizations(locale, labels);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;

  String? _bundleFor(Locale locale) {
    final language = locale.languageCode;
    final country = locale.countryCode;
    if (language == 'en') return 'LabelsBundle_en_US.properties';
    if (language == 'pt' && country == 'BR') {
      return 'LabelsBundle_pt_BR.properties';
    }
    if (language == 'pt') return 'LabelsBundle_pt_PT.properties';
    if (language == 'fr') return 'LabelsBundle_fr_CH.properties';
    if (language == 'zh') return 'LabelsBundle_zh_CN.properties';
    if (language == 'id') return 'LabelsBundle_in_ID.properties';
    if (language == 'ko') return 'LabelsBundle_kr_KR.properties';
    const languageBundles = {
      'ar': 'LabelsBundle_ar_AR.properties',
      'de': 'LabelsBundle_de_DE.properties',
      'el': 'LabelsBundle_el_GR.properties',
      'es': 'LabelsBundle_es_ES.properties',
      'fi': 'LabelsBundle_fi_FI.properties',
      'it': 'LabelsBundle_it_IT.properties',
      'nl': 'LabelsBundle_nl_NL.properties',
      'pl': 'LabelsBundle_pl_PL.properties',
      'ru': 'LabelsBundle_ru_RU.properties',
    };
    return languageBundles[language];
  }

  Future<Map<String, String>> _loadProperties(String fileName) async {
    try {
      final contents =
          await rootBundle.loadString('src/main/resources/$fileName');
      return _parseProperties(contents);
    } catch (_) {
      return const {};
    }
  }

  Map<String, String> _parseProperties(String contents) {
    final result = <String, String>{};
    for (final rawLine in _logicalLines(contents)) {
      final line = rawLine.trimLeft();
      if (line.isEmpty || line.startsWith('#') || line.startsWith('!')) {
        continue;
      }
      final separator = _propertySeparatorIndex(line);
      if (separator < 0) continue;
      final key = line.substring(0, separator).trim();
      var valueStart = separator + 1;
      if (line[separator] != '=' && line[separator] != ':') {
        while (valueStart < line.length &&
            (line[valueStart] == ' ' || line[valueStart] == '\t')) {
          valueStart++;
        }
        if (valueStart < line.length &&
            (line[valueStart] == '=' || line[valueStart] == ':')) {
          valueStart++;
        }
      }
      while (valueStart < line.length &&
          (line[valueStart] == ' ' || line[valueStart] == '\t')) {
        valueStart++;
      }
      final value = line.substring(valueStart);
      result[_decodePropertyEscapes(key)] = _decodePropertyEscapes(value);
    }
    return result;
  }

  List<String> _logicalLines(String contents) {
    final lines =
        contents.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');
    final result = <String>[];
    final buffer = StringBuffer();
    for (final line in lines) {
      if (buffer.isNotEmpty) {
        buffer.write(line.trimLeft());
      } else {
        buffer.write(line);
      }
      if (_continuesPropertyLine(buffer.toString())) {
        final current = buffer.toString();
        buffer
          ..clear()
          ..write(current.substring(0, current.length - 1));
      } else {
        result.add(buffer.toString());
        buffer.clear();
      }
    }
    if (buffer.isNotEmpty) {
      result.add(buffer.toString());
    }
    return result;
  }

  bool _continuesPropertyLine(String line) {
    var slashCount = 0;
    for (var i = line.length - 1; i >= 0 && line[i] == r'\'; i--) {
      slashCount++;
    }
    return slashCount.isOdd;
  }

  int _propertySeparatorIndex(String line) {
    var escaped = false;
    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      if (escaped) {
        escaped = false;
        continue;
      }
      if (char == r'\') {
        escaped = true;
        continue;
      }
      if (char == '=' || char == ':' || char == ' ' || char == '\t') {
        return i;
      }
    }
    return -1;
  }

  String _decodePropertyEscapes(String value) {
    final buffer = StringBuffer();
    for (var i = 0; i < value.length; i++) {
      final char = value[i];
      if (char != r'\' || i == value.length - 1) {
        buffer.write(char);
        continue;
      }
      final next = value[++i];
      switch (next) {
        case 't':
          buffer.write('\t');
          break;
        case 'n':
          buffer.write('\n');
          break;
        case 'r':
          buffer.write('\r');
          break;
        case 'f':
          buffer.write('\f');
          break;
        case 'u':
          if (i + 4 < value.length) {
            final hex = value.substring(i + 1, i + 5);
            final codeUnit = int.tryParse(hex, radix: 16);
            if (codeUnit != null) {
              buffer.writeCharCode(codeUnit);
              i += 4;
              break;
            }
          }
          buffer.write(r'\u');
          break;
        default:
          buffer.write(next);
      }
    }
    return buffer.toString();
  }
}
