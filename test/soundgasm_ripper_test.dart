import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:ripme/ripper/rippers/soundgasm_ripper.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('SoundgasmRipper matches Java host, domain, support, and GID', () async {
    final url = Uri.parse(
      'https://soundgasm.net/u/HTMLExamples/Making-Text-into-a-Soundgasm-Audio-Link',
    );
    final ripper = SoundgasmRipper(url);

    expect(ripper.canRip(url), isTrue);
    expect(ripper.canRip(Uri.parse('https://www.soundgasm.net/u/user/id')),
        isTrue);
    expect(ripper.canRip(Uri.parse('https://soundgasm.example/u/user/id')),
        isFalse);
    expect(ripper.getHost(), 'soundgasm');
    expect(ripper.getDomain(), 'soundgasm.net');
    expect(
      await ripper.getGID(url),
      'Making-Text-into-a-Soundgasm-Audio-Link',
    );
    expect(
      await ripper.getGID(Uri.parse('https://www.soundgasm.net/u/user/id')),
      'id',
    );
    expect(
      await ripper.getGID(
        Uri.parse('https://soundgasm.net/u/user/invalid.slug'),
      ),
      'invalid',
    );

    await expectLater(
      ripper.getGID(Uri.parse('https://soundgasm.net/not/user/id')),
      throwsA(isA<FormatException>()),
    );
  });

  test('SoundgasmRipper extracts script m4a URLs like Java', () {
    final page = html.parse(r'''
      <script>
        window.sound = { m4a: "https://media.soundgasm.net/sounds/one.m4a" };
      </script>
      <script>
        window.other = { m4a: "http://media.soundgasm.net/sounds/two.m4a" };
      </script>
    ''');

    expect(SoundgasmRipper.audioUrlsFromDocument(page), [
      'https://media.soundgasm.net/sounds/one.m4a',
      'http://media.soundgasm.net/sounds/two.m4a',
    ]);
  });

  test('SoundgasmRipper keeps Java greedy m4a regex behavior', () {
    final page = html.parse(r'''
      <script>
        window.sound = { m4a: "https://media.soundgasm.net/sounds/one.m4a", x: "tail" };
      </script>
    ''');

    expect(SoundgasmRipper.audioUrlsFromDocument(page), [
      'https://media.soundgasm.net/sounds/one.m4a", x: "tail',
    ]);
  });

  test('SoundgasmRipper uses Java-style configurable ordered filenames',
      () async {
    SharedPreferences.setMockInitialValues({'download.save_order': true});
    await Utils.init();
    expect(
      SoundgasmRipper.fileNameForUrl(
        Uri.parse('https://media.soundgasm.net/sounds/example.m4a?token=1'),
        7,
      ),
      '007_example.m4a',
    );

    SharedPreferences.setMockInitialValues({'download.save_order': false});
    await Utils.init();
    expect(
      SoundgasmRipper.fileNameForUrl(
        Uri.parse('https://media.soundgasm.net/sounds/example.m4a'),
        7,
      ),
      'example.m4a',
    );
  });
}
