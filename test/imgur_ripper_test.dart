import 'package:flutter_test/flutter_test.dart';
import 'package:ripme/ripper/rippers/imgur_ripper.dart';

void main() {
  test('ImgurRipper canRip', () {
    final ripper = ImgurRipper(Uri.parse('https://imgur.com/a/G058j5F'));
    expect(ripper.canRip(Uri.parse('https://imgur.com/a/G058j5F')), isTrue);
    expect(ripper.canRip(Uri.parse('https://google.com')), isFalse);
  });

  test('ImgurRipper getHost', () {
    final ripper = ImgurRipper(Uri.parse('https://imgur.com/a/G058j5F'));
    expect(ripper.getHost(), equals('imgur'));
  });
}
