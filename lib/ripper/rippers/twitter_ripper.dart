import '../abstract_json_ripper.dart';
import '../../utils/utils.dart';

class TwitterRipper extends AbstractJSONRipper {
  TwitterRipper(super.url);

  @override
  String getHost() => "twitter";

  @override
  bool canRip(Uri url) => url.host.endsWith("twitter.com") || url.host.endsWith("x.com");

  @override
  Future<String> getGID(Uri url) async {
    return url.pathSegments.last;
  }

  @override
  Future<void> parseJSON(Uri url) async {
    // Twitter ripping requires complex OAuth or guest tokens usually.
    // Original code used a configured auth key.
    String? authKey = Utils.getConfigString("twitter.auth", null);
    if (authKey == null) {
      throw Exception("Twitter auth key not found in config");
    }

    throw UnimplementedError("Twitter ripping still needs to be ported from the Java implementation");
  }
}
