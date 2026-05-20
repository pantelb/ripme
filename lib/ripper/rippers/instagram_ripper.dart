import 'package:html/dom.dart';
import '../abstract_html_ripper.dart';

class InstagramRipper extends AbstractHTMLRipper {
  InstagramRipper(super.url);

  @override
  String getHost() => "instagram";

  @override
  bool canRip(Uri url) => url.host.endsWith("instagram.com");

  @override
  Future<String> getGID(Uri url) async {
    return url.pathSegments.lastWhere((s) => s.isNotEmpty);
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    // Instagram is very JS-heavy, but some images might be in meta tags
    List<String> urls = [];
    var meta = page.querySelector('meta[property="og:image"]');
    if (meta != null) {
      String? content = meta.attributes['content'];
      if (content != null) urls.add(content);
    }
    return urls;
  }

  @override
  Future<Uri?> getNextPage(Document page) async {
    return null;
  }
}
