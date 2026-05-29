import 'dart:convert';
import 'dart:io';

import 'package:html/dom.dart';
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';
import '../abstract_ripper.dart';
import 'thechive_ripper.dart';

class TsuminoRipper extends AbstractHTMLRipper {
  static final RegExp _gidWithTitlePattern = RegExp(
    r'^https?://www\.tsumino\.com/Book/Info/([0-9]+)/([a-zA-Z0-9_-]*)/?$',
  );
  static final RegExp _gidWithoutTitlePattern = RegExp(
    r'^https?://www\.tsumino\.com/Book/Info/([0-9]+)/?$',
  );
  static final RegExp _albumIdPattern = RegExp(
    r'^https?://www\.tsumino\.com/Book/Info/([0-9]+)/\S*$',
  );

  final Map<String, String> _cookies = <String, String>{};

  TsuminoRipper(super.url);

  @override
  String getHost() => 'tsumino';

  String getDomain() => 'tsumino.com';

  @override
  bool canRip(Uri url) =>
      _gidWithTitlePattern.hasMatch(url.toString()) ||
      _gidWithoutTitlePattern.hasMatch(url.toString());

  @override
  Future<String> getGID(Uri url) async {
    final withTitle = _gidWithTitlePattern.firstMatch(url.toString());
    if (withTitle != null) {
      return '${withTitle.group(1)!}_${withTitle.group(2)!}';
    }

    final withoutTitle = _gidWithoutTitlePattern.firstMatch(url.toString());
    if (withoutTitle != null) return withoutTitle.group(1)!;

    throw FormatException(
      'Expected tsumino URL format: '
      'tsumino.com/Book/Info/ID/TITLE - got $url instead',
    );
  }

  @override
  Future<void> rip() async {
    sendUpdate(RipStatus.loadingResource, url.toString());

    Document? page;
    try {
      page = await getFirstPage();
    } catch (e) {
      sendUpdate(RipStatus.ripErrored, e.toString());
      return;
    }

    if (page == null || isStopped) {
      sendUpdate(RipStatus.ripComplete, workingDir.path);
      return;
    }

    final downloads = <RipperDownload>[];
    var index = 0;
    for (final imageUrl in await getURLsFromPage(page)) {
      if (isStopped) break;
      index++;
      final imageUri = Uri.parse(imageUrl);
      downloads.add(
        RipperDownload(
          url: imageUri,
          saveAs:
              File(p.join(workingDir.path, fileNameForUrl(imageUri, index))),
          allowDuplicate: true,
        ),
      );
    }

    await downloadFiles(downloads);
    sendUpdate(RipStatus.ripComplete, workingDir.path);
  }

  Future<Document?> getFirstPage() async {
    final response = await Http.getResponse(url);
    _cookies.addAll(
      ThechiveRipper.cookiesFromSetCookieHeader(response.headers['set-cookie']),
    );
    final page = Document.html(response.body);
    final blacklistedTag = checkTags(
      Utils.getConfigStringList('tsumino.blacklist.tags'),
      tagsFromDocument(page),
    );
    if (blacklistedTag != null) {
      sendUpdate(
        RipStatus.downloadWarn,
        'Skipping $url as it contains the blacklisted tag "$blacklistedTag"',
      );
      return null;
    }
    return page;
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    final pageUrls = await getPageUrls();
    if (pageUrls == null) return const [];
    return imageUrlsFromReaderPageUrls(pageUrls);
  }

  @override
  Future<Uri?> getNextPage(Document page) async => null;

  Future<List<String>?> getPageUrls() async {
    final albumId = albumIdFromUrl(url);
    if (albumId == null) return null;

    final requestCookies = <String, String>{
      ..._cookies,
      'ASP.NET_SessionId': 'c4rbzccf0dvy3e0cloolmlkq',
    };
    final loadUri = Uri.parse('http://www.tsumino.com/Read/Load')
        .replace(queryParameters: {'q': albumId});
    try {
      final text = await Http.getText(
        loadUri,
        headers: {'Referer': 'http://www.tsumino.com/Read/View/$albumId'},
        cookies: requestCookies,
      );
      return readerPageUrlsFromLoadResponse(text);
    } catch (_) {
      sendUpdate(
        RipStatus.downloadErrored,
        'Unable to download album, please compete the captcha at '
        'http://www.tsumino.com/Read/Auth/$albumId and try again',
      );
      return null;
    }
  }

  static List<String> tagsFromDocument(Document page) {
    return [
      for (final tag in page.querySelectorAll('div#Tag > a'))
        tag.text.toLowerCase(),
    ];
  }

  static String? checkTags(List<String> blacklist, List<String> tags) {
    final normalizedTags = tags.map((tag) => tag.toLowerCase()).toSet();
    for (final tag in blacklist) {
      final normalizedTag = tag.toLowerCase();
      if (normalizedTags.contains(normalizedTag)) return normalizedTag;
    }
    return null;
  }

  static List<String> readerPageUrlsFromLoadResponse(String body) {
    final jsonInfo = body
        .replaceAll('<html>', '')
        .replaceAll('<head></head>', '')
        .replaceAll('<body>', '')
        .replaceAll('</body>', '')
        .replaceAll('</html>', '')
        .replaceAll('\n', '');
    final json = jsonDecode(jsonInfo) as Map<String, dynamic>;
    return [
      for (final value in json['reader_page_urls'] as List<dynamic>)
        value as String,
    ];
  }

  static List<String> imageUrlsFromReaderPageUrls(List<String> pageUrls) {
    return [
      for (final pageUrl in pageUrls)
        'http://www.tsumino.com/Image/Object?name=${Uri.encodeQueryComponent(pageUrl)}',
    ];
  }

  static String? albumIdFromUrl(Uri url) {
    final match = _albumIdPattern.firstMatch(url.toString());
    return match?.group(1);
  }

  static String fileNameForUrl(Uri uri, int index) {
    final fileName =
        uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'file';
    return Utils.sanitizeSaveAs('${prefix(index)}$fileName');
  }

  static String prefix(int index) {
    if (!Utils.getConfigBoolean('download.save_order', true)) return '';
    return '${index.toString().padLeft(3, '0')}_';
  }
}
