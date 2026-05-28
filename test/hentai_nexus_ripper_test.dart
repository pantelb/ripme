import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' show parse;
import 'package:ripme/ripper/rippers/hentai_nexus_ripper.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('matches Java host, domain, URL support, and GIDs', () async {
    final view =
        HentaiNexusRipper(Uri.parse('https://hentainexus.com/view/9202'));
    final read =
        HentaiNexusRipper(Uri.parse('https://hentainexus.com/read/9202#001'));

    expect(view.canRip(view.url), isTrue);
    expect(read.canRip(read.url), isTrue);
    expect(view.getHost(), 'hentainexus');
    expect(view.getDomain(), 'hentainexus.com');
    expect(await view.getGID(view.url), '9202');
    expect(await read.getGID(read.url), '9202');
  });

  test('extracts encoded initReader payloads from scripts', () {
    final page = parse(r'''
      <script>
        window.foo = true;
        initReader("abc123", "Ignored title");
      </script>
    ''');

    expect(HentaiNexusRipper.jsonEncodedStringFromPage(page), 'abc123');
  });

  test('decodes initReader JSON and builds image URLs like Java', () {
    const jsonText =
        '{"b":"https://cdn.hn/","r":"gallery/","i":"9202","f":[{"h":"hash1","p":"001.jpg"},{"h":"hash2","p":"002.png"}]}';
    final encoded = _encodeLikeInitReader(jsonText);
    final decoded = HentaiNexusRipper.decodeJsonString(encoded);

    expect(decoded, jsonText);
    expect(HentaiNexusRipper.urlsFromJson(jsonDecode(decoded)), [
      'https://cdn.hn/gallery/hash1/9202/001.jpg',
      'https://cdn.hn/gallery/hash2/9202/002.png',
    ]);
  });

  test('uses Java-style ordered filename prefixes', () async {
    SharedPreferences.setMockInitialValues({'download.save_order': true});
    await Utils.init();
    expect(
      HentaiNexusRipper.fileNameForUrl(
        Uri.parse('https://cdn.hn/gallery/hash/9202/image:name.jpg'),
        5,
      ),
      '005_image',
    );

    SharedPreferences.setMockInitialValues({'download.save_order': false});
    await Utils.init();
    expect(
      HentaiNexusRipper.fileNameForUrl(
        Uri.parse('https://cdn.hn/gallery/hash/9202/image.jpg'),
        5,
      ),
      'image.jpg',
    );
  });
}

String _encodeLikeInitReader(String jsonText) {
  final header = List<int>.generate(0x40, (i) => (i * 17 + 29) & 0xff);
  final stream = _hentaiNexusKeyStream(header, jsonText.length);
  final payload = utf8.encode(jsonText);
  final encoded = <int>[
    ...header,
    for (var i = 0; i < payload.length; i++) payload[i] ^ stream[i],
  ];
  return base64.encode(encoded);
}

List<int> _hentaiNexusKeyStream(List<int> header, int length) {
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

  var magicByte = 0;
  for (var i = 0; i < 0x40; i++) {
    magicByte = (magicByte ^ header[i]) & 0xff;
    for (var j = 0; j < 0x8; j++) {
      magicByte =
          ((magicByte & 1) == 1 ? (magicByte >> 1) ^ 0xc : magicByte >> 1) &
              0xff;
    }
  }
  final magicByteTranslated = unknownArray[magicByte & 0x7];

  final state = [for (var i = 0; i < 0x100; i++) i];
  var newIndex = 0;
  for (var i = 0; i < 0x100; i++) {
    newIndex = (newIndex + state[i] + header[i % 0x40]) % 0x100;
    final backup = state[i];
    state[i] = state[newIndex];
    state[newIndex] = backup;
  }

  var index1 = 0;
  var index2 = 0;
  var index3 = 0;
  var xorNumber = 0;
  return [
    for (var i = 0; i < length; i++)
      (() {
        index1 = (index1 + magicByteTranslated) % 0x100;
        index2 = (index3 + state[(index2 + state[index1]) % 0x100]) % 0x100;
        index3 = (index3 + index1 + state[index1]) % 0x100;
        final swap = state[index1];
        state[index1] = state[index2];
        state[index2] = swap;
        xorNumber = state[(index2 +
                state[(index1 + state[(xorNumber + index3) % 0x100]) % 0x100]) %
            0x100];
        return xorNumber;
      })(),
  ];
}
