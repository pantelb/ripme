import 'package:html/dom.dart';
import '../ripper/abstract_html_ripper.dart';
import '../utils/http_utils.dart';
import '../ui/rip_status_message.dart';

class FlickrRipper extends AbstractHTMLRipper {
  FlickrRipper(Uri url) : super(url);

  @override
  String getHost() => "flickr";

  @override
  bool canRip(Uri url) => url.host.endsWith("flickr.com");

  @override
  Future<String> getGID(Uri url) async {
    return url.pathSegments.lastWhere((s) => s.isNotEmpty);
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    List<String> urls = [];
    // Flick uses an API usually, but this is a fallback HTML scraper
    var images = page.querySelectorAll('img.main-photo');
    for (var img in images) {
      String? src = img.attributes['src'];
      if (src != null) {
        if (src.startsWith('//')) src = 'https:\$src';
        urls.add(src);
      }
    }
    return urls;
  }

  @override
  Future<Uri?> getNextPage(Document page) async {
    return null;
  }
}
