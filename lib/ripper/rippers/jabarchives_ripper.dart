import 'dart:io';

import 'package:html/dom.dart';
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';
import '../abstract_ripper.dart';

class JabArchivesRipper extends AbstractHTMLRipper {
  JabArchivesRipper(super.url);

  static final RegExp _gidPattern = RegExp(
    r'^https?://(?:www\.)?jabarchives\.com/main/view/([a-zA-Z0-9_]+).*$',
  );

  final Map<String, String> itemPrefixes = <String, String>{};

  @override
  String getHost() => 'jabarchives';

  String getDomain() => 'jabarchives.com';

  @override
  bool canRip(Uri url) => url.host.endsWith(getDomain());

  @override
  Future<String> getGID(Uri url) async {
    final match = _gidPattern.firstMatch(url.toString());
    if (match != null) return match.group(1)!;

    throw FormatException(
      'Expected javarchives.com URL format: '
      'jabarchives.com/main/view/albumname - got $url instead',
    );
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

    while (!isStopped) {
      final downloads = <RipperDownload>[];
      for (final imageUrl in await getURLsFromPage(page)) {
        if (isStopped) break;
        final imageUri = Uri.parse(imageUrl);
        downloads.add(
          RipperDownload(
            url: imageUri,
            saveAs: File(
              p.join(
                workingDir.path,
                fileNameForUrl(
                  imageUri,
                  prefix: itemPrefixes[imageUrl] ?? '',
                ),
              ),
            ),
          ),
        );
      }
      await downloadFiles(downloads);

      if (isStopped) break;
      final nextUri = await getNextPage(page);
      if (nextUri == null) break;

      try {
        sendUpdate(RipStatus.loadingResource, nextUri.toString());
        await Http.delay(const Duration(milliseconds: 500));
        page = await Http.get(nextUri);
      } catch (_) {
        break;
      }
    }

    sendUpdate(RipStatus.ripComplete, workingDir.path);
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    return imageUrlsFromDocument(page, itemPrefixes);
  }

  @override
  Future<Uri?> getNextPage(Document page) async {
    final href = page.querySelector('a[title="Next page"]')?.attributes['href'];
    if (href == null) return null;
    return Uri.parse('https://jabarchives.com$href');
  }

  static List<String> imageUrlsFromDocument(
    Document page,
    Map<String, String> itemPrefixes,
  ) {
    final result = <String>[];
    for (final image in page.querySelectorAll('#contentMain img')) {
      final source = image.attributes['src'] ?? '';
      final imageUrl = 'https://jabarchives.com${source.replaceAll(
        'thumb',
        'large',
      )}';
      result.add(imageUrl);

      final title = image.parent?.attributes['title'] ?? '';
      itemPrefixes[imageUrl] = '${getSlug(title)}_';
    }
    return result;
  }

  static String getSlug(String input) {
    final withoutWhitespace = input.replaceAll(RegExp(r'\s'), '-');
    final normalized = _stripCommonLatinDiacritics(withoutWhitespace);
    return normalized.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '').toLowerCase();
  }

  static String fileNameForUrl(Uri uri, {required String prefix}) {
    final fileName =
        uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'file';
    return Utils.sanitizeSaveAs('$prefix$fileName');
  }

  static String _stripCommonLatinDiacritics(String value) {
    const replacements = <String, String>{
      'À': 'A',
      'Á': 'A',
      'Â': 'A',
      'Ã': 'A',
      'Ä': 'A',
      'Å': 'A',
      'Ā': 'A',
      'Ă': 'A',
      'Ą': 'A',
      'à': 'a',
      'á': 'a',
      'â': 'a',
      'ã': 'a',
      'ä': 'a',
      'å': 'a',
      'ā': 'a',
      'ă': 'a',
      'ą': 'a',
      'Ç': 'C',
      'Ć': 'C',
      'Ĉ': 'C',
      'Ċ': 'C',
      'Č': 'C',
      'ç': 'c',
      'ć': 'c',
      'ĉ': 'c',
      'ċ': 'c',
      'č': 'c',
      'Ð': 'D',
      'Ď': 'D',
      'Đ': 'D',
      'ð': 'd',
      'ď': 'd',
      'đ': 'd',
      'È': 'E',
      'É': 'E',
      'Ê': 'E',
      'Ë': 'E',
      'Ē': 'E',
      'Ĕ': 'E',
      'Ė': 'E',
      'Ę': 'E',
      'Ě': 'E',
      'è': 'e',
      'é': 'e',
      'ê': 'e',
      'ë': 'e',
      'ē': 'e',
      'ĕ': 'e',
      'ė': 'e',
      'ę': 'e',
      'ě': 'e',
      'Ĝ': 'G',
      'Ğ': 'G',
      'Ġ': 'G',
      'Ģ': 'G',
      'ĝ': 'g',
      'ğ': 'g',
      'ġ': 'g',
      'ģ': 'g',
      'Ĥ': 'H',
      'Ħ': 'H',
      'ĥ': 'h',
      'ħ': 'h',
      'Ì': 'I',
      'Í': 'I',
      'Î': 'I',
      'Ï': 'I',
      'Ĩ': 'I',
      'Ī': 'I',
      'Ĭ': 'I',
      'Į': 'I',
      'İ': 'I',
      'ì': 'i',
      'í': 'i',
      'î': 'i',
      'ï': 'i',
      'ĩ': 'i',
      'ī': 'i',
      'ĭ': 'i',
      'į': 'i',
      'ı': 'i',
      'Ĵ': 'J',
      'ĵ': 'j',
      'Ķ': 'K',
      'ķ': 'k',
      'Ĺ': 'L',
      'Ļ': 'L',
      'Ľ': 'L',
      'Ŀ': 'L',
      'Ł': 'L',
      'ĺ': 'l',
      'ļ': 'l',
      'ľ': 'l',
      'ŀ': 'l',
      'ł': 'l',
      'Ñ': 'N',
      'Ń': 'N',
      'Ņ': 'N',
      'Ň': 'N',
      'ñ': 'n',
      'ń': 'n',
      'ņ': 'n',
      'ň': 'n',
      'Ò': 'O',
      'Ó': 'O',
      'Ô': 'O',
      'Õ': 'O',
      'Ö': 'O',
      'Ø': 'O',
      'Ō': 'O',
      'Ŏ': 'O',
      'Ő': 'O',
      'ò': 'o',
      'ó': 'o',
      'ô': 'o',
      'õ': 'o',
      'ö': 'o',
      'ø': 'o',
      'ō': 'o',
      'ŏ': 'o',
      'ő': 'o',
      'Ŕ': 'R',
      'Ŗ': 'R',
      'Ř': 'R',
      'ŕ': 'r',
      'ŗ': 'r',
      'ř': 'r',
      'Ś': 'S',
      'Ŝ': 'S',
      'Ş': 'S',
      'Š': 'S',
      'ś': 's',
      'ŝ': 's',
      'ş': 's',
      'š': 's',
      'Ţ': 'T',
      'Ť': 'T',
      'Ŧ': 'T',
      'ţ': 't',
      'ť': 't',
      'ŧ': 't',
      'Ù': 'U',
      'Ú': 'U',
      'Û': 'U',
      'Ü': 'U',
      'Ũ': 'U',
      'Ū': 'U',
      'Ŭ': 'U',
      'Ů': 'U',
      'Ű': 'U',
      'Ų': 'U',
      'ù': 'u',
      'ú': 'u',
      'û': 'u',
      'ü': 'u',
      'ũ': 'u',
      'ū': 'u',
      'ŭ': 'u',
      'ů': 'u',
      'ű': 'u',
      'ų': 'u',
      'Ŵ': 'W',
      'ŵ': 'w',
      'Ý': 'Y',
      'Ŷ': 'Y',
      'Ÿ': 'Y',
      'ý': 'y',
      'ÿ': 'y',
      'ŷ': 'y',
      'Ź': 'Z',
      'Ż': 'Z',
      'Ž': 'Z',
      'ź': 'z',
      'ż': 'z',
      'ž': 'z',
    };

    final buffer = StringBuffer();
    for (final rune in value.runes) {
      final character = String.fromCharCode(rune);
      buffer.write(replacements[character] ?? character);
    }
    return buffer.toString();
  }
}
