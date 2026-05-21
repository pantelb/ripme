import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'download_history_provider.dart';
import 'history_provider.dart';
import 'rip_manager.dart';
import 'ui/rip_status_message.dart';
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
      title: 'RipMe',
      debugShowCheckedModeBanner: false,
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('RipMe'),
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
                    decoration: const InputDecoration(
                      hintText: 'Enter URL to rip',
                      border: OutlineInputBorder(),
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
                  label: const Text('Rip'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed:
                      ripManager.isRipping ? () => ripManager.stop() : null,
                  icon: const Icon(Icons.stop, color: Colors.red),
                  tooltip: 'Stop Ripping',
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
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            _StatusChip(
                label: 'Queue', value: ripManager.queue.length.toString()),
            _StatusChip(
                label: 'Active', value: ripManager.activeDownloads.toString()),
            _StatusChip(
                label: 'Done', value: ripManager.completedDownloads.toString()),
            _StatusChip(
                label: 'Skipped',
                value: ripManager.skippedDownloads.toString()),
            _StatusChip(
                label: 'Failed', value: ripManager.failedDownloads.toString()),
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
    return TabBar(
      controller: tabController,
      tabs: const [
        Tab(text: 'Log', icon: Icon(Icons.list_alt)),
        Tab(text: 'History', icon: Icon(Icons.history)),
        Tab(text: 'Queue', icon: Icon(Icons.queue)),
        Tab(text: 'Config', icon: Icon(Icons.settings)),
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
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.filter_list),
                    hintText: 'Filter log',
                    border: OutlineInputBorder(),
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
                label: const Text('Copy'),
              ),
              OutlinedButton.icon(
                onPressed:
                    widget.logs.isEmpty ? null : widget.ripManager.clearLogs,
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear'),
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
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'copy', child: Text('Copy log line')),
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
                  label: const Text('Clear history'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _importHistory(context),
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Import'),
                ),
                OutlinedButton.icon(
                  onPressed:
                      history.isEmpty ? null : () => _exportHistory(context),
                  icon: const Icon(Icons.download),
                  label: const Text('Export'),
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
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'copy', child: Text('Copy URL')),
                        PopupMenuItem(value: 'rerip', child: Text('Rip again')),
                        PopupMenuItem(value: 'remove', child: Text('Remove')),
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
          const SnackBar(content: Text('History imported')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('History import failed: $e')),
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
          const SnackBar(content: Text('History exported')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('History export failed: $e')),
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: queue.isEmpty ? null : ripManager.clearQueue,
              icon: const Icon(Icons.delete_sweep),
              label: const Text('Clear queue'),
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
                    const PopupMenuItem(value: 'copy', child: Text('Copy URL')),
                    PopupMenuItem(
                      value: 'up',
                      enabled: index > 0,
                      child: const Text('Move up'),
                    ),
                    PopupMenuItem(
                      value: 'down',
                      enabled: index < queue.length - 1,
                      child: const Text('Move down'),
                    ),
                    const PopupMenuItem(
                      value: 'remove',
                      child: Text('Remove from queue'),
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
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ConfigSection(
          title: 'Files',
          children: [
            ListTile(
              title: const Text('Save directory'),
              subtitle: Text(Utils.getConfigString(
                  'rips.directory', 'Default (Documents/rips)')!),
              leading: const Icon(Icons.folder_open),
              onTap: () async {
                String? selectedDirectory = await FilePicker.getDirectoryPath();
                if (selectedDirectory != null) {
                  await Utils.setConfigString(
                      'rips.directory', selectedDirectory);
                  setState(() {});
                }
              },
            ),
            _ConfigSwitch(
              title: 'Overwrite existing files',
              icon: Icons.file_copy,
              keyName: 'file.overwrite',
              defaultValue: false,
              onChanged: _refresh,
            ),
            _ConfigSwitch(
              title: 'Preserve download order',
              icon: Icons.format_list_numbered,
              keyName: 'download.save_order',
              defaultValue: true,
              onChanged: _refresh,
            ),
            _ConfigSwitch(
              title: 'Save album titles as folders',
              icon: Icons.drive_file_rename_outline,
              keyName: 'album_titles.save',
              defaultValue: true,
              onChanged: _refresh,
            ),
            _ConfigSwitch(
              title: 'Save URLs only',
              icon: Icons.link,
              keyName: 'urls_only.save',
              defaultValue: false,
              onChanged: _refresh,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ConfigSection(
          title: 'Downloads',
          children: [
            _ConfigIntegerTile(
              title: 'Maximum download threads',
              icon: Icons.downloading,
              keyName: 'threads.size',
              defaultValue: 5,
              min: 1,
              max: 64,
              onChanged: _refresh,
            ),
            _ConfigIntegerTile(
              title: 'Retry download count',
              icon: Icons.refresh,
              keyName: 'download.retries',
              defaultValue: 3,
              min: 0,
              max: 25,
              onChanged: _refresh,
            ),
            _ConfigIntegerTile(
              title: 'Wait between retries (ms)',
              icon: Icons.timer,
              keyName: 'download.retry.sleep',
              defaultValue: 5000,
              min: 0,
              max: 600000,
              onChanged: _refresh,
            ),
            _ConfigIntegerTile(
              title: 'Page timeout (ms)',
              icon: Icons.public,
              keyName: 'page.timeout',
              defaultValue: 5000,
              min: 100,
              max: 600000,
              onChanged: _refresh,
            ),
            _ConfigIntegerTile(
              title: 'Download timeout (ms)',
              icon: Icons.cloud_download,
              keyName: 'download.timeout',
              defaultValue: 60000,
              min: 1000,
              max: 3600000,
              onChanged: _refresh,
            ),
            _ConfigIntegerTile(
              title: 'Maximum file size (bytes)',
              icon: Icons.sd_storage,
              keyName: 'download.max_size',
              defaultValue: 104857600,
              min: 1,
              max: 1099511627776,
              onChanged: _refresh,
            ),
            _ConfigSwitch(
              title: 'Skip retries after 404',
              icon: Icons.error_outline,
              keyName: 'error.skip404',
              defaultValue: true,
              onChanged: _refresh,
            ),
            _ConfigStringTile(
              title: 'Ignored extensions',
              icon: Icons.block,
              keyName: 'download.ignore_extensions',
              defaultValue: '',
              helperText: 'Comma-separated extensions',
              onChanged: _refresh,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ConfigSection(
          title: 'Network',
          children: [
            _ConfigSwitch(
              title: 'Use proxy',
              icon: Icons.settings_ethernet,
              keyName: 'proxy.enabled',
              defaultValue: false,
              onChanged: _refresh,
            ),
            _ConfigStringTile(
              title: 'Proxy host',
              icon: Icons.dns,
              keyName: 'proxy.host',
              defaultValue: '',
              helperText: 'Hostname or IP address',
              onChanged: _refresh,
            ),
            _ConfigIntegerTile(
              title: 'Proxy port',
              icon: Icons.numbers,
              keyName: 'proxy.port',
              defaultValue: 8080,
              min: 1,
              max: 65535,
              onChanged: _refresh,
            ),
            _ConfigStringTile(
              title: 'Proxy username',
              icon: Icons.person_outline,
              keyName: 'proxy.username',
              defaultValue: '',
              helperText: 'Optional',
              onChanged: _refresh,
            ),
            _ConfigStringTile(
              title: 'Proxy password',
              icon: Icons.password,
              keyName: 'proxy.password',
              defaultValue: '',
              helperText: 'Optional',
              onChanged: _refresh,
            ),
            _ConfigStringTile(
              title: 'Reddit cookies',
              icon: Icons.cookie,
              keyName: 'cookies.reddit.com',
              defaultValue: '',
              helperText: 'key=value; other=value',
              onChanged: _refresh,
            ),
            _ConfigStringTile(
              title: 'Imgur cookies',
              icon: Icons.cookie_outlined,
              keyName: 'cookies.imgur.com',
              defaultValue: '',
              helperText: 'key=value; other=value',
              onChanged: _refresh,
            ),
            _ConfigStringTile(
              title: 'Erome cookies',
              icon: Icons.cookie_outlined,
              keyName: 'cookies.erome.com',
              defaultValue: '',
              helperText: 'key=value; other=value',
              onChanged: _refresh,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ConfigSection(
          title: 'API Keys',
          children: [
            _ConfigStringTile(
              title: 'Twitter auth',
              icon: Icons.key,
              keyName: 'twitter.auth',
              defaultValue:
                  'VW9Ybjdjb1pkd2J0U3kwTUh2VXVnOm9GTzVQVzNqM29LQU1xVGhnS3pFZzhKbGVqbXU0c2lHQ3JrUFNNZm8=',
              helperText: 'Configured auth token',
              onChanged: _refresh,
            ),
            _ConfigIntegerTile(
              title: 'Twitter max requests',
              icon: Icons.speed,
              keyName: 'twitter.max_requests',
              defaultValue: 10,
              min: 1,
              max: 100000,
              onChanged: _refresh,
            ),
            _ConfigSwitch(
              title: 'Rip retweets',
              icon: Icons.repeat,
              keyName: 'twitter.rip_retweets',
              defaultValue: false,
              onChanged: _refresh,
            ),
            _ConfigSwitch(
              title: 'Exclude replies',
              icon: Icons.comments_disabled,
              keyName: 'twitter.exclude_replies',
              defaultValue: true,
              onChanged: _refresh,
            ),
            _ConfigStringTile(
              title: 'Tumblr API key',
              icon: Icons.key,
              keyName: 'tumblr.auth',
              defaultValue:
                  'JFNLu3CbINQjRdUvZibXW9VpSEVYYtiPJ86o8YmvgLZIoKyuNX',
              helperText: 'Configured API key',
              onChanged: _refresh,
            ),
            _ConfigStringTile(
              title: 'GoneWild API key',
              icon: Icons.key,
              keyName: 'gw.api',
              defaultValue: 'gonewild',
              helperText: 'Configured API key',
              onChanged: _refresh,
            ),
            _ConfigStringTile(
              title: 'Erome session',
              icon: Icons.vpn_key,
              keyName: 'erome.laravel_session',
              defaultValue: '',
              helperText: 'Laravel session cookie value',
              onChanged: _refresh,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ConfigSection(
          title: 'History',
          children: [
            _ConfigSwitch(
              title: 'Remember URL history',
              icon: Icons.history,
              keyName: 'remember.url_history',
              defaultValue: true,
              onChanged: _refresh,
            ),
            _ConfigIntegerTile(
              title: 'Stop after already-seen count',
              icon: Icons.stop_circle_outlined,
              keyName: 'history.end_rip_after_already_seen',
              defaultValue: 1000000000,
              min: 1,
              max: 1000000000,
              onChanged: _refresh,
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever),
              title: const Text('Clear downloaded URL history'),
              onTap: () async {
                await DownloadHistoryProvider.clear();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Downloaded URL history cleared')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: const Text('Import downloaded URL history'),
              onTap: () => _importDownloadedUrlHistory(context),
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Export downloaded URL history'),
              onTap: () => _exportDownloadedUrlHistory(context),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ConfigSection(
          title: 'Reddit',
          children: [
            _ConfigSwitch(
              title: 'Filter by upvotes',
              icon: Icons.arrow_upward,
              keyName: 'reddit.rip_by_upvote',
              defaultValue: false,
              onChanged: _refresh,
            ),
            _ConfigIntegerTile(
              title: 'Minimum upvotes',
              icon: Icons.exposure_plus_1,
              keyName: 'reddit.min_upvotes',
              defaultValue: 0,
              min: 0,
              max: 1000000000,
              onChanged: _refresh,
            ),
            _ConfigIntegerTile(
              title: 'Maximum upvotes',
              icon: Icons.exposure,
              keyName: 'reddit.max_upvotes',
              defaultValue: 10000,
              min: 0,
              max: 1000000000,
              onChanged: _refresh,
            ),
            _ConfigSwitch(
              title: 'Use Reddit post subfolders',
              icon: Icons.create_new_folder,
              keyName: 'reddit.use_sub_dirs',
              defaultValue: true,
              onChanged: _refresh,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ConfigSection(
          title: 'App',
          children: [
            _ConfigSwitch(
              title: 'Clipboard autorip',
              icon: Icons.content_paste_search,
              keyName: 'clipboard.autorip',
              defaultValue: false,
              onChanged: _refresh,
            ),
            _ConfigSwitch(
              title: 'Play sound when rip completes',
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
          const SnackBar(content: Text('Downloaded URL history imported')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Downloaded URL history import failed: $e')),
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
          const SnackBar(content: Text('Downloaded URL history exported')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Downloaded URL history export failed: $e')),
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
              helperText: 'Range: $min-$max',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final parsed = int.tryParse(controller.text.trim());
                if (parsed == null) return;
                Navigator.of(context).pop(parsed.clamp(min, max));
              },
              child: const Text('Save'),
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
    final value = Utils.getConfigString(keyName, defaultValue) ?? defaultValue;
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(value.isEmpty ? 'None' : value),
      trailing: const Icon(Icons.edit),
      onTap: () => _editValue(context, value),
    );
  }

  Future<void> _editValue(BuildContext context, String currentValue) async {
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
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(controller.text.trim());
              },
              child: const Text('Save'),
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
