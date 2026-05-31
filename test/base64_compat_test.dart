import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Java Base64.decode compatibility', () {
    test('decodes the Java Base64Test fixture', () {
      expect(utf8.decode(base64.decode('dGVzdA==')), 'test');
    });

    test('decodes credentials used by Java TwodgalleriesRipper', () {
      expect(utf8.decode(base64.decode('cmlwbWU=')), 'ripme');
      expect(utf8.decode(base64.decode('cmlwcGVy')), 'ripper');
    });

    test('decodes nested JSON payloads used by Java CliphunterRipper', () {
      final encodedUrl = base64.encode(utf8.encode('{"u":{"l":"video.mp4"}}'));
      final encodedOuter = base64.encode(utf8.encode('{"url":"$encodedUrl"}'));

      final outer = jsonDecode(utf8.decode(base64.decode(encodedOuter)))
          as Map<String, dynamic>;
      final inner =
          jsonDecode(utf8.decode(base64.decode(outer['url'] as String)))
              as Map<String, dynamic>;

      expect(inner['u'], {'l': 'video.mp4'});
    });
  });
}
