import 'dart:io';

import 'package:html/dom.dart';
import 'package:http/http.dart' show Response;
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';
import '../abstract_ripper.dart';

class VscoRipper extends AbstractHTMLRipper {
  static const String domain = 'vsco.co';
  static final RegExp _mediaGidPattern =
      RegExp(r'^https?://vsco\.co/([a-zA-Z0-9-]+)/media/([a-zA-Z0-9]+)$');
  static final RegExp _profileGidPattern =
      RegExp(r'^https?://vsco\.co/([a-zA-Z0-9-]+)(/gallery)?(/)?$');

  VscoRipper(super.url);

  int _pageNumber = 1;

  @override
  String getHost() => 'vsco';

  String getDomain() => domain;

  @override
  bool canRip(Uri url) {
    if (!url.host.toLowerCase().endsWith(domain)) return false;
    final text = url.toString();
    return !text.contains('/store/') ||
        !text.contains('/feed/') ||
        !text.contains('/login/') ||
        !text.contains('/journal/') ||
        !text.contains('/collection/') ||
        !text.contains('/images/') ||
        text.contains('/media/');
  }

  @override
  Future<String> getGID(Uri url) async {
    final mediaMatch = _mediaGidPattern.firstMatch(url.toString());
    if (mediaMatch != null) {
      final imageNum = mediaMatch.group(2)!.substring(0, 5);
      return '${mediaMatch.group(1)!}/$imageNum';
    }

    final profileMatch = _profileGidPattern.firstMatch(url.toString());
    if (profileMatch != null) return profileMatch.group(1)!;

    throw FormatException(
      'Expected a URL to a single image or to a member profile, got $url instead',
    );
  }

  @override
  Future<void> rip() async {
    sendUpdate(RipStatus.loadingResource, url.toString());
    try {
      final page = await Http.get(url);
      final downloads = <RipperDownload>[];
      var index = 0;
      for (final imageUrl in await getURLsFromPage(page)) {
        if (isStopped) break;
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
    } catch (e) {
      sendUpdate(RipStatus.ripErrored, e.toString());
    }
    sendUpdate(RipStatus.ripComplete, workingDir.path);
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    if (url.toString().contains('/media/')) {
      final image = imageUrlFromMediaPage(page);
      return image == null ? const [] : [image];
    }

    final username = userNameFromUrl(url);
    final token = await getUserToken();
    final siteId = await getSiteId(token, username);
    final toRip = <String>[];
    while (true) {
      final profileJson = await getProfileJson(token, _pageNumber, siteId);
      toRip.addAll(profileImageUrls(profileJson));
      final total = _toInt(profileJson['total']);
      if (_pageNumber * 1000 > total) return toRip;
      _pageNumber++;
    }
  }

  @override
  Future<Uri?> getNextPage(Document page) async => null;

  Future<String> getUserToken() async {
    final response = await Http.getResponse(
      Uri.parse('https://vsco.co/content/Static'),
    );
    final cookies = _cookiesFromResponse(response);
    final token = cookies['vs'];
    if (token == null) throw const HttpException('Could not get user tkn');
    return token;
  }

  Future<String> getSiteId(String token, String username) async {
    final json = await Http.getJSON(
      Uri.parse('https://vsco.co/ajxp/$token/2.0/sites?subdomain=$username'),
      cookies: {'vs': token},
    );
    if (json is Map) {
      final sites = json['sites'];
      if (sites is List && sites.isNotEmpty && sites.first is Map) {
        return _toInt((sites.first as Map)['id']).toString();
      }
    }
    throw const HttpException('Could not get site id');
  }

  Future<Map<String, dynamic>> getProfileJson(
    String token,
    int page,
    String siteId,
  ) async {
    final json = await Http.getJSON(
      Uri.parse(
        'https://vsco.co/ajxp/$token/2.0/medias?site_id=$siteId&page=$page&size=1000',
      ),
      cookies: {'vs': token},
    );
    if (json is Map<String, dynamic>) return json;
    throw const HttpException('Could not profile images');
  }

  static String userNameFromUrl(Uri url) {
    final match = _profileGidPattern.firstMatch(url.toString());
    if (match != null) return match.group(1)!;
    throw FormatException('Could not find VSCO username in $url');
  }

  static String? imageUrlFromMediaPage(Document page) {
    for (final metaTag in page.getElementsByTagName('meta')) {
      if (metaTag.attributes['property'] != 'og:image') continue;
      return (metaTag.attributes['content'] ?? '')
          .replaceAll(RegExp(r'\?h=[0-9]+'), '');
    }
    return null;
  }

  static List<String> profileImageUrls(Map<String, dynamic> profileJson) {
    final media = profileJson['media'];
    if (media is! List) return const [];
    return [
      for (final item in media)
        if (item is Map && item['responsive_url'] != null)
          'https://${item['responsive_url']}',
    ];
  }

  static String fileNameForUrl(Uri uri, int index) {
    var fileName = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'file';
    for (final separator in ['?', '#', '&', ':']) {
      final separatorIndex = fileName.indexOf(separator);
      if (separatorIndex >= 0) fileName = fileName.substring(0, separatorIndex);
    }
    return Utils.sanitizeSaveAs('${_prefix(index)}$fileName');
  }

  static String _prefix(int index) {
    if (!Utils.getConfigBoolean('download.save_order', true)) return '';
    return '${index.toString().padLeft(3, '0')}_';
  }

  static Map<String, String> _cookiesFromResponse(Response response) {
    final cookies = <String, String>{};
    final setCookie = response.headers['set-cookie'];
    if (setCookie == null || setCookie.isEmpty) return cookies;
    for (final cookie in setCookie.split(',')) {
      final firstPart = cookie.split(';').first.trim();
      final separator = firstPart.indexOf('=');
      if (separator <= 0) continue;
      cookies[firstPart.substring(0, separator)] =
          firstPart.substring(separator + 1);
    }
    return cookies;
  }

  static int _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
