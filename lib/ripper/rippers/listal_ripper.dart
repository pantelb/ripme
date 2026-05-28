import 'dart:io';

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';
import '../abstract_ripper.dart';

enum ListalUrlType { list, folder, unknown }

class ListalRipper extends AbstractHTMLRipper {
  ListalRipper(
    super.url, {
    Uri? baseUri,
    Uri? postUri,
    http.Client? postClient,
  })  : baseUri = baseUri ?? Uri.parse('https://www.listal.com/'),
        postUri = postUri ?? Uri.parse('https://www.listal.com/item-list/'),
        _postClient = postClient;

  static final RegExp _listPattern =
      RegExp(r'^https:\/\/www\.listal\.com\/list\/([a-zA-Z0-9-]+)$');
  static final RegExp _folderPattern =
      RegExp(r'^https:\/\/www\.listal\.com\/((?:(?:[a-zA-Z0-9-_%]+)\/?)+)$');

  final Uri baseUri;
  final Uri postUri;
  final http.Client? _postClient;
  String? _listId;
  ListalUrlType _urlType = ListalUrlType.unknown;

  @override
  String getHost() => 'listal';

  String getDomain() => 'listal.com';

  @override
  bool canRip(Uri url) => url.host.endsWith(getDomain());

  @override
  Future<String> getGID(Uri url) async {
    final listMatch = _listPattern.firstMatch(url.toString());
    if (listMatch != null) {
      _urlType = ListalUrlType.list;
      return listMatch.group(1)!;
    }

    final folderMatch = _folderPattern.firstMatch(url.toString());
    if (folderMatch != null) {
      _urlType = ListalUrlType.folder;
      return getFolderTypeGid(folderMatch.group(1)!);
    }

    throw FormatException(
      'Expected listal.com URL format: '
      'listal.com/list/my-list-name - got $url instead.',
    );
  }

  Future<String> getFolderTypeGid(String group) async {
    final folders = _javaSplitPath(group);
    try {
      if (folders.length == 2 && folders[1] == 'pictures') {
        return folders[0];
      }

      if (folders.length == 3 && folders[2] == 'pictures') {
        final doc = await Http.get(url);
        return doc.querySelector('.itemheadingmedium')!.text;
      }
    } catch (_) {
      // Java logs and then throws the generic malformed URL error below.
    }
    throw const FormatException('Unable to fetch the gid for given url.');
  }

  Future<Document> getFirstPage() async {
    final page = await Http.get(url);
    if (_urlType == ListalUrlType.list) {
      _listId =
          page.querySelector('#customlistitems')!.attributes['data-listid'];
    }
    return page;
  }

  @override
  Future<void> rip() async {
    sendUpdate(RipStatus.loadingResource, url.toString());

    try {
      await getGID(url);
    } catch (e) {
      sendUpdate(RipStatus.ripErrored, e.toString());
      return;
    }

    Document page;
    try {
      page = await getFirstPage();
    } catch (e) {
      sendUpdate(RipStatus.ripErrored, e.toString());
      return;
    }

    var index = 0;
    while (!isStopped) {
      final downloads = <RipperDownload>[];
      for (final imagePageUrl in await getURLsFromPage(page)) {
        if (isStopped) break;
        final imageUrl =
            await imageUrlFromImagePageUrl(Uri.parse(imagePageUrl));
        if (imageUrl == null) continue;
        index++;
        final imageUri = Uri.parse(imageUrl);
        final imagePageUri = Uri.parse(imagePageUrl);
        downloads.add(
          RipperDownload(
            url: imageUri,
            saveAs: File(
              p.join(
                workingDir.path,
                fileNameForImagePage(imagePageUri, prefixForIndex(index)),
              ),
            ),
          ),
        );
      }

      await downloadFiles(downloads);
      if (isStopped) break;

      final nextPage = await getNextListalPage(page);
      if (nextPage == null) break;
      page = nextPage;
    }

    sendUpdate(RipStatus.ripComplete, workingDir.path);
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    if (_urlType == ListalUrlType.list) {
      return urlsForListType(page, baseUri);
    }
    if (_urlType == ListalUrlType.folder) {
      return urlsForFolderType(page, baseUri);
    }
    return const [];
  }

  Future<Document?> getNextListalPage(Document page) async {
    switch (_urlType) {
      case ListalUrlType.list:
        final loadMore = page.querySelectorAll('.loadmoreitems');
        if (loadMore.isEmpty) return null;
        final offset = loadMore.last.attributes['data-offset'] ?? '';
        return postNextListPage(_listId, offset);
      case ListalUrlType.folder:
        final pageLinks = page.querySelectorAll('.pages a');
        if (pageLinks.isEmpty || !pageLinks.last.text.startsWith('Next')) {
          return null;
        }
        final href = pageLinks.last.attributes['href'] ?? '';
        if (href.isEmpty) return null;
        final nextUri = baseUri.resolve(href);
        return Http.get(nextUri);
      case ListalUrlType.unknown:
        return null;
    }
  }

  @override
  Future<Uri?> getNextPage(Document page) async {
    final next = await getNextListalPage(page);
    return next == null ? null : postUri;
  }

  Future<Document> postNextListPage(String? listId, String offset) async {
    final body = <String, String>{
      'listid': listId ?? '',
      'offset': offset,
    };
    Object? lastError;
    for (var attempt = 0; attempt < 3; attempt++) {
      final client = _postClient ?? http.Client();
      try {
        final response = await client.post(
          postUri,
          headers: {'User-Agent': Http.userAgent},
          body: body,
        );
        if (response.statusCode == 200) {
          return html.parse(response.body, sourceUrl: postUri.toString());
        }
        lastError = HttpException(
          'Failed to load $postUri: Status ${response.statusCode}',
        );
      } catch (e) {
        lastError = e;
      } finally {
        if (_postClient == null) client.close();
      }
    }
    if (lastError is Exception) throw lastError;
    throw HttpException('Failed to load $postUri');
  }

  Future<String?> imageUrlFromImagePageUrl(Uri imagePageUrl) async {
    try {
      final page = await Http.get(imagePageUrl);
      return imageUrlFromImagePage(page);
    } catch (_) {
      return null;
    }
  }

  ListalUrlType get urlTypeForTesting => _urlType;
  String? get listIdForTesting => _listId;

  static List<String> urlsForListType(Document page, Uri baseUri) {
    return [
      for (final link in page.querySelectorAll('.pure-g a[href*=viewimage]'))
        '${baseUri.resolve(link.attributes['href'] ?? '')}h',
    ];
  }

  static List<String> urlsForFolderType(Document page, Uri baseUri) {
    return [
      for (final link
          in page.querySelectorAll('#browseimagescontainer .imagewrap-outer a'))
        '${baseUri.resolve(link.attributes['href'] ?? '')}h',
    ];
  }

  static String? imageUrlFromImagePage(Document page) {
    final src = page.querySelector('.pure-img')?.attributes['src'] ?? '';
    return src.isEmpty ? null : src;
  }

  static String fileNameForImagePage(Uri imagePageUrl, String prefix) {
    var name = imagePageUrl.toString();
    try {
      name = name.substring(name.lastIndexOf('/') + 1);
    } catch (_) {
      name = 'null';
    }
    return Utils.sanitizeSaveAs('$prefix$name.jpg');
  }

  static String prefixForIndex(int index) {
    if (!Utils.getConfigBoolean('download.save_order', true)) return '';
    return '${index.toString().padLeft(3, '0')}_';
  }

  static List<String> _javaSplitPath(String group) {
    final parts = group.split('/');
    while (parts.isNotEmpty && parts.last.isEmpty) {
      parts.removeLast();
    }
    return parts;
  }
}
