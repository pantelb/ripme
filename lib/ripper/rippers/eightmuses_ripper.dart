import 'package:html/dom.dart';
import '../ripper/abstract_html_ripper.dart';
import '../utils/http_utils.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

class EightmusesRipper extends AbstractHTMLRipper {
  EightmusesRipper(Uri url) : super(url);

  @override
  String getHost() => "8muses";

  @override
  bool canRip(Uri url) => url.host.endsWith("8muses.com");

  @override
  Future<String> getGID(Uri url) async {
    return url.pathSegments.last;
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    List<String> urls = [];
    var tiles = page.querySelectorAll('.c-tile');
    for (var tile in tiles) {
      if (isStopped) break;
      String? href = tile.attributes['href'];
      if (href != null) {
        if (href.contains('/comics/album/')) {
          // Recursive call for sub-albums
          Document subPage = await Http.get(Uri.parse("https://www.8muses.com\$href"));
          urls.addAll(await getURLsFromPage(subPage));
        } else if (href.contains('/comics/picture/')) {
          var img = tile.querySelector('img');
          String? src = img?.attributes['data-src'];
          if (src != null) {
            String imageUrl = "https://comics.8muses.com" + src.replaceFirst('/th/', '/fl/');
            urls.add(imageUrl);
          }
        }
      }
    }
    return urls;
  }

  @override
  Future<Uri?> getNextPage(Document page) async {
    return null;
  }
}
