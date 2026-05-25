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
    final lightScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2563EB),
      brightness: Brightness.light,
    );
    final darkScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF38BDF8),
      brightness: Brightness.dark,
    );

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
      theme: _buildTheme(lightScheme),
      darkTheme: _buildTheme(darkScheme),
      home: const MainWindow(),
    );
  }

  ThemeData _buildTheme(ColorScheme scheme) {
    final base = ThemeData(colorScheme: scheme, useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.52),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        dividerHeight: 0,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurfaceVariant,
        indicator: BoxDecoration(
          color: scheme.primaryContainer.withValues(alpha: 0.62),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        iconColor: scheme.primary,
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        space: 1,
      ),
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
        titleSpacing: 20,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _IconBadge(
              icon: Icons.cloud_download_outlined,
              color: Theme.of(context).colorScheme.primary,
              compact: true,
            ),
            const SizedBox(width: 10),
            Text(strings.appTitle),
          ],
        ),
        bottom: TabControllerWidget(tabController: _tabController),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _CommandBar(
              controller: _urlController,
              ripManager: ripManager,
              onSubmit: (value) {
                _enqueueUrl(ripManager, value);
                _urlController.clear();
              },
            ),
            _StatusSummary(ripManager: ripManager),
            _ProgressStrip(ripManager: ripManager),
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

class _CommandBar extends StatelessWidget {
  final TextEditingController controller;
  final RipManager ripManager;
  final ValueChanged<String> onSubmit;

  const _CommandBar({
    required this.controller,
    required this.ripManager,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 720;
              final field = TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: strings.enterUrlToRip,
                  prefixIcon: const Icon(Icons.link_outlined),
                  isDense: true,
                ),
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) onSubmit(value);
                },
              );
              final actions = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      if (controller.text.trim().isNotEmpty) {
                        onSubmit(controller.text);
                      }
                    },
                    icon: const Icon(Icons.download_for_offline_outlined),
                    label: Text(strings.rip),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed:
                        ripManager.isRipping ? () => ripManager.stop() : null,
                    icon: const Icon(Icons.stop_circle_outlined),
                    color: scheme.error,
                    tooltip: strings.stopRipping,
                  ),
                ],
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    field,
                    const SizedBox(height: 10),
                    Align(alignment: Alignment.centerRight, child: actions),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: field),
                  const SizedBox(width: 12),
                  actions,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StatusSummary extends StatelessWidget {
  final RipManager ripManager;

  const _StatusSummary({required this.ripManager});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusChip(
                icon: Icons.playlist_add_check_circle_outlined,
                label: strings.queue,
                value: ripManager.queue.length.toString(),
                color: scheme.primary,
              ),
              _StatusChip(
                icon: Icons.bolt_outlined,
                label: strings.active,
                value: ripManager.activeDownloads.toString(),
                color: const Color(0xFF0EA5E9),
              ),
              _StatusChip(
                icon: Icons.verified_outlined,
                label: strings.done,
                value: ripManager.completedDownloads.toString(),
                color: const Color(0xFF059669),
              ),
              _StatusChip(
                icon: Icons.low_priority_outlined,
                label: strings.skipped,
                value: ripManager.skippedDownloads.toString(),
                color: const Color(0xFFD97706),
              ),
              _StatusChip(
                icon: Icons.error_outline,
                label: strings.failed,
                value: ripManager.failedDownloads.toString(),
                color: scheme.error,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressStrip extends StatelessWidget {
  final RipManager ripManager;

  const _ProgressStrip({required this.ripManager});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  ripManager.statusText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ripManager.isRipping
                            ? scheme.onSurface
                            : scheme.onSurfaceVariant,
                      ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                ripManager.isRipping ? '${ripManager.progressPercent}%' : '',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: ripManager.progressValue,
            minHeight: 5,
            borderRadius: BorderRadius.circular(8),
            backgroundColor: scheme.surfaceContainerHighest,
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatusChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 36),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 7),
          Text(
            '$label:',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool compact;

  const _IconBadge({
    required this.icon,
    required this.color,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = compact ? 32.0 : 38.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Icon(icon, size: compact ? 18 : 21, color: color),
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      tabs: [
        Tab(text: strings.log, icon: const Icon(Icons.receipt_long_outlined)),
        Tab(text: strings.history, icon: const Icon(Icons.history_outlined)),
        Tab(
            text: strings.queue,
            icon: const Icon(Icons.pending_actions_outlined)),
        Tab(text: strings.config, icon: const Icon(Icons.tune_outlined)),
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
            .where(
                (log) => _logLine(log).toLowerCase().contains(normalizedFilter))
            .toList(growable: false);
    final scheme = Theme.of(context).colorScheme;
    final logText = filteredLogs.map(_logLine).join('\n');

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 320,
                    child: TextField(
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.manage_search_outlined),
                        hintText: strings.filterLog,
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
                                text: filteredLogs.map(_logLine).join('\n'),
                              ),
                            ),
                    icon: const Icon(Icons.content_copy_outlined),
                    label: Text(strings.copy),
                  ),
                  OutlinedButton.icon(
                    onPressed: widget.logs.isEmpty
                        ? null
                        : widget.ripManager.clearLogs,
                    icon: const Icon(Icons.cleaning_services_outlined),
                    label: Text(strings.clear),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: filteredLogs.isEmpty
              ? const _EmptyState(icon: Icons.receipt_long_outlined)
              : Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: SelectableText(
                        logText,
                        key: const Key('log_text_block'),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                              height: 1.35,
                            ),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  String _logLine(RipStatusMessage log) {
    final object = log.object.toString();
    switch (log.status) {
      case RipStatus.loadingResource:
      case RipStatus.downloadStarted:
        return 'Downloading $object';
      case RipStatus.downloadComplete:
        return 'Downloaded $object';
      case RipStatus.ripComplete:
        return 'Rip complete, saved to $object';
      case RipStatus.downloadErrored:
      case RipStatus.ripErrored:
      case RipStatus.downloadWarn:
      case RipStatus.downloadSkip:
        return object;
      case RipStatus.queueAdd:
        return 'Queued $object';
    }
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;

  const _EmptyState({required this.icon});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _IconBadge(icon: icon, color: scheme.primary),
          ],
        ),
      ),
    );
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
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
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
                  icon: const Icon(Icons.delete_sweep_outlined),
                  label: Text(strings.clearHistory),
                ),
                OutlinedButton.icon(
                  onPressed: () => _importHistory(context),
                  icon: const Icon(Icons.file_upload_outlined),
                  label: Text(strings.import),
                ),
                OutlinedButton.icon(
                  onPressed:
                      history.isEmpty ? null : () => _exportHistory(context),
                  icon: const Icon(Icons.file_download_outlined),
                  label: Text(strings.export),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: history.isEmpty
              ? const _EmptyState(icon: Icons.history_outlined)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: history.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final entry = history[index];
                    return Material(
                      color: scheme.surfaceContainerLow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: scheme.outlineVariant),
                      ),
                      child: ListTile(
                        leading: _IconBadge(
                          icon: Icons.folder_copy_outlined,
                          color: scheme.primary,
                          compact: true,
                        ),
                        title: Text(
                          entry.url,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          entry.dir,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(entry.date.toString().split(' ')[0]),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_horiz),
                              onSelected: (value) {
                                switch (value) {
                                  case 'copy':
                                    Clipboard.setData(
                                      ClipboardData(text: entry.url),
                                    );
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
                                  value: 'copy',
                                  child: Text(strings.copyUrl),
                                ),
                                PopupMenuItem(
                                  value: 'rerip',
                                  child: Text(strings.ripAgain),
                                ),
                                PopupMenuItem(
                                  value: 'remove',
                                  child: Text(strings.remove),
                                ),
                              ],
                            ),
                          ],
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
                      ),
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
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: queue.isEmpty ? null : ripManager.clearQueue,
              icon: const Icon(Icons.delete_sweep_outlined),
              label: Text(strings.clearQueue),
            ),
          ),
        ),
        Expanded(
          child: queue.isEmpty
              ? const _EmptyState(icon: Icons.pending_actions_outlined)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: queue.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    return Material(
                      color: scheme.surfaceContainerLow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: scheme.outlineVariant),
                      ),
                      child: ListTile(
                        title: Text(
                          queue[index],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        leading: CircleAvatar(
                          radius: 17,
                          backgroundColor: scheme.primaryContainer,
                          foregroundColor: scheme.onPrimaryContainer,
                          child: Text('${index + 1}'),
                        ),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_horiz),
                          onSelected: (value) {
                            switch (value) {
                              case 'copy':
                                Clipboard.setData(
                                  ClipboardData(text: queue[index]),
                                );
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
                            PopupMenuItem(
                              value: 'copy',
                              child: Text(strings.copyUrl),
                            ),
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
              leading: _IconBadge(
                icon: Icons.folder_open_outlined,
                color: Theme.of(context).colorScheme.primary,
                compact: true,
              ),
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
              icon: Icons.file_copy_outlined,
              keyName: 'file.overwrite',
              defaultValue: false,
              onChanged: _refresh,
            ),
            _ConfigSwitch(
              title: strings.preserveDownloadOrder,
              icon: Icons.format_list_numbered_outlined,
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
              icon: Icons.link_outlined,
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
              icon: Icons.speed_outlined,
              keyName: 'threads.size',
              defaultValue: 5,
              min: 1,
              max: 64,
              onChanged: _refresh,
            ),
            _ConfigIntegerTile(
              title: strings.retryDownloadCount,
              icon: Icons.refresh_outlined,
              keyName: 'download.retries',
              defaultValue: 3,
              min: 0,
              max: 25,
              onChanged: _refresh,
            ),
            _ConfigIntegerTile(
              title: strings.waitBetweenRetriesMs,
              icon: Icons.timer_outlined,
              keyName: 'download.retry.sleep',
              defaultValue: 5000,
              min: 0,
              max: 600000,
              onChanged: _refresh,
            ),
            _ConfigIntegerTile(
              title: strings.pageTimeoutMs,
              icon: Icons.travel_explore_outlined,
              keyName: 'page.timeout',
              defaultValue: 5000,
              min: 100,
              max: 600000,
              onChanged: _refresh,
            ),
            _ConfigIntegerTile(
              title: strings.downloadTimeoutMs,
              icon: Icons.cloud_download_outlined,
              keyName: 'download.timeout',
              defaultValue: 60000,
              min: 1000,
              max: 3600000,
              onChanged: _refresh,
            ),
            _ConfigIntegerTile(
              title: strings.maximumFileSizeBytes,
              icon: Icons.sd_storage_outlined,
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
              icon: Icons.settings_ethernet_outlined,
              keyName: 'proxy.enabled',
              defaultValue: false,
              onChanged: _refresh,
            ),
            _ConfigStringTile(
              title: strings.proxyHost,
              icon: Icons.dns_outlined,
              keyName: 'proxy.host',
              defaultValue: '',
              helperText: strings.hostnameOrIpAddress,
              onChanged: _refresh,
            ),
            _ConfigIntegerTile(
              title: strings.proxyPort,
              icon: Icons.numbers_outlined,
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
              icon: Icons.password_outlined,
              keyName: 'proxy.password',
              defaultValue: '',
              helperText: strings.optional,
              onChanged: _refresh,
            ),
            _ConfigStringTile(
              title: strings.redditCookies,
              icon: Icons.cookie_outlined,
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
            _ConfigStringTile(
              title: strings.soundgasmCookies,
              icon: Icons.cookie_outlined,
              keyName: 'cookies.soundgasm.net',
              defaultValue: '',
              helperText: strings.cookieHint,
              onChanged: _refresh,
            ),
            _ConfigStringTile(
              title: strings.vidbleCookies,
              icon: Icons.cookie_outlined,
              keyName: 'cookies.vidble.com',
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
              icon: Icons.key_outlined,
              keyName: 'twitter.auth',
              defaultValue:
                  'VW9Ybjdjb1pkd2J0U3kwTUh2VXVnOm9GTzVQVzNqM29LQU1xVGhnS3pFZzhKbGVqbXU0c2lHQ3JrUFNNZm8=',
              helperText: strings.configuredAuthToken,
              onChanged: _refresh,
            ),
            _ConfigIntegerTile(
              title: strings.twitterMaxRequests,
              icon: Icons.speed_outlined,
              keyName: 'twitter.max_requests',
              defaultValue: 10,
              min: 1,
              max: 100000,
              onChanged: _refresh,
            ),
            _ConfigSwitch(
              title: strings.ripRetweets,
              icon: Icons.repeat_outlined,
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
              icon: Icons.key_outlined,
              keyName: 'tumblr.auth',
              defaultValue:
                  'JFNLu3CbINQjRdUvZibXW9VpSEVYYtiPJ86o8YmvgLZIoKyuNX',
              helperText: strings.configuredApiKey,
              onChanged: _refresh,
            ),
            _ConfigStringTile(
              title: strings.goneWildApiKey,
              icon: Icons.key_outlined,
              keyName: 'gw.api',
              defaultValue: 'gonewild',
              helperText: strings.configuredApiKey,
              onChanged: _refresh,
            ),
            _ConfigStringTile(
              title: strings.eromeSession,
              icon: Icons.vpn_key_outlined,
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
              icon: Icons.history_outlined,
              keyName: 'remember.url_history',
              defaultValue: true,
              onChanged: _refresh,
            ),
            _ConfigSwitch(
              title: strings.skipAlreadyDownloadedUrls,
              icon: Icons.skip_next,
              keyName: 'history.skip_downloaded_urls',
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
              leading: _IconBadge(
                icon: Icons.delete_forever_outlined,
                color: Theme.of(context).colorScheme.error,
                compact: true,
              ),
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
              leading: _IconBadge(
                icon: Icons.file_upload_outlined,
                color: Theme.of(context).colorScheme.primary,
                compact: true,
              ),
              title: Text(strings.importDownloadedUrlHistory),
              onTap: () => _importDownloadedUrlHistory(context),
            ),
            ListTile(
              leading: _IconBadge(
                icon: Icons.file_download_outlined,
                color: Theme.of(context).colorScheme.primary,
                compact: true,
              ),
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
              icon: Icons.create_new_folder_outlined,
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
              leading: _IconBadge(
                icon: Icons.info_outline,
                color: Theme.of(context).colorScheme.primary,
                compact: true,
              ),
              title: Text(strings.currentVersion),
              subtitle: const Text('$appVersion+$appBuildNumber'),
            ),
            SwitchListTile(
              secondary: _IconBadge(
                icon: Icons.system_update_alt_outlined,
                color: Theme.of(context).colorScheme.primary,
                compact: true,
              ),
              title: Text(strings.autoUpdateNotAvailable),
              subtitle: Text(strings.openReleasePage),
              value: false,
              onChanged: null,
            ),
            ListTile(
              leading: _IconBadge(
                icon: Icons.new_releases_outlined,
                color: Theme.of(context).colorScheme.primary,
                compact: true,
              ),
              title: Text(strings.checkForUpdates),
              subtitle: Text(_updateStatusText(strings)),
              trailing: _checkingForUpdates
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_outlined),
              onTap: _checkingForUpdates ? null : () => _checkForUpdates(),
            ),
            if (_updateCheckResult?.releaseUrl != null)
              ListTile(
                leading: _IconBadge(
                  icon: Icons.open_in_new_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  compact: true,
                ),
                title: Text(strings.openReleasePage),
                subtitle: Text(_updateCheckResult!.releaseUrl.toString()),
                onTap: () => launchUrl(
                  _updateCheckResult!.releaseUrl,
                  mode: LaunchMode.externalApplication,
                ),
              ),
            _ConfigSwitch(
              title: strings.clipboardAutorip,
              icon: Icons.content_paste_search_outlined,
              keyName: 'clipboard.autorip',
              defaultValue: false,
              onChanged: _refresh,
            ),
            _ConfigSwitch(
              title: strings.playSoundWhenRipCompletes,
              icon: Icons.volume_up_outlined,
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
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
            ),
          ),
          Divider(color: scheme.outlineVariant),
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
      secondary: _IconBadge(
        icon: icon,
        color: Theme.of(context).colorScheme.primary,
        compact: true,
      ),
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
      leading: _IconBadge(
        icon: icon,
        color: Theme.of(context).colorScheme.primary,
        compact: true,
      ),
      title: Text(title),
      subtitle: Text('$value'),
      trailing: const Icon(Icons.edit_outlined),
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
      leading: _IconBadge(
        icon: icon,
        color: Theme.of(context).colorScheme.primary,
        compact: true,
      ),
      title: Text(title),
      subtitle: Text(value.isEmpty ? strings.none : value),
      trailing: const Icon(Icons.edit_outlined),
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
