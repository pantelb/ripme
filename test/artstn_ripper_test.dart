import 'package:flutter_test/flutter_test.dart';
import 'package:ripme/ripper/rippers/artstn_ripper.dart';

void main() {
  test('matches Java short-domain canRip behavior', () {
    final ripper = ArtstnRipper(Uri.parse('https://artstn.co/p/JlE15Z'));

    expect(ripper.canRip(Uri.parse('https://artstn.co/p/JlE15Z')), isTrue);
    expect(
        ripper.canRip(Uri.parse('https://www.artstation.com/artwork/JlE15Z')),
        isFalse);
  });

  test('resolves redirect locations recursively like the Java ripper', () {
    expect(
      ArtstnRipper.redirectTarget(
        Uri.parse('https://artstn.co/p/JlE15Z'),
        302,
        'https://www.artstation.com/artwork/JlE15Z',
      ).toString(),
      'https://www.artstation.com/artwork/JlE15Z',
    );
    expect(
      ArtstnRipper.redirectTarget(
        Uri.parse('https://artstn.co/p/JlE15Z'),
        301,
        '/artwork/JlE15Z',
      ).toString(),
      'https://artstn.co/artwork/JlE15Z',
    );
    expect(
      ArtstnRipper.redirectTarget(
          Uri.parse('https://artstn.co/p/JlE15Z'), 200, null),
      isNull,
    );
  });
}
