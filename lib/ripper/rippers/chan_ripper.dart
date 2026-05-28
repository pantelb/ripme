import 'dart:io';

import 'package:html/dom.dart';
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';
import 'reddit_ripper.dart';

class ChanSite {
  final List<String> domains;
  final List<String> cdnDomains;

  const ChanSite(this.domains, [List<String>? cdnDomains])
      : cdnDomains = cdnDomains ?? domains;

  factory ChanSite.single(String domain, [List<String>? cdnDomains]) {
    return ChanSite([domain], cdnDomains);
  }
}

class ChanRipper extends AbstractHTMLRipper {
  static const List<ChanSite> bakedInExplicitDomains = [
    ChanSite([
      'boards.4chan.org',
    ], [
      '4cdn.org',
      'is.4chan.org',
      'is2.4chan.org',
      'is3.4chan.org',
    ]),
    ChanSite([
      'boards.4channel.org',
    ], [
      '4cdn.org',
      'is.4chan.org',
      'is2.4chan.org',
      'is3.4chan.org',
    ]),
    ChanSite(['4archive.org'], ['imgur.com']),
    ChanSite(['archive.4plebs.org'], ['img.4plebs.org']),
    ChanSite(['yuki.la'], ['ii.yuki.la']),
    ChanSite(['55chan.org']),
    ChanSite(['desuchan.net']),
    ChanSite(['boards.420chan.org']),
    ChanSite(['7chan.org']),
    ChanSite(['desuarchive.org'], ['desu-usergeneratedcontent.xyz']),
    ChanSite(['8ch.net'], ['media.8ch.net']),
    ChanSite(['thebarchive.com']),
    ChanSite(['archiveofsins.com']),
    ChanSite(['archive.nyafuu.org']),
    ChanSite(['rbt.asia']),
  ];

  static const List<String> urlPieceBlacklist = [
    '=http',
    'http://imgops.com/',
    'iqdb.org',
    'saucenao.com',
  ];

  final ChanSite chanSite;
  final bool generalChanSite;

  ChanRipper(super.url)
      : chanSite = siteForUrl(url) ?? ChanSite([url.host]),
        generalChanSite = siteForUrl(url) == null;

  @override
  String getHost() {
    var host = url.host;
    host = host.substring(0, host.lastIndexOf('.'));
    if (host.contains('.')) {
      host = host.substring(host.lastIndexOf('.') + 1);
    }
    final board = url.pathSegments.isNotEmpty ? url.pathSegments.first : '';
    return '${host}_$board';
  }

  String getDomain() => url.host;

  @override
  bool canRip(Uri url) => siteForUrl(url) != null;

  @override
  Future<String> getGID(Uri url) async {
    final text = url.toString();
    if (text.contains('/thread/') ||
        text.contains('/res/') ||
        text.contains('yuki.la') ||
        text.contains('55chan.org')) {
      var match = RegExp(
        r'^.*\.[a-z]{1,4}/[a-zA-Z0-9]+/(thread|res)/([0-9]+)(\.html|\.php)?.*$',
      ).firstMatch(text);
      if (match != null) return match.group(2)!;

      match = RegExp(
        r'^.*\.[a-z]{1,3}/[a-zA-Z0-9]+/[a-zA-Z0-9]+/res/([0-9]+)(\.html|\.php)?.*$',
      ).firstMatch(text);
      if (match != null) return match.group(1)!;

      match = RegExp(
        r'^.*\.[a-z]{1,3}/board/[a-zA-Z0-9]+/thread/([0-9]+)/?.*$',
      ).firstMatch(text);
      if (match != null) return match.group(1)!;

      match =
          RegExp(r'https?://yuki.la/[a-zA-Z0-9]+/([0-9]+)').firstMatch(text);
      if (match != null) return match.group(1)!;

      match = RegExp(r'https?://55chan.org/[a-z0-9]+/(res|thread)/[0-9]+.html')
          .firstMatch(text);
      if (match != null) return match.group(1)!;
    }

    throw FormatException(
      'Expected *chan URL formats: .*/@/(res|thread)/####.html Got: $text',
    );
  }

  @override
  Future<String> getAlbumTitle(Uri url) async {
    try {
      final page = await Http.get(url);
      final subject = page.querySelector('.post.op > .postinfo > .subject');
      final text = subject?.text;
      if (text != null && text.isNotEmpty) {
        return '${getHost()}_${await getGID(url)}_$text';
      }
    } catch (_) {
      // Fall through to Java's default host_GID album naming convention.
    }
    return '${getHost()}_${await getGID(url)}';
  }

  @override
  Future<void> rip() async {
    sendUpdate(RipStatus.loadingResource, url.toString());

    Document page;
    try {
      page = await Http.get(url);
    } catch (e) {
      sendUpdate(RipStatus.ripErrored, e.toString());
      return;
    }

    final imageUrls = await getURLsFromPage(page);
    for (var i = 0; i < imageUrls.length; i++) {
      if (isStopped) break;
      final imageUri = Uri.parse(imageUrls[i]);
      if (isVideo(imageUri)) {
        await Http.delay(const Duration(seconds: 5));
      }
      await downloadFile(
        imageUri,
        File(p.join(
          workingDir.path,
          fileNameForUrl(imageUri, prefix: prefixForIndex(i + 1)),
        )),
      );
    }

    sendUpdate(RipStatus.ripComplete, workingDir.path);
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    final imageUrls = <String>[];
    for (final link in page.querySelectorAll('a')) {
      var href = link.attributes['href']?.trim();
      if (href == null || href.isEmpty) continue;
      if (isUrlBlacklisted(href)) continue;

      var selfHosted = false;
      if (!generalChanSite) {
        selfHosted = chanSite.cdnDomains.any(href.contains);
      }

      if (selfHosted || generalChanSite) {
        if (!isDirectMediaHref(href)) continue;
        href = normalizeMediaHref(href, url.host);
        if (imageUrls.contains(href)) continue;
        imageUrls.add(href);
      } else {
        final originalUri = Uri.tryParse(href);
        if (originalUri == null || !originalUri.hasScheme) continue;
        final expanded = await RedditRipper.expandNonDirectUrl(originalUri);
        imageUrls.addAll(expanded.map((uri) => uri.toString()));
      }

      if (isStopped) break;
    }
    return imageUrls;
  }

  @override
  Future<Uri?> getNextPage(Document page) async => null;

  static List<ChanSite>? getChansFromConfig(String? rawChanString) {
    if (rawChanString == null) return null;
    final userChans = <ChanSite>[];
    for (final chanInfo in rawChanString.split(',')) {
      if (chanInfo.contains('[')) {
        final siteUrl = chanInfo.split('[').first;
        final cdns =
            chanInfo.replaceAll('$siteUrl[', '').replaceAll(']', '').split('|');
        userChans.add(ChanSite([siteUrl], cdns));
      } else {
        userChans.add(ChanSite([chanInfo]));
      }
    }
    return userChans;
  }

  static ChanSite? siteForUrl(Uri url) {
    for (final site in explicitDomains()) {
      if (site.domains.contains(url.host)) return site;
    }
    return null;
  }

  static List<ChanSite> explicitDomains() {
    final sites = <ChanSite>[...bakedInExplicitDomains];
    final configured = getChansFromConfig(
      Utils.getConfigString('chans.chan_sites', null),
    );
    if (configured != null) sites.addAll(configured);
    return sites;
  }

  static bool isUrlBlacklisted(String url) {
    return urlPieceBlacklist.any(url.contains);
  }

  static bool isDirectMediaHref(String href) {
    return RegExp(
      r'^.*\.(jpg|jpeg|png|gif|apng|webp|tif|tiff|webm|mp4)$',
      caseSensitive: false,
    ).hasMatch(href);
  }

  static String normalizeMediaHref(String href, String host) {
    if (href.startsWith('//')) return 'http:$href';
    if (href.startsWith('/')) return 'http://$host$href';
    return href;
  }

  static bool isVideo(Uri url) {
    final text = url.toString();
    return text.endsWith('.webm') || text.endsWith('.mp4');
  }

  static String prefixForIndex(int index) {
    if (!Utils.getConfigBoolean('download.save_order', true)) return '';
    return '${index.toString().padLeft(3, '0')}_';
  }

  static String fileNameForUrl(Uri uri, {required String prefix}) {
    final fileName =
        uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'file';
    return Utils.sanitizeSaveAs('$prefix$fileName');
  }
}
