import 'dart:convert';
import 'dart:io';

import 'package:html/dom.dart';
import 'package:path/path.dart' as p;

import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_json_ripper.dart';
import '../abstract_ripper.dart';

class HentaiNexusRipper extends AbstractJSONRipper {
  HentaiNexusRipper(super.url);

  static const String domain = 'hentainexus.com';
  static final RegExp _gidPattern = RegExp(
      r'^https?://hentainexus\.com/(?:view|read)/([0-9]+)(?:\#[0-9]+)*$');

  @override
  String getHost() => 'hentainexus';

  String getDomain() => domain;

  @override
  bool canRip(Uri url) => _gidPattern.hasMatch(url.toString());

  @override
  Future<String> getGID(Uri url) async {
    final match = _gidPattern.firstMatch(url.toString());
    if (match != null) return match.group(1)!;
    throw FormatException(
      'Expected hentainexus.com URL format: hentainexus.com/view/id OR hentainexus.com/read/id - got ${url}instead',
    );
  }

  @override
  Future<void> parseJSON(Uri url) async {
    final json = await getFirstPage();
    final downloads = <RipperDownload>[];
    var index = 0;
    for (final imageUrl in urlsFromJson(json)) {
      if (isStopped) break;
      index++;
      final uri = Uri.parse(imageUrl);
      downloads.add(
        RipperDownload(
          url: uri,
          saveAs: File(p.join(workingDir.path, fileNameForUrl(uri, index))),
        ),
      );
    }
    await downloadFiles(downloads);
  }

  Future<Map<String, dynamic>> getFirstPage() async {
    final encoded = await getJsonEncodedStringFromPage();
    final decoded = decodeJsonString(encoded);
    return jsonDecode(decoded) as Map<String, dynamic>;
  }

  Future<String> getJsonEncodedStringFromPage() async {
    final readUrl =
        Uri.parse('http://hentainexus.com/read/${await getGID(url)}');
    final page = await Http.get(readUrl);
    return jsonEncodedStringFromPage(page);
  }

  static String jsonEncodedStringFromPage(Document page) {
    for (final script in page.getElementsByTagName('script')) {
      final data = script.text.replaceAll(RegExp(r'[\r\n\t]'), '').trim();
      if (!data.contains('initReader')) continue;
      final match = RegExp(r'initReader\("(.*?)",').firstMatch(data);
      if (match != null) return match.group(1)!;
    }
    return '';
  }

  static List<String> urlsFromJson(Map<String, dynamic> json) {
    final images = json['f'];
    final host = json['b'] as String? ?? '';
    final folder = json['r'] as String? ?? '';
    final id = json['i'] as String? ?? '';
    if (images is! List) return const [];

    return [
      for (final image in images)
        if (image is Map && image['h'] is String && image['p'] is String)
          '$host$folder${image['h']}/$id/${image['p']}',
    ];
  }

  static String decodeJsonString(String jsonEncodedString) {
    final jsonBytes = base64.decode(jsonEncodedString);
    final unknownArray = <int>[];
    final indexesToUse = <int>[];

    for (var i = 0x2; unknownArray.length < 0x10; ++i) {
      if (!indexesToUse.contains(i)) {
        unknownArray.add(i);
        for (var j = i << 0x1; j <= 0x100; j += i) {
          if (!indexesToUse.contains(j)) indexesToUse.add(j);
        }
      }
    }

    var magicByte = 0x0;
    for (var i = 0x0; i < 0x40; i++) {
      magicByte = (magicByte ^ jsonBytes[i]) & 0xff;
      for (var j = 0x0; j < 0x8; j++) {
        magicByte = ((magicByte & 0x1) == 1
                ? (magicByte >> 0x1) ^ 0xc
                : magicByte >> 0x1) &
            0xff;
      }
    }

    magicByte = magicByte & 0x7;
    final newArray = [for (var i = 0x0; i < 0x100; i++) i];

    var newIndex = 0;
    for (var i = 0x0; i < 0x100; i++) {
      newIndex = (newIndex + newArray[i] + jsonBytes[i % 0x40]) % 0x100;
      final backup = newArray[i];
      newArray[i] = newArray[newIndex];
      newArray[newIndex] = backup;
    }

    final magicByteTranslated = unknownArray[magicByte];
    var index1 = 0x0;
    var index2 = 0x0;
    var index3 = 0x0;
    var xorNumber = 0x0;
    final decoded = StringBuffer();

    for (var i = 0x0; i + 0x40 < jsonBytes.length; i++) {
      index1 = (index1 + magicByteTranslated) % 0x100;
      index2 = (index3 + newArray[(index2 + newArray[index1]) % 0x100]) % 0x100;
      index3 = (index3 + index1 + newArray[index1]) % 0x100;
      final swap1 = newArray[index1];
      newArray[index1] = newArray[index2];
      newArray[index2] = swap1;
      xorNumber = newArray[(index2 +
              newArray[
                  (index1 + newArray[(xorNumber + index3) % 0x100]) % 0x100]) %
          0x100];
      decoded.writeCharCode((jsonBytes[i + 0x40] ^ xorNumber) & 0xff);
    }

    return decoded.toString();
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
}
