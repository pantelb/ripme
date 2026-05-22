import '../abstract_json_ripper.dart';
import '../../utils/http_utils.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

class TumblrRipper extends AbstractJSONRipper {
  TumblrRipper(super.url);

  @override
  String getHost() => "tumblr";

  @override
  bool canRip(Uri url) => url.host.endsWith("tumblr.com");

  @override
  Future<String> getGID(Uri url) async {
    return url.host.split('.').first;
  }

  @override
  Future<void> parseJSON(Uri url) async {
    String hostname = url.host;
    String apiKey =
        "JFNLu3CbINQjRdUvZibXW9VpSEVYYtiPJ86o8YmvgLZIoKyuNX"; // One of the defaults

    int offset = 0;
    while (true) {
      if (isStopped) break;

      String apiUrl =
          "https://api.tumblr.com/v2/blog/$hostname/posts?api_key=$apiKey&offset=$offset&limit=20";
      dynamic json = await Http.getJSON(Uri.parse(apiUrl));

      var posts = json['response']['posts'] as List;
      if (posts.isEmpty) break;

      for (var post in posts) {
        if (isStopped) break;
        if (post.containsKey('photos')) {
          var photos = post['photos'] as List;
          for (var photo in photos) {
            String imageUrl = photo['original_size']['url'];
            Uri imageUri = Uri.parse(imageUrl);
            File saveAs =
                File(p.join(workingDir.path, imageUri.pathSegments.last));
            await downloadFile(imageUri, saveAs);
          }
        }
      }

      offset += 20;
    }
  }
}
