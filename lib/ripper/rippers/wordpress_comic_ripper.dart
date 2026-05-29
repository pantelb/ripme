import 'dart:io';

import 'package:html/dom.dart';
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';
import '../abstract_ripper.dart';

class WordpressComicRipper extends AbstractHTMLRipper {
  static const explicitDomains = {
    'www.totempole666.com',
    'buttsmithy.com',
    'incase.buttsmithy.com',
    'themonsterunderthebed.net',
    'prismblush.com',
    'www.konradokonski.com',
    'freeadultcomix.com',
    'thisis.delvecomic.com',
    'shipinbottle.pepsaga.com',
    '8muses.download',
    'spyingwithlana.com',
    'comixfap.net',
  };

  static const theme1 = {
    'www.totempole666.com',
    'buttsmithy.com',
    'themonsterunderthebed.net',
    'prismblush.com',
    'www.konradokonski.com',
    'thisis.delvecomic.com',
    'spyingwithlana.com',
  };

  WordpressComicRipper(super.url);

  String _pageTitle = '';

  @override
  String getHost() => url.host;

  String getDomain() => url.host;

  @override
  bool canRip(Uri url) {
    if (!explicitDomains.contains(url.host)) return false;
    return _canRipPatterns.any((pattern) => pattern.hasMatch(url.toString()));
  }

  @override
  bool hasQueueSupport() => true;

  @override
  bool pageContainsAlbums(Uri url) {
    return _queuePatterns.any((pattern) => pattern.hasMatch(url.toString()));
  }

  @override
  Future<List<String>> getAlbumsToQueue(Document page) async {
    return [
      for (final anchor in page
          .querySelectorAll('#post_masonry > article > div > figure > a'))
        anchor.attributes['href'] ?? '',
    ];
  }

  @override
  Future<String> getAlbumTitle(Uri url) async {
    final title = albumTitleForUrl(url);
    if (title != null) return title;
    return super.getAlbumTitle(url);
  }

  @override
  Future<String> getGID(Uri url) async {
    if (explicitDomains.contains(url.host)) return '';
    throw const FormatException('You should never see this error message');
  }

  @override
  Future<void> rip() async {
    sendUpdate(RipStatus.loadingResource, url.toString());

    try {
      var page = await Http.get(url);
      if (hasQueueSupport() && pageContainsAlbums(url)) {
        for (final childUrl in await getAlbumsToQueue(page)) {
          if (isStopped) break;
          sendUpdate(RipStatus.queueAdd, childUrl);
        }
        sendUpdate(RipStatus.ripComplete, workingDir.path);
        return;
      }

      var index = 0;
      while (!isStopped) {
        final downloads = <RipperDownload>[];
        for (final imageUrl in await getURLsFromPage(page)) {
          if (imageUrl.isEmpty || isStopped) continue;
          index++;
          final imageUri = Uri.parse(imageUrl);
          downloads.add(
            RipperDownload(
              url: imageUri,
              saveAs: File(
                p.join(workingDir.path, fileNameForUrl(imageUri, index)),
              ),
            ),
          );
        }
        await downloadFiles(downloads);

        final nextUrl = await getNextPage(page);
        if (nextUrl == null) break;
        sendUpdate(RipStatus.loadingResource, nextUrl.toString());
        page = await Http.get(nextUrl);
      }
    } catch (e) {
      sendUpdate(RipStatus.ripErrored, e.toString());
    }
    sendUpdate(RipStatus.ripComplete, workingDir.path);
  }

  @override
  Future<Uri?> getNextPage(Document page) async {
    String nextPage = '';
    if (theme1.contains(getHost())) {
      nextPage =
          page.querySelector('a.comic-nav-next')?.attributes['href'] ?? '';
    } else if (getHost().contains('shipinbottle.pepsaga.com')) {
      nextPage = page
              .querySelector('td.comic_navi_right > a.navi-next')
              ?.attributes['href'] ??
          '';
    }
    if (nextPage.isEmpty) return null;
    return Uri.parse(nextPage);
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    final result = <String>[];
    final urlText = url.toString();

    if (theme1.contains(getHost())) {
      final image =
          page.querySelector('div.comic-table > div#comic > a > img') ??
              page.querySelector('div.comic-table > div#comic > img');
      if (urlText.contains('buttsmithy.com')) {
        _pageTitle = (page
                    .querySelector('meta[property="og:title"]')
                    ?.attributes['content'] ??
                '')
            .replaceAll(' ', '')
            .replaceAll('P', 'p');
      }
      if (urlText.contains('www.totempole666.com')) {
        final postDate =
            page.querySelector('span.post-date')?.text.replaceAll('/', '_') ??
                '';
        final postTitle =
            page.querySelector('h2.post-title')?.text.replaceAll('#', '') ?? '';
        _pageTitle = '${postDate}_$postTitle';
      }
      if (urlText.contains('themonsterunderthebed.net')) {
        _pageTitle = (page.querySelector('title')?.text ?? '')
            .replaceAll('#', '')
            .replaceAll('“', '')
            .replaceAll('”', '')
            .replaceAll('The Monster Under the Bed', '')
            .replaceAll('–', '')
            .replaceAll(',', '')
            .replaceAll(' ', '');
      }
      result.add(image?.attributes['src'] ?? '');
    }

    if (urlText.contains('freeadultcomix.com')) {
      for (final image in page.querySelectorAll(
          'div.post-texto > p > noscript > img[class*=aligncenter]')) {
        result.add(image.attributes['src'] ?? '');
      }
      for (final noscript
          in page.querySelectorAll('div.post-texto > p > noscript')) {
        final fragment = Document.html(noscript.text);
        for (final image
            in fragment.querySelectorAll('img[class*=aligncenter]')) {
          result.add(image.attributes['src'] ?? '');
        }
      }
    } else if (urlText.contains('comics-xxx.com')) {
      for (final image
          in page.querySelectorAll('div.single-post > center > p > img')) {
        result.add(image.attributes['src'] ?? '');
      }
    } else if (urlText.contains('shipinbottle.pepsaga.com')) {
      for (final image in page.querySelectorAll('div#comic > a > img')) {
        result.add(image.attributes['src'] ?? '');
      }
    } else if (urlText.contains('8muses.download')) {
      for (final anchor
          in page.querySelectorAll('div.popup-gallery > figure > a')) {
        result.add(anchor.attributes['href'] ?? '');
      }
    } else if (urlText.contains('http://comixfap.net')) {
      for (final anchor in page.querySelectorAll(
          'div.entry-content > div.dgwt-jg-gallery > figure > a')) {
        result.add(anchor.attributes['href'] ?? '');
      }
      for (final image in page.querySelectorAll('.unite-gallery > img')) {
        result.add(image.attributes['src'] ?? '');
      }
    }

    return result;
  }

  String fileNameForUrl(Uri uri, int index) {
    final prefix =
        titlePrefixHost(url.host) ? '${_pageTitle}_' : prefixForIndex(index);
    return fileNameWithPrefix(uri, prefix);
  }

  static bool titlePrefixHost(String host) {
    return host.contains('buttsmithy.com') ||
        host.contains('www.totempole666.com') ||
        host.contains('themonsterunderthebed.net');
  }

  static String fileNameWithPrefix(Uri uri, String prefix) {
    final fileName =
        uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'file';
    return Utils.sanitizeSaveAs('$prefix$fileName');
  }

  static String prefixForIndex(int index) {
    if (!Utils.getConfigBoolean('download.save_order', true)) return '';
    return '${index.toString().padLeft(3, '0')}_';
  }

  static String? albumTitleForUrl(Uri url) {
    final text = url.toString();
    Match? match;
    if (RegExp(
            r'(?:https?://)?(?:www\.)?totempole666.com/comic/([a-zA-Z0-9_-]*)/?$')
        .hasMatch(text)) {
      return 'totempole666.com_The_cummoner';
    }
    if (RegExp(r'https?://buttsmithy.com/archives/comic/([a-zA-Z0-9_-]*)/?$')
        .hasMatch(text)) {
      return 'buttsmithy.com_Alfie';
    }
    match = RegExp(
            r'http://www.konradokonski.com/([a-zA-Z]+)/comic/([a-zA-Z0-9_-]*)/?$')
        .firstMatch(text);
    if (match != null) return 'konradokonski.com_${match.group(1)!}';
    if (RegExp(r'https?://www.konradokonski.com/aquartzbead/?$')
        .hasMatch(text)) {
      return 'konradokonski.com_aquartzbead';
    }
    match = RegExp(r'https?://freeadultcomix.com/([a-zA-Z0-9_\-]*)/?$')
        .firstMatch(text);
    if (match != null) return '${url.host}_${match.group(1)!}';
    if (RegExp(
            r'https?://thisis.delvecomic.com/NewWP/comic/([a-zA-Z0-9_\-]*)/?$')
        .hasMatch(text)) {
      return '${url.host}_Delve';
    }
    match = RegExp(r'https?://prismblush.com/comic/([a-zA-Z0-9_-]*)/?$')
        .firstMatch(text);
    if (match != null) return '${url.host}_${match.group(1)!}';
    match = RegExp(r'https?://incase.buttsmithy.com/comic/([a-zA-Z0-9_-]*)/?$')
        .firstMatch(text);
    if (match != null) {
      return '${url.host}_${match.group(1)!.replaceAll(RegExp(r'-page-\d'), '').replaceAll(RegExp(r'-pg-\d'), '')}';
    }
    match = RegExp(r'https?://comics-xxx.com/([a-zA-Z0-9_\-]*)/?$')
        .firstMatch(text);
    if (match != null) return '${url.host}_${match.group(1)!}';
    if (RegExp(r'https?://shipinbottle.pepsaga.com/\?p=([0-9]*)/?$')
        .hasMatch(text)) {
      return '${url.host}_Ship_in_bottle';
    }
    match = RegExp(r'https?://8muses.download/([a-zA-Z0-9_-]+)/?$')
        .firstMatch(text);
    if (match != null) return '${url.host}_${match.group(1)!}';
    match = RegExp(r'https?://spyingwithlana.com/comic/([a-zA-Z0-9_-]+)/?$')
        .firstMatch(text);
    if (match != null) {
      return 'spyingwithlana_${match.group(1)!.replaceAll(RegExp(r'-page-\d'), '')}';
    }
    match = RegExp(r'https?://comixfap.net/([a-zA-Z0-9-]*)/?').firstMatch(text);
    if (match != null) return 'comixfap_${match.group(1)!}';
    return null;
  }

  static final List<RegExp> _queuePatterns = [
    RegExp(r'^https?://8muses.download/\?s=([a-zA-Z0-9-]*)'),
    RegExp(r'https?://8muses.download/page/\d+/\?s=([a-zA-Z0-9-]*)'),
    RegExp(r'https://8muses.download/category/([a-zA-Z0-9-]*)/?'),
  ];

  static final List<RegExp> _canRipPatterns = [
    RegExp(r'https?://www\.totempole666.com/comic/([a-zA-Z0-9_-]*)/?$'),
    RegExp(
        r'https?://www.konradokonski.com/([a-zA-Z0-9_-]*)/comic/([a-zA-Z0-9_-]*)/?$'),
    RegExp(r'https?://www.konradokonski.com/aquartzbead/?$'),
    RegExp(r'https?://buttsmithy.com/archives/comic/([a-zA-Z0-9_-]*)/?$'),
    RegExp(r'https?://incase.buttsmithy.com/comic/([a-zA-Z0-9_-]*)/?$'),
    RegExp(r'https?://themonsterunderthebed.net/\?comic=([a-zA-Z0-9_-]*)/?$'),
    RegExp(r'https?://prismblush.com/comic/([a-zA-Z0-9_-]*)/?$'),
    RegExp(r'https?://freeadultcomix.com/([a-zA-Z0-9_\-]*)/?$'),
    RegExp(r'https?://thisis.delvecomic.com/NewWP/comic/([a-zA-Z0-9_\-]*)/?$'),
    RegExp(r'https?://comics-xxx.com/([a-zA-Z0-9_\-]*)/?$'),
    RegExp(r'https?://shipinbottle.pepsaga.com/\?p=([0-9]*)/?$'),
    RegExp(r'https?://8muses.download/([a-zA-Z0-9_-]+)/?$'),
    RegExp(r'https?://spyingwithlana.com/comic/([a-zA-Z0-9_-]+)/?$'),
    ..._queuePatterns,
    RegExp(r'https?://comixfap.net/([a-zA-Z0-9-]*)/?'),
  ];
}
