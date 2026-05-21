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
  String get remove => _label('remove', 'Remove');
  String get historyImported => 'History imported';
  String historyImportFailed(Object error) => 'History import failed: $error';
  String get historyExported => 'History exported';
  String historyExportFailed(Object error) => 'History export failed: $error';
  String get clearQueue => _label('queue.remove.all', 'Clear queue');
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
  String get cookieHint => 'key=value; other=value';
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
  String get clipboardAutorip => 'Clipboard autorip';
  String get playSoundWhenRipCompletes =>
      _label('sound.when.rip.completes', 'Play sound when rip completes');
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
    for (final rawLine in contents.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#') || line.startsWith('!')) {
        continue;
      }
      final separator = line.indexOf('=');
      if (separator < 0) continue;
      final key = line.substring(0, separator).trim();
      final value = line.substring(separator + 1).trim();
      result[key] = value.replaceAll(r'\n', '\n');
    }
    return result;
  }
}
