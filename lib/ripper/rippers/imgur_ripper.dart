import 'package:html/dom.dart';
import '../abstract_html_ripper.dart';

class ImgurRipper extends AbstractHTMLRipper {
  ImgurRipper(super.url);

  @override
  String getHost() => "imgur";

  @override
  Future<String> getGID(Uri url) async {
    // Basic GID extraction for imgur
    return url.pathSegments.last;
  }

  @override
  bool canRip(Uri url) => url.host.endsWith("imgur.com");

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    List<String> urls = [];
    // Imgur usually has images in meta tags or specific classes
    // This is a simplified version
    var images = page.querySelectorAll('img');
    for (var img in images) {
      String? src = img.attributes['src'];
      if (src != null && src.contains('i.imgur.com')) {
        if (src.startsWith('//')) src = 'https:$src';
        urls.add(src);
      }
    }
    return urls;
  }

  @override
  Future<Uri?> getNextPage(Document page) async {
    return null; // Imgur usually loads everything on one page or via API
  }
}
