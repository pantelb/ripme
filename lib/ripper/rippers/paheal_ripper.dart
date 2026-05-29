import 'dart:io';

import 'package:html/dom.dart';
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';
import '../abstract_ripper.dart';

class PahealRipper extends AbstractHTMLRipper {
  static const String domain = 'rule34.paheal.net';
  static const Map<String, String> listingCookies = {
    'ui-tnc-agreed': 'true',
  };

  static final RegExp _termPattern = RegExp(
    r"^https?://(www\.)?rule34\.paheal\.net/post/list/([a-zA-Z0-9$_.+!*'(),%-]+)(/.*)?(#.*)?$",
  );

  PahealRipper(super.url);

  @override
  String getHost() => 'paheal';

  String getDomain() => domain;

  @override
  bool canRip(Uri url) => url.host.toLowerCase().endsWith(domain);

  @override
  Future<String> getGID(Uri url) async {
    try {
      return Utils.filesystemSafe(Uri.decodeComponent(termFromUrl(url)));
    } catch (_) {
      throw FormatException(_formatError(url));
    }
  }

  @override
  Future<void> rip() async {
    sendUpdate(RipStatus.loadingResource, firstPageUrl().toString());
    Document page;
    try {
      page = await getFirstPage();
    } catch (e) {
      sendUpdate(RipStatus.ripErrored, e.toString());
      return;
    }

    while (!isStopped) {
      final downloads = <RipperDownload>[];
      for (final mediaUrl in await getURLsFromPage(page)) {
        if (isStopped) break;
        final mediaUri = Uri.parse(mediaUrl);
        downloads.add(
          RipperDownload(
            url: mediaUri,
            saveAs: File(
              p.join(workingDir.path, downloadFileName(mediaUri)),
            ),
          ),
        );
      }

      await downloadFiles(downloads);
      if (isStopped) break;

      final next = await getNextPage(page);
      if (next == null) break;

      try {
        sendUpdate(RipStatus.loadingResource, next.toString());
        page = await getDocument(next);
      } catch (_) {
        break;
      }
    }
    sendUpdate(RipStatus.ripComplete, workingDir.path);
  }

  Future<Document> getFirstPage() => getDocument(firstPageUrl());

  Uri firstPageUrl() {
    return Uri.parse('http://$domain/post/list/${termFromUrl(url)}/1');
  }

  Future<Document> getDocument(Uri uri) {
    return Http.get(uri, cookies: listingCookies);
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    return urlsFromPage(page);
  }

  @override
  Future<Uri?> getNextPage(Document page) async {
    return nextPageUrlFromPage(page);
  }

  static String termFromUrl(Uri url) {
    final match = _termPattern.firstMatch(url.toString());
    if (match != null) return match.group(2)!;
    throw FormatException(_formatError(url));
  }

  static List<String> urlsFromPage(
    Document page, {
    Uri? baseUri,
  }) {
    final root = baseUri ?? Uri.parse('http://$domain');
    final urls = <String>[];
    for (final link in page.querySelectorAll('.shm-thumb.thumb > a')) {
      final classes = (link.attributes['class'] ?? '').split(RegExp(r'\s+'));
      if (classes.contains('shm-thumb-link')) continue;

      final href = link.attributes['href'];
      if (href == null || href.isEmpty) continue;
      urls.add(root.resolve(href).toString());
    }
    return urls;
  }

  static Uri? nextPageUrlFromPage(
    Document page, {
    Uri? baseUri,
  }) {
    final root = baseUri ?? Uri.parse('http://$domain');
    for (final link in page.querySelectorAll('#paginator a')) {
      if (link.text.trim().toLowerCase() != 'next') continue;
      final href = link.attributes['href'];
      if (href == null || href.isEmpty) return null;
      return root.resolve(href);
    }
    return null;
  }

  static String downloadFileName(Uri uri) {
    var name = uri.toString().split(RegExp(r'[?#]')).first;
    var ext = '.png';

    name = name.substring(name.lastIndexOf('/') + 1);
    final lastDot = name.lastIndexOf('.');
    if (lastDot >= 0) {
      ext = name.substring(lastDot);
      name = name.substring(0, name.length - ext.length);
    }

    return '${Utils.filesystemSafe(Uri.decodeComponent(name))}$ext';
  }

  static String _formatError(Uri url) {
    return 'Expected paheal.net URL format: '
        'rule34.paheal.net/post/list/searchterm - got $url instead';
  }
}
