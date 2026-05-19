import 'package:html/dom.dart';
import '../ripper/abstract_html_ripper.dart';
import '../utils/http_utils.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

class ImagefapRipper extends AbstractHTMLRipper {
  ImagefapRipper(Uri url) : super(url);

  @override
  String getHost() => "imagefap";

  @override
  bool canRip(Uri url) => url.host.endsWith("imagefap.com");

  @override
  Future<String> getGID(Uri url) async {
    final regExp = RegExp(r"imagefap.com/(pictures|gallery)/([a-f0-9]+)");
    final match = regExp.firstMatch(url.toString());
    if (match != null) {
      return match.group(2)!;
    }
    throw Exception("Could not find GID for \$url");
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    List<String> urls = [];
    var thumbs = page.querySelectorAll('#gallery img');
    for (var thumb in thumbs) {
      if (isStopped) break;
      var parent = thumb.parent;
      if (parent != null && parent.localName == 'a') {
        String? href = parent.attributes['href'];
        if (href != null) {
          String? imageUrl = await _getFullSizedImage("https://www.imagefap.com\$href");
          if (imageUrl != null) {
            urls.add(imageUrl);
          }
        }
      }
    }
    return urls;
  }

  Future<String?> _getFullSizedImage(String pageUrl) async {
    try {
      Document doc = await Http.get(Uri.parse(pageUrl));
      var mainPhoto = doc.querySelector('img#mainPhoto');
      return mainPhoto?.attributes['data-src'];
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Uri?> getNextPage(Document page) async {
    var nextLink = page.querySelectorAll('a.link3').where((e) => e.text.contains('next')).firstOrNull;
    if (nextLink != null) {
      String? href = nextLink.attributes['href'];
      if (href != null) {
        return Uri.parse("https://www.imagefap.com\$href");
      }
    }
    return null;
  }
}
