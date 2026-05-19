import 'package:html/dom.dart';
import '../ripper/abstract_html_ripper.dart';
import '../utils/http_utils.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

class MotherlessRipper extends AbstractHTMLRipper {
  MotherlessRipper(Uri url) : super(url);

  @override
  String getHost() => "motherless";

  @override
  bool canRip(Uri url) => url.host.endsWith("motherless.com");

  @override
  Future<String> getGID(Uri url) async {
    final regExp = RegExp(r"motherless.com/G([MVI]?[A-F0-9]{6,8})");
    final match = regExp.firstMatch(url.toString());
    if (match != null) {
      return match.group(1)!;
    }
    throw Exception("Could not find GID for $url");
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    List<String> urls = [];
    var thumbs = page.querySelectorAll('div.thumb-container a.img-container');
    for (var thumb in thumbs) {
      if (isStopped) break;
      String? href = thumb.attributes['href'];
      if (href != null) {
        if (!href.startsWith('http')) href = "https://motherless.com$href";
        String? imageUrl = await _getFileUrl(href);
        if (imageUrl != null) {
          urls.add(imageUrl);
        }
      }
    }
    return urls;
  }

  Future<String?> _getFileUrl(String pageUrl) async {
    try {
      Document doc = await Http.get(Uri.parse(pageUrl));
      final html = doc.outerHtml;
      final regExp = RegExp(r"__fileurl = '([^']+)';");
      final match = regExp.firstMatch(html);
      return match?.group(1);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Uri?> getNextPage(Document page) async {
    var nextLink = page.querySelector('link[rel="next"]');
    if (nextLink != null) {
      String? href = nextLink.attributes['href'];
      if (href != null) {
        return Uri.parse(href);
      }
    }
    return null;
  }
}
