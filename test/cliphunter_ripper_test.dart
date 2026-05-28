import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ripme/ripper/rippers/cliphunter_ripper.dart';

void main() {
  test('matches Java URL detection and GID parsing', () async {
    final ripper =
        CliphunterRipper(Uri.parse('https://www.cliphunter.com/w/12345/title'));

    expect(ripper.canRip(Uri.parse('https://cliphunter.com/w/12345')), isTrue);
    expect(
        ripper.canRip(Uri.parse('https://m.cliphunter.com/w/12345/x')), isTrue);
    expect(ripper.canRip(Uri.parse('https://www.cliphunter.com/videos/12345')),
        isFalse);
    expect(await ripper.getGID(Uri.parse('https://cliphunter.com/w/12345')),
        '12345');

    expect(
      () => ripper.getGID(Uri.parse('https://cliphunter.com/videos/12345')),
      throwsFormatException,
    );
  });

  test('decodes nested Base64 flashVars and decrypts video URL like Java', () {
    const encrypted =
        r'aqqvr$==cil&cyzvaplqdx&cfn=ezidfr=rmnvyd&nv4?qfkdl(mbc^q(1';
    const decoded =
        'https://cdn.cliphunter.com/videos/sample.mp4?token=abc&t=1';
    final urlJson = base64.encode(utf8.encode(jsonEncode({
      'u': {'l': encrypted}
    })));
    final flashVars = base64.encode(utf8.encode(jsonEncode({'url': urlJson})));
    final html = "<script>var flashVars = {d: '$flashVars'};</script>";

    expect(CliphunterRipper.decryptVideoUrl(encrypted), decoded);
    expect(CliphunterRipper.videoUrlFromHtml(html).toString(), decoded);
  });

  test('uses Java-style video filename prefix and video URL referrer',
      () async {
    final ripper =
        _Harness(Uri.parse('https://www.cliphunter.com/w/24680/example'));

    final request = await ripper.getVideoDownloadForRip(ripper.url);

    expect(request.url.toString(),
        'https://cdn.cliphunter.com/videos/movie.mp4?download=1');
    expect(request.fileName, 'cliphunter_24680movie.mp4');
    expect(request.headers, {
      'Referer': 'https://cdn.cliphunter.com/videos/movie.mp4?download=1',
    });
  });
}

class _Harness extends CliphunterRipper {
  _Harness(super.url);

  @override
  Future<Uri> getVideoURLForRip(Uri url) async =>
      Uri.parse('https://cdn.cliphunter.com/videos/movie.mp4?download=1');
}
