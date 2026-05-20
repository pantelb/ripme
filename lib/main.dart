import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.light),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
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

class _MainWindowState extends State<MainWindow> with SingleTickerProviderStateMixin {
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
                  onPressed: ripManager.isRipping ? () => ripManager.stop() : null,
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
                HistoryView(history: ripManager.history, ripManager: ripManager),
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

class TabControllerWidget extends StatelessWidget implements PreferredSizeWidget {
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
  const HistoryView({super.key, required this.history, required this.ripManager});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
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
        Card(
          child: ListTile(
            title: const Text('Save Directory'),
            subtitle: Text(Utils.getConfigString('rips.directory', 'Default (Documents/rips)')!),
            trailing: const Icon(Icons.folder_open),
            onTap: () async {
              String? selectedDirectory = await FilePicker.getDirectoryPath();
              if (selectedDirectory != null) {
                await Utils.setConfigString('rips.directory', selectedDirectory);
                setState(() {});
              }
            },
          ),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Overwrite existing files'),
          secondary: const Icon(Icons.file_copy),
          value: Utils.getConfigBoolean('file.overwrite', false),
          onChanged: (value) async {
            await Utils.setConfigBoolean('file.overwrite', value);
            setState(() {});
          },
        ),
        SwitchListTile(
          title: const Text('Play sound when rip completes'),
          secondary: const Icon(Icons.volume_up),
          value: Utils.getConfigBoolean('play.sound', false),
          onChanged: (value) async {
            await Utils.setConfigBoolean('play.sound', value);
            setState(() {});
          },
        ),
         SwitchListTile(
          title: const Text('Dark Mode'),
          secondary: const Icon(Icons.dark_mode),
          value: Theme.of(context).brightness == Brightness.dark,
          onChanged: (value) {
            // Theme state usually handled at app level, for now just a toggle placeholder
          },
        ),
      ],
    );
  }
}
