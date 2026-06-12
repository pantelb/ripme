import 'package:flutter_test/flutter_test.dart';
import 'package:ripme/clipboard_autorip.dart';

void main() {
  test('uses the Java 1000 ms clipboard polling interval', () {
    expect(
      ClipboardAutoripTracker.pollInterval,
      const Duration(milliseconds: 1000),
    );
  });

  test('matches Java clipboard URL schemes only at the start', () {
    final tracker = ClipboardAutoripTracker();

    expect(
      tracker.takeNewUrl('https://example.com/gallery trailing text'),
      'https://example.com/gallery',
    );
    expect(
      tracker.takeNewUrl(' ftp://example.com/archive'),
      isNull,
    );
    expect(
      tracker.takeNewUrl('ftp://example.com/archive'),
      'ftp://example.com/archive',
    );
    expect(
      tracker.takeNewUrl('file://localhost/path/image.jpg'),
      'file://localhost/path/image.jpg',
    );
  });

  test('keeps the first Java regex match once per autorip session', () {
    final tracker = ClipboardAutoripTracker();
    const clipboard = 'https://example.com/first https://example.com/second';

    expect(tracker.takeNewUrl(clipboard), 'https://example.com/first');
    expect(tracker.takeNewUrl(clipboard), isNull);
    expect(
      ClipboardAutoripTracker().takeNewUrl(clipboard),
      'https://example.com/first',
    );
  });

  test('keeps Java trailing punctuation and final-character boundaries', () {
    final tracker = ClipboardAutoripTracker();

    expect(
      tracker.takeNewUrl('https://example.com/gallery.'),
      'https://example.com/gallery',
    );
    expect(tracker.takeNewUrl('not a URL'), isNull);
    expect(tracker.takeNewUrl(null), isNull);
  });
}
