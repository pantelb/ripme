import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'rip_manager.dart';
import 'utils/utils.dart';

class HistoryProvider {
  static const String _key = 'rip_history';

  static Future<List<HistoryEntry>> loadHistory({
    Directory? workingDirectory,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final String? json = prefs.getString(_key);
    if (json != null) {
      return _decodeHistory(json, strictJavaShape: false);
    }

    final legacyHistory = Utils.getConfigList('download.history');
    if (legacyHistory.isNotEmpty) {
      return [
        for (final url in legacyHistory)
          HistoryEntry(url: url, dir: '', date: DateTime.now()),
      ];
    }

    if (workingDirectory != null) {
      return _guessHistory(workingDirectory);
    }
    final configuredPath = Utils.getConfigString('rips.directory', null);
    if (configuredPath == null) return <HistoryEntry>[];
    return _guessHistory(Directory(configuredPath));
  }

  static Future<void> saveHistory(List<HistoryEntry> history) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, exportHistory(history));
  }

  static String exportHistory(List<HistoryEntry> history) {
    return const JsonEncoder.withIndent('  ')
        .convert(history.map((e) => e.toJson()).toList());
  }

  static List<HistoryEntry> importHistory(String json) {
    return _decodeHistory(json, strictJavaShape: true);
  }

  static List<HistoryEntry> _decodeHistory(
    String json, {
    required bool strictJavaShape,
  }) {
    final decoded = jsonDecode(json);
    if (decoded is! List) {
      throw const FormatException('Expected a JSON history array');
    }
    if (!strictJavaShape) {
      return decoded.whereType<Map>().map(HistoryEntry.fromJson).toList();
    }

    return [
      for (var index = 0; index < decoded.length; index++)
        _strictJavaEntry(decoded[index], index),
    ];
  }

  static HistoryEntry _strictJavaEntry(Object? value, int index) {
    if (value is! Map) {
      throw FormatException('History entry $index must be a JSON object');
    }
    if (value['url'] is! String) {
      throw FormatException('History entry $index must contain string url');
    }
    if (value['startDate'] is! num) {
      throw FormatException(
        'History entry $index must contain numeric startDate',
      );
    }
    if (value['modifiedDate'] is! num) {
      throw FormatException(
        'History entry $index must contain numeric modifiedDate',
      );
    }
    return HistoryEntry.fromJson(value);
  }

  static Future<void> exportToFile(
      List<HistoryEntry> history, File file) async {
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }
    await file.writeAsString(exportHistory(history));
  }

  static Future<List<HistoryEntry>> importFromFile(File file) async {
    return importHistory(await file.readAsString());
  }

  static Future<List<HistoryEntry>> _guessHistory(Directory directory) async {
    if (!await directory.exists()) return <HistoryEntry>[];

    final history = <HistoryEntry>[];
    await for (final entity in directory.list()) {
      if (entity is! Directory) continue;
      try {
        final url = HistoryDirectoryGuesser.urlFromDirectoryName(entity.path);
        if (url != null) {
          history.add(HistoryEntry(url: url, dir: '', date: DateTime.now()));
        }
      } on RangeError {
        // Java can abort startup for malformed names. Flutter ignores them.
      } on UnsupportedError {
        // Java's Imgur subreddit branch mutates a fixed-size list and fails.
      }
    }
    return history;
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

class HistoryDirectoryGuesser {
  static String? urlFromDirectoryName(String directory) {
    return _urlFromImgurDirectoryName(directory) ??
        _urlFromImagefapDirectoryName(directory) ??
        _urlFromDeviantartDirectoryName(directory) ??
        _urlFromRedditDirectoryName(directory) ??
        _urlFromSiteDirectoryName(
          directory,
          'bfcakes',
          'http://www.bcfakes.com/celebritylist/',
        ) ??
        _urlFromSiteDirectoryName(
          directory,
          'drawcrowd',
          'http://drawcrowd.com/',
        ) ??
        _urlFromSiteDirectoryName(
          directory.replaceAll('-', '/'),
          'ehentai',
          'http://g.e-hentai.org/g/',
        ) ??
        _urlFromSiteDirectoryName(
          directory,
          'vinebox',
          'http://finebox.co/u/',
        ) ??
        _urlFromSiteDirectoryName(
          directory,
          'imgbox',
          'http://imgbox.com/g/',
        ) ??
        _urlFromSiteDirectoryName(
          directory,
          'modelmayhem',
          'http://www.modelmayhem.com/',
        );
  }

  static String? _urlFromSiteDirectoryName(
    String directory,
    String site,
    String before,
  ) {
    final prefix = '${site}_';
    if (!directory.startsWith(prefix)) return null;
    return '$before${directory.substring(prefix.length)}';
  }

  static String? _urlFromRedditDirectoryName(String directory) {
    if (!directory.startsWith('reddit_')) return null;
    final fields = _javaSplit(directory);
    switch (fields.first) {
      case 'sub':
        return 'http://reddit.com/r/$directory';
      case 'user':
        return 'http://reddit.com/user/$directory';
      case 'post':
        return 'http://reddit.com/comments/$directory';
    }
    return null;
  }

  static String? _urlFromImagefapDirectoryName(String directory) {
    if (!directory.startsWith('imagefap')) return null;
    final id = directory.substring('imagefap_'.length);
    final parameter = RegExp(r'^\d+$').hasMatch(id) ? 'gid' : 'pgid';
    return 'http://www.imagefap.com/gallery.php?$parameter=$id';
  }

  static String? _urlFromDeviantartDirectoryName(String directory) {
    if (!directory.startsWith('deviantart')) return null;
    final suffix = directory.substring('deviantart_'.length);
    if (!suffix.contains('_')) {
      return 'http://$suffix.deviantart.com/';
    }
    final fields = _javaSplit(suffix);
    return 'http://${fields[0]}.deviantart.com/gallery/${fields[1]}';
  }

  static String? _urlFromImgurDirectoryName(String directory) {
    if (!directory.startsWith('imgur_')) return null;
    if (directory.contains(' ')) {
      directory = directory.substring(0, directory.indexOf(' '));
    }
    final fields = _javaSplit(directory);
    final album = fields[1];
    final isSubreddit = (fields.contains('top') || fields.contains('new')) &&
        (fields.contains('year') ||
            fields.contains('month') ||
            fields.contains('week') ||
            fields.contains('all'));
    if (isSubreddit) {
      throw UnsupportedError(
        'Java Imgur history guessing mutates Arrays.asList',
      );
    }
    if (album.contains('-')) {
      return 'http://imgur.com/${album.replaceAll('-', ',')}';
    }
    if (album.length == 5 || album.length == 6) {
      return 'http://imgur.com/a/$album';
    }
    var url = 'http://$album.imgur.com/';
    if (fields.length > 2) {
      url += fields[2];
    }
    return url;
  }

  static List<String> _javaSplit(String value) {
    final fields = value.split('_');
    while (fields.isNotEmpty && fields.last.isEmpty) {
      fields.removeLast();
    }
    return fields;
  }
}
