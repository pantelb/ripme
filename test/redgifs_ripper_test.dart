import 'package:flutter_test/flutter_test.dart';
import 'package:ripme/ripper/rippers/redgifs_ripper.dart';

void main() {
  test('sanitizes legacy Redgifs URL forms', () {
    expect(
      RedgifsRipper.sanitizeUrl(
              Uri.parse('https://thumbs.redgifs.com/watch/example/amp'))
          .toString(),
      'https://redgifs.com/watch/example',
    );
    expect(
      RedgifsRipper.sanitizeUrl(
              Uri.parse('https://www.gifdeliverynetwork.com/exampleid'))
          .toString(),
      'https://www.redgifs.com/watch/exampleid',
    );
    expect(
      RedgifsRipper.sanitizeUrl(
              Uri.parse('https://www.redgifs.com/gifs/detail/exampleid'))
          .toString(),
      'https://www.redgifs.com/watch/exampleid',
    );
  });

  test('extracts Redgifs GIDs for singleton, profile, search, and tags',
      () async {
    expect(
        await RedgifsRipper(
                Uri.parse('https://www.redgifs.com/watch/exampleid-extra'))
            .getGID(Uri.parse('https://www.redgifs.com/watch/exampleid-extra')),
        'exampleid');
    expect(
        await RedgifsRipper(
                Uri.parse('https://www.redgifs.com/users/example_user'))
            .getGID(Uri.parse('https://www.redgifs.com/users/example_user')),
        'example_user');
    expect(
        await RedgifsRipper(
                Uri.parse('https://www.redgifs.com/search?query=take+a+shot'))
            .getGID(
                Uri.parse('https://www.redgifs.com/search?query=take+a+shot')),
        'take-a-shot');
    expect(
        await RedgifsRipper(
                Uri.parse('https://www.redgifs.com/gifs/funny,safe?tab=gifs'))
            .getGID(
                Uri.parse('https://www.redgifs.com/gifs/funny,safe?tab=gifs')),
        'funny_safe');
  });
}
