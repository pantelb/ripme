import 'package:html/dom.dart';
import '../abstract_html_ripper.dart';

class NhentaiRipper extends AbstractHTMLRipper {
  NhentaiRipper(super.url);

  @override
  String getHost() => "nhentai";

  @override
  bool canRip(Uri url) => url.host.endsWith("nhentai.net");

  @override
  Future<String> getGID(Uri url) async {
    return url.pathSegments.firstWhere((s) => RegExp(r"^\d+$").hasMatch(s));
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    List<String> urls = [];
    var thumbs = page.querySelectorAll('.thumb-container img');
    for (var thumb in thumbs) {
      String? src = thumb.attributes['data-src'] ?? thumb.attributes['src'];
      if (src != null) {
        // Convert thumbnail URL to full image URL
        // e.g. https://t.nhentai.net/galleries/12345/1t.jpg -> https://i.nhentai.net/galleries/12345/1.jpg
        String imageUrl = src
            .replaceFirst('t.nhentai.net', 'i.nhentai.net')
            .replaceFirst('t.jpg', '.jpg')
            .replaceFirst('t.png', '.png');
        urls.add(imageUrl);
      }
    }
    return urls;
  }

  @override
  Future<Uri?> getNextPage(Document page) async {
    return null;
  }
}
