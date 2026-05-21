import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_version.dart';
import 'download_history_provider.dart';
import 'history_provider.dart';
import 'l10n/app_localizations.dart';
import 'rip_manager.dart';
import 'ui/rip_status_message.dart';
import 'update_checker.dart';
import 'utils/utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Utils.init();
  runApp(
    ChangeNotifierProvider(
      create: (context) => RipManager()..init(),
      child: const RipMeApp(),
    ),
  );
}

class RipMeApp extends StatelessWidget {
  const RipMeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue, brightness: Brightness.light),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: const MainWindow(),
    );
  }
}

class MainWindow extends StatefulWidget {
  const MainWindow({super.key});

  @override
  State<MainWindow> createState() => _MainWindowState();
}

class _MainWindowState extends State<MainWindow>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _urlController = TextEditingController();
  Timer? _clipboardTimer;
  String? _lastClipboardUrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _clipboardTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _checkClipboardAutorip(),
    );
  }

  @override
  void dispose() {
    _clipboardTimer?.cancel();
    _tabController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ripManager = Provider.of<RipManager>(context);
    final strings = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.appTitle),
        bottom: TabControllerWidget(tabController: _tabController),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      hintText: strings.enterUrlToRip,
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        _enqueueUrl(ripManager, value);
                        _urlController.clear();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    if (_urlController.text.isNotEmpty) {
                      _enqueueUrl(ripManager, _urlController.text);
                      _urlController.clear();
                    }
                  },
                  icon: const Icon(Icons.download),
                  label: Text(strings.rip),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed:
                      ripManager.isRipping ? () => ripManager.stop() : null,
                  icon: const Icon(Icons.stop, color: Colors.red),
                  tooltip: strings.stopRipping,
                ),
              ],
            ),
          ),
          _StatusSummary(ripManager: ripManager),
          if (ripManager.isRipping) const LinearProgressIndicator(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                LogView(logs: ripManager.logs, ripManager: ripManager),
                HistoryView(
                    history: ripManager.history, ripManager: ripManager),
                QueueView(queue: ripManager.queue, ripManager: ripManager),
                const ConfigurationView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _enqueueUrl(RipManager ripManager, String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return;
    ripManager.addUrlToQueue(trimmed);
  }

  Future<void> _checkClipboardAutorip() async {
    if (!mounted) return;
    if (!Utils.getConfigBoolean('clipboard.autorip', false)) return;
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text == _lastClipboardUrl) return;
    final uri = Uri.tryParse(text);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return;
    _lastClipboardUrl = text;
    if (!mounted) return;
    Provider.of<RipManager>(context, listen: false).addUrlToQueue(text);
  }
}

class _StatusSummary extends StatelessWidget {
  final RipManager ripManager;

  const _StatusSummary({required this.ripManager});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            _StatusChip(
                label: strings.queue,
                value: ripManager.queue.length.toString()),
            _StatusChip(
                label: strings.active,
                value: ripManager.activeDownloads.toString()),
            _StatusChip(
                label: strings.done,
                value: ripManager.completedDownloads.toString()),
            _StatusChip(
                label: strings.skipped,
                value: ripManager.skippedDownloads.toString()),
            _StatusChip(
                label: strings.failed,
                value: ripManager.failedDownloads.toString()),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatusChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Chip(
      visualDensity: VisualDensity.compact,
      label: Text('$label: $value'),
    );
  }
}

class TabControllerWidget extends StatelessWidget
    implements PreferredSizeWidget {
  final TabController tabController;
  const TabControllerWidget({super.key, required this.tabController});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return TabBar(
      controller: tabController,
      tabs: [
        Tab(text: strings.log, icon: const Icon(Icons.list_alt)),
        Tab(text: strings.history, icon: const Icon(Icons.history)),
        Tab(text: strings.queue, icon: const Icon(Icons.queue)),
        Tab(text: strings.config, icon: const Icon(Icons.settings)),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 20);
}

class LogView extends StatelessWidget {
  final List<RipStatusMessage> logs;
  final RipManager ripManager;
  const LogView({super.key, required this.logs, required this.ripManager});

  @override
  Widget build(BuildContext context) {
    return _FilteredLogView(logs: logs, ripManager: ripManager);
  }
}

class _FilteredLogView extends StatefulWidget {
  final List<RipStatusMessage> logs;
  final RipManager ripManager;

  const _FilteredLogView({required this.logs, required this.ripManager});

  @override
  State<_FilteredLogView> createState() => _FilteredLogViewState();
}

class _FilteredLogViewState extends State<_FilteredLogView> {
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final normalizedFilter = _filter.toLowerCase();
    final filteredLogs = normalizedFilter.isEmpty
        ? widget.logs
        : widget.logs
            .where((log) =>
                log.toString().toLowerCase().contains(normalizedFilter))
            .toList(growable: false);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 280,
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.filter_list),
                    hintText: strings.filterLog,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (value) => setState(() => _filter = value),
                ),
              ),
              OutlinedButton.icon(
                onPressed: filteredLogs.isEmpty
                    ? null
                    : () => Clipboard.setData(
                          ClipboardData(
                            text: filteredLogs
                                .map((log) => log.toString())
                                .join('\n'),
                          ),
                        ),
                icon: const Icon(Icons.copy),
                label: Text(strings.copy),
              ),
              OutlinedButton.icon(
                onPressed:
                    widget.logs.isEmpty ? null : widget.ripManager.clearLogs,
                icon: const Icon(Icons.clear_all),
                label: Text(strings.clear),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: filteredLogs.length,
            itemBuilder: (context, index) {
              final log = filteredLogs[index];
              return ListTile(
                dense: true,
                leading: Icon(_statusIcon(log.status)),
                title: SelectableText(
                  log.toString(),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'copy') {
                      Clipboard.setData(ClipboardData(text: log.toString()));
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                        value: 'copy', child: Text(strings.copyLogLine)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _statusIcon(RipStatus status) {
    switch (status) {
      case RipStatus.downloadComplete:
      case RipStatus.ripComplete:
        return Icons.check_circle_outline;
      case RipStatus.downloadErrored:
      case RipStatus.ripErrored:
        return Icons.error_outline;
      case RipStatus.downloadSkip:
      case RipStatus.downloadWarn:
        return Icons.warning_amber;
      case RipStatus.downloadStarted:
        return Icons.downloading;
      case RipStatus.loadingResource:
        return Icons.public;
    }
  }
}

class HistoryView extends StatelessWidget {
  final List<HistoryEntry> history;
  final RipManager ripManager;
  const HistoryView(
      {super.key, required this.history, required this.ripManager});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed:
                      history.isEmpty ? null : () => ripManager.clearHistory(),
                  icon: const Icon(Icons.delete_sweep),
                  label: Text(strings.clearHistory),
                ),
                OutlinedButton.icon(
                  onPressed: () => _importHistory(context),
                  icon: const Icon(Icons.upload_file),
                  label: Text(strings.import),
                ),
                OutlinedButton.icon(
                  onPressed:
                      history.isEmpty ? null : () => _exportHistory(context),
                  icon: const Icon(Icons.download),
                  label: Text(strings.export),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: history.length,
            itemBuilder: (context, index) {
              final entry = history[index];
              return ListTile(
                title: Text(entry.url),
                subtitle: Text(entry.dir),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(entry.date.toString().split(' ')[0]),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'copy':
                            Clipboard.setData(ClipboardData(text: entry.url));
                            break;
                          case 'rerip':
                            ripManager.addUrlToQueue(entry.url);
                            break;
                          case 'remove':
                            ripManager.removeHistoryEntry(index);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                            value: 'copy', child: Text(strings.copyUrl)),
                        PopupMenuItem(
                            value: 'rerip', child: Text(strings.ripAgain)),
                        PopupMenuItem(
                            value: 'remove', child: Text(strings.remove)),
                      ],
                    ),
                  ],
                ),
                leading: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => ripManager.removeHistoryEntry(index),
                ),
                onTap: () async {
                  final Uri uri = Uri.file(entry.dir);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
                onLongPress: () {
                  ripManager.addUrlToQueue(entry.url);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _importHistory(BuildContext context) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    final path = result?.files.single.path;
    if (path == null) return;
    try {
      await ripManager.replaceHistory(
        await HistoryProvider.importFromFile(File(path)),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).historyImported)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppLocalizations.of(context).historyImportFailed(e))),
        );
      }
    }
  }

  Future<void> _exportHistory(BuildContext context) async {
    final directory = await FilePicker.getDirectoryPath();
    if (directory == null) return;
    try {
      await HistoryProvider.exportToFile(
        history,
        File('$directory/ripme_history.json'),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).historyExported)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppLocalizations.of(context).historyExportFailed(e))),
        );
      }
    }
  }
}

class QueueView extends StatelessWidget {
  final List<String> queue;
  final RipManager ripManager;
  const QueueView({super.key, required this.queue, required this.ripManager});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: queue.isEmpty ? null : ripManager.clearQueue,
              icon: const Icon(Icons.delete_sweep),
              label: Text(strings.clearQueue),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: queue.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(queue[index]),
                leading: CircleAvatar(child: Text('${index + 1}')),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'copy':
                        Clipboard.setData(ClipboardData(text: queue[index]));
                        break;
                      case 'up':
                        ripManager.moveQueueItem(index, index - 1);
                        break;
                      case 'down':
                        ripManager.moveQueueItem(index, index + 1);
                        break;
                      case 'remove':
                        ripManager.removeFromQueue(index);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 'copy', child: Text(strings.copyUrl)),
                    PopupMenuItem(
                      value: 'up',
                      enabled: index > 0,
                      child: Text(strings.moveUp),
                    ),
                    PopupMenuItem(
                      value: 'down',
                      enabled: index < queue.length - 1,
                      child: Text(strings.moveDown),
                    ),
                    PopupMenuItem(
                      value: 'remove',
                      child: Text(strings.removeFromQueue),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class ConfigurationView extends StatefulWidget {
  const ConfigurationView({super.key});

  @override
  State<ConfigurationView> createState() => _ConfigurationViewState();
}

class _ConfigurationViewState extends State<ConfigurationView> {
  bool _checkingForUpdates = false;
  UpdateCheckResult? _updateCheckResult;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ConfigSection(
          title: strings.files,
          children: [
            ListTile(
              title: Text(strings.saveDirectory),
              subtitle: Text(Utils.getConfigString(
                  'rips.directory', strings.defaultSaveDirectory)!),
              leading: const Icon(Icons.folder_open),
              onTap: () async {
                if (!await Utils.ensureStorageAccess()) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(strings.storageAccessWasNotGranted)),
                    );
                  }
                  return;
                }
                String? selectedDirectory = await FilePicker.getDirectoryPath();
                if (selectedDirectory != null) {
                  await Utils.setConfigString(
                      'rips.directory', selectedDirectory);
                  setState(() {});
                }
              },
            ),
            _ConfigSwitch(
              title: strings.overwriteExistingFiles,
              icon: Icons.file_copy,
              keyName: 'file.overwrite',
              defaultValue: false,
              onChanged: _refresh,
            ),
            _ConfigSwitch(
              title: strings.preserveDownloadOrder,
              icon: Icons.format_list_numbered,
              keyName: 'download.save_order',
              defaultValue: true,
              onChanged: _refresh,
            ),
            _ConfigSwitch(
              title: strings.saveAlbumTitlesAsFolders,
              icon: Icons.drive_file_rename_outline,
              keyName: 'album_titles.save',
              defaultValue: true,
              onChanged: _refresh,
            ),
            _ConfigSwitch(
              title: strings.saveUrlsOnly,
              icon: Icons.link,
              keyName: 'urls_only.save',
              defaultValue: false,
              onChanged: _refresh,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ConfigSection(
          title: strings.downloads,
          children: [
            _ConfigIntegerTile(
              title: strings.maximumDownloadThreads,
              icon: Icons.downloading,
              keyName: 'threads.size',
              defaultValue: 5,
              min: 1,
              max: 64,
              onChanged: _refresh,
            ),
            _ConfigIntegerTile(
              title: strings.retryDownloadCount,
              icon: Icons.refresh,
              keyName: 'download.retries',
              defaultValue: 3,
              min: 0,
              max: 25,
              onChanged: _refresh,
            ),
            _ConfigIntegerTile(
              title: strings.waitBetweenRetriesMs,
              icon: Icons.timer,
              keyName: 'download.retry.sleep',
              defaultValue: 5000,
              min: 0,
              max: 600000,
              onChanged: _refresh,
            ),
            _ConfigIntegerTile(
              title: strings.pageTimeoutMs,
              icon: Icons.public,
              keyName: 'page.timeout',
              defaultValue: 5000,
              min: 100,
              max: 600000,
              onChanged: _refresh,
            ),
            _ConfigIntegerTile(
              title: strings.downloadTimeoutMs,
              icon: Icons.cloud_download,
              keyName: 'download.timeout',
              defaultValue: 60000,
              min: 1000,
              max: 3600000,
              onChanged: _refresh,
            ),
            _ConfigIntegerTile(
              title: strings.maximumFileSizeBytes,
              icon: Icons.sd_storage,
              keyName: 'download.max_size',
              defaultValue: 104857600,
              min: 1,
              max: 1099511627776,
              onChanged: _refresh,
            ),
            _ConfigSwitch(
              title: strings.skipRetriesAfter404,
              icon: Icons.error_outline,
              keyName: 'error.skip404',
              defaultValue: true,
              onChanged: _refresh,
            ),
            _ConfigStringTile(
              title: strings.ignoredExtensions,
              icon: Icons.block,
              keyName: 'download.ignore_extensions',
              defaultValue: '',
              helperText: strings.commaSeparatedExtensions,
              onChanged: _refresh,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ConfigSection(
          title: strings.network,
          children: [
            _ConfigSwitch(
              title: strings.useProxy,
              icon: Icons.settings_ethernet,
              keyName: 'proxy.enabled',
              defaultValue: false,
              onChanged: _refresh,
            ),
            _ConfigStringTile(
              title: strings.proxyHost,
              icon: Icons.dns,
              keyName: 'proxy.host',
              defaultValue: '',
              helperText: strings.hostnameOrIpAddress,
              onChanged: _refresh,
            ),
            _ConfigIntegerTile(
              title: strings.proxyPort,
              icon: Icons.numbers,
              keyName: 'proxy.port',
              defaultValue: 8080,
              min: 1,
              max: 65535,
              onChanged: _refresh,
            ),
            _ConfigStringTile(
              title: strings.proxyUsername,
              icon: Icons.person_outline,
              keyName: 'proxy.username',
              defaultValue: '',
              helperText: strings.optional,
              onChanged: _refresh,
            ),
            _ConfigStringTile(
              title: strings.proxyPassword,
              icon: Icons.password,
              keyName: 'proxy.password',
              defaultValue: '',
              helperText: strings.optional,
              onChanged: _refresh,
            ),
            _ConfigStringTile(
              title: strings.redditCookies,
              icon: Icons.cookie,
              keyName: 'cookies.reddit.com',
              defaultValue: '',
              helperText: strings.cookieHint,
              onChanged: _refresh,
            ),
            _ConfigStringTile(
              title: strings.imgurCookies,
              icon: Icons.cookie_outlined,
              keyName: 'cookies.imgur.com',
              defaultValue: '',
              helperText: strings.cookieHint,
              onChanged: _refresh,
            ),
            _ConfigStringTile(
              title: strings.eromeCookies,
              icon: Icons.cookie_outlined,
              keyName: 'cookies.erome.com',
              defaultValue: '',
              helperText: strings.cookieHint,
              onChanged: _refresh,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ConfigSection(
          title: strings.apiKeys,
          children: [
            _ConfigStringTile(
              title: strings.twitterAuth,
              icon: Icons.key,
              keyName: 'twitter.auth',
              defaultValue:
                  'VW9Ybjdjb1pkd2J0U3kwTUh2VXVnOm9GTzVQVzNqM29LQU1xVGhnS3pFZzhKbGVqbXU0c2lHQ3JrUFNNZm8=',
              helperText: strings.configuredAuthToken,
              onChanged: _refresh,
            ),
            _ConfigIntegerTile(
              title: strings.twitterMaxRequests,
              icon: Icons.speed,
              keyName: 'twitter.max_requests',
              defaultValue: 10,
              min: 1,
              max: 100000,
              onChanged: _refresh,
            ),
            _ConfigSwitch(
              title: strings.ripRetweets,
              icon: Icons.repeat,
              keyName: 'twitter.rip_retweets',
              defaultValue: false,
              onChanged: _refresh,
            ),
            _ConfigSwitch(
              title: strings.excludeReplies,
              icon: Icons.comments_disabled,
              keyName: 'twitter.exclude_replies',
              defaultValue: true,
              onChanged: _refresh,
            ),
            _ConfigStringTile(
              title: strings.tumblrApiKey,
              icon: Icons.key,
              keyName: 'tumblr.auth',
              defaultValue:
                  'JFNLu3CbINQjRdUvZibXW9VpSEVYYtiPJ86o8YmvgLZIoKyuNX',
              helperText: strings.configuredApiKey,
              onChanged: _refresh,
            ),
            _ConfigStringTile(
              title: strings.goneWildApiKey,
              icon: Icons.key,
              keyName: 'gw.api',
              defaultValue: 'gonewild',
              helperText: strings.configuredApiKey,
              onChanged: _refresh,
            ),
            _ConfigStringTile(
              title: strings.eromeSession,
              icon: Icons.vpn_key,
              keyName: 'erome.laravel_session',
              defaultValue: '',
              helperText: strings.laravelSessionCookieValue,
              onChanged: _refresh,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ConfigSection(
          title: strings.history,
          children: [
            _ConfigSwitch(
              title: strings.rememberUrlHistory,
              icon: Icons.history,
              keyName: 'remember.url_history',
              defaultValue: true,
              onChanged: _refresh,
            ),
            _ConfigIntegerTile(
              title: strings.stopAfterAlreadySeenCount,
              icon: Icons.stop_circle_outlined,
              keyName: 'history.end_rip_after_already_seen',
              defaultValue: 1000000000,
              min: 1,
              max: 1000000000,
              onChanged: _refresh,
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever),
              title: Text(strings.clearDownloadedUrlHistory),
              onTap: () async {
                await DownloadHistoryProvider.clear();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(strings.downloadedUrlHistoryCleared)),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: Text(strings.importDownloadedUrlHistory),
              onTap: () => _importDownloadedUrlHistory(context),
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: Text(strings.exportDownloadedUrlHistory),
              onTap: () => _exportDownloadedUrlHistory(context),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ConfigSection(
          title: strings.reddit,
          children: [
            _ConfigSwitch(
              title: strings.filterByUpvotes,
              icon: Icons.arrow_upward,
              keyName: 'reddit.rip_by_upvote',
              defaultValue: false,
              onChanged: _refresh,
            ),
            _ConfigIntegerTile(
              title: strings.minimumUpvotes,
              icon: Icons.exposure_plus_1,
              keyName: 'reddit.min_upvotes',
              defaultValue: 0,
              min: 0,
              max: 1000000000,
              onChanged: _refresh,
            ),
            _ConfigIntegerTile(
              title: strings.maximumUpvotes,
              icon: Icons.exposure,
              keyName: 'reddit.max_upvotes',
              defaultValue: 10000,
              min: 0,
              max: 1000000000,
              onChanged: _refresh,
            ),
            _ConfigSwitch(
              title: strings.useRedditPostSubfolders,
              icon: Icons.create_new_folder,
              keyName: 'reddit.use_sub_dirs',
              defaultValue: true,
              onChanged: _refresh,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ConfigSection(
          title: strings.app,
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(strings.currentVersion),
              subtitle: const Text('$appVersion+$appBuildNumber'),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.system_update_alt),
              title: Text(strings.autoUpdateNotAvailable),
              subtitle: Text(strings.openReleasePage),
              value: false,
              onChanged: null,
            ),
            ListTile(
              leading: const Icon(Icons.new_releases_outlined),
              title: Text(strings.checkForUpdates),
              subtitle: Text(_updateStatusText(strings)),
              trailing: _checkingForUpdates
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              onTap: _checkingForUpdates ? null : () => _checkForUpdates(),
            ),
            if (_updateCheckResult?.releaseUrl != null)
              ListTile(
                leading: const Icon(Icons.open_in_new),
                title: Text(strings.openReleasePage),
                subtitle: Text(_updateCheckResult!.releaseUrl.toString()),
                onTap: () => launchUrl(
                  _updateCheckResult!.releaseUrl,
                  mode: LaunchMode.externalApplication,
                ),
              ),
            _ConfigSwitch(
              title: strings.clipboardAutorip,
              icon: Icons.content_paste_search,
              keyName: 'clipboard.autorip',
              defaultValue: false,
              onChanged: _refresh,
            ),
            _ConfigSwitch(
              title: strings.playSoundWhenRipCompletes,
              icon: Icons.volume_up,
              keyName: 'play.sound',
              defaultValue: false,
              onChanged: _refresh,
            ),
          ],
        ),
      ],
    );
  }

  void _refresh() {
    setState(() {});
  }

  String _updateStatusText(AppLocalizations strings) {
    final result = _updateCheckResult;
    if (_checkingForUpdates) return '${strings.checkForUpdates}...';
    if (result == null) return releaseRepository;
    final latest = '${strings.latestVersion}: ${result.latestVersion}';
    if (result.updateAvailable) return '${strings.updateAvailable}. $latest';
    return '${strings.noUpdateAvailable}. $latest';
  }

  Future<void> _checkForUpdates() async {
    setState(() => _checkingForUpdates = true);
    try {
      final result = await const UpdateChecker().check();
      if (!mounted) return;
      setState(() => _updateCheckResult = result);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(_updateStatusText(AppLocalizations.of(context)))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('${AppLocalizations.of(context).updateCheckFailed}: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _checkingForUpdates = false);
      }
    }
  }

  Future<void> _importDownloadedUrlHistory(BuildContext context) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    final path = result?.files.single.path;
    if (path == null) return;
    try {
      await DownloadHistoryProvider.importFromFile(File(path));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  AppLocalizations.of(context).downloadedUrlHistoryImported)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)
                  .downloadedUrlHistoryImportFailed(e))),
        );
      }
    }
  }

  Future<void> _exportDownloadedUrlHistory(BuildContext context) async {
    final directory = await FilePicker.getDirectoryPath();
    if (directory == null) return;
    try {
      await DownloadHistoryProvider.exportToFile(
        File('$directory/ripme_downloaded_urls.json'),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  AppLocalizations.of(context).downloadedUrlHistoryExported)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)
                  .downloadedUrlHistoryExportFailed(e))),
        );
      }
    }
  }
}

class _ConfigSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _ConfigSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _ConfigSwitch extends StatelessWidget {
  final String title;
  final IconData icon;
  final String keyName;
  final bool defaultValue;
  final VoidCallback onChanged;

  const _ConfigSwitch({
    required this.title,
    required this.icon,
    required this.keyName,
    required this.defaultValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(title),
      secondary: Icon(icon),
      value: Utils.getConfigBoolean(keyName, defaultValue),
      onChanged: (value) async {
        await Utils.setConfigBoolean(keyName, value);
        onChanged();
      },
    );
  }
}

class _ConfigIntegerTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final String keyName;
  final int defaultValue;
  final int min;
  final int max;
  final VoidCallback onChanged;

  const _ConfigIntegerTile({
    required this.title,
    required this.icon,
    required this.keyName,
    required this.defaultValue,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final value = Utils.getConfigInteger(keyName, defaultValue);
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text('$value'),
      trailing: const Icon(Icons.edit),
      onTap: () => _editValue(context, value),
    );
  }

  Future<void> _editValue(BuildContext context, int currentValue) async {
    final strings = AppLocalizations.of(context);
    final controller = TextEditingController(text: '$currentValue');
    final nextValue = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              helperText: strings.range(min, max),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(strings.cancel),
            ),
            FilledButton(
              onPressed: () {
                final parsed = int.tryParse(controller.text.trim());
                if (parsed == null) return;
                Navigator.of(context).pop(parsed.clamp(min, max));
              },
              child: Text(strings.save),
            ),
          ],
        );
      },
    );

    if (nextValue != null) {
      await Utils.setConfigInteger(keyName, nextValue);
      onChanged();
    }
  }
}

class _ConfigStringTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final String keyName;
  final String defaultValue;
  final String helperText;
  final VoidCallback onChanged;

  const _ConfigStringTile({
    required this.title,
    required this.icon,
    required this.keyName,
    required this.defaultValue,
    required this.helperText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final value = Utils.getConfigString(keyName, defaultValue) ?? defaultValue;
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(value.isEmpty ? strings.none : value),
      trailing: const Icon(Icons.edit),
      onTap: () => _editValue(context, value),
    );
  }

  Future<void> _editValue(BuildContext context, String currentValue) async {
    final strings = AppLocalizations.of(context);
    final controller = TextEditingController(text: currentValue);
    final nextValue = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(helperText: helperText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(strings.cancel),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(controller.text.trim());
              },
              child: Text(strings.save),
            ),
          ],
        );
      },
    );

    if (nextValue != null) {
      await Utils.setConfigString(keyName, nextValue);
      onChanged();
    }
  }
}
