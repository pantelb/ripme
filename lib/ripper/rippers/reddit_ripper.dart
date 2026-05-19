import 'dart:io';
import '../ripper/abstract_json_ripper.dart';
import '../ui/rip_status_message.dart';
import '../utils/http_utils.dart';
import 'package:path/path.dart' as p;

class RedditRipper extends AbstractJSONRipper {
  RedditRipper(Uri url) : super(url);

  @override
  String getHost() => "reddit";

  @override
  bool canRip(Uri url) => url.host.endsWith("reddit.com");

  @override
  Future<String> getGID(Uri url) async {
    if (url.pathSegments.contains('user') || url.pathSegments.contains('u')) {
      return "user_\${url.pathSegments.last}";
    }
    return "post_\${url.pathSegments.contains('comments') ? url.pathSegments[url.pathSegments.indexOf('comments') + 1] : url.pathSegments.last}";
  }

  @override
  Future<void> parseJSON(Uri url) async {
    String jsonUrl = url.toString();
    if (!jsonUrl.contains('.json')) {
      if (jsonUrl.contains('?')) {
        jsonUrl = jsonUrl.replaceFirst('?', '.json?');
      } else {
        jsonUrl = "\$jsonUrl.json";
      }
    }

    dynamic json = await Http.getJSON(Uri.parse(jsonUrl));
    await _parseRedditJSON(json);
  }

  Future<void> _parseRedditJSON(dynamic json) async {
    List<dynamic> children = [];
    if (json is List) {
      children = json[0]['data']['children'];
    } else {
      children = json['data']['children'];
    }

    int index = 0;
    for (var child in children) {
      if (isStopped) break;
      var data = child['data'];
      String? imageUrl = data['url'];
      if (imageUrl != null && _isImage(imageUrl)) {
        index++;
        Uri imageUri = Uri.parse(imageUrl);
        File saveAs = File(p.join(workingDir.path, "\${index.toString().padLeft(3, '0')}_\${imageUri.pathSegments.last}"));
        await downloadFile(imageUri, saveAs);
      }
    }
  }

  bool _isImage(String url) {
    return url.endsWith('.jpg') || url.endsWith('.jpeg') || url.endsWith('.png') || url.endsWith('.gif');
  }
}
