import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'download_history_provider.dart';
import 'rip_manager.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
                        ripManager.addUrlToQueue(value);
                        _urlController.clear();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    if (_urlController.text.isNotEmpty) {
                      ripManager.addUrlToQueue(_urlController.text);
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
          if (ripManager.isRipping) const LinearProgressIndicator(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                LogView(logs: ripManager.logs),
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
  final List<dynamic> logs;
  const LogView({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: logs.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(
            logs[index].toString(),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        );
      },
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              const Spacer(),
              OutlinedButton.icon(
                onPressed:
                    history.isEmpty ? null : () => ripManager.clearHistory(),
                icon: const Icon(Icons.delete_sweep),
                label: const Text('Clear history'),
              ),
            ],
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
                trailing: Text(entry.date.toString().split(' ')[0]),
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
}

class QueueView extends StatelessWidget {
  final List<String> queue;
  final RipManager ripManager;
  const QueueView({super.key, required this.queue, required this.ripManager});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: queue.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(queue[index]),
          leading: CircleAvatar(child: Text('${index + 1}')),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              ripManager.removeFromQueue(index);
            },
          ),
        );
      },
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
              defaultValue: 0,
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
          ],
        ),
        const SizedBox(height: 16),
        _ConfigSection(
          title: 'History',
          children: [
            _ConfigSwitch(
              title: 'Skip already-downloaded URLs',
              icon: Icons.history,
              keyName: 'history.skip_downloaded_urls',
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
