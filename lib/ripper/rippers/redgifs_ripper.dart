import '../ripper/abstract_json_ripper.dart';
import '../utils/http_utils.dart';
import '../ui/rip_status_message.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

class RedgifsRipper extends AbstractJSONRipper {
  RedgifsRipper(Uri url) : super(url);

  static String? _authToken;

  @override
  String getHost() => "redgifs";

  @override
  bool canRip(Uri url) => url.host.endsWith("redgifs.com") || url.host.endsWith("gifdeliverynetwork.com");

  @override
  Future<String> getGID(Uri url) async {
    return url.pathSegments.last;
  }

  Future<void> _fetchAuthToken() async {
    if (_authToken != null) return;
    try {
      final json = await Http.getJSON(Uri.parse("https://api.redgifs.com/v2/auth/temporary"));
      _authToken = json['token'];
    } catch (e) {
      // Fallback or error
    }
  }

  @override
  Future<void> parseJSON(Uri url) async {
    await _fetchAuthToken();
    String gid = await getGID(url);
    String apiUrl = "https://api.redgifs.com/v2/gifs/\$gid";

    dynamic json = await Http.getJSON(Uri.parse(apiUrl), headers: {
      'Authorization': 'Bearer \$_authToken',
    });

    if (json['gif'] != null) {
      String? hdUrl = json['gif']['urls']['hd'];
      if (hdUrl != null) {
        Uri imageUri = Uri.parse(hdUrl);
        File saveAs = File(p.join(workingDir.path, imageUri.pathSegments.last));
        await downloadFile(imageUri, saveAs);
      }
    }
  }
}
