import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' show parse;
import 'package:ripme/ripper/rippers/fivehundredpx_ripper.dart';

void main() {
  Future<String> fakeUserId(String username) async => '1913159';

  test('matches Java host, domain, GIDs, and API base URLs', () async {
    final user = FivehundredpxRipper(Uri.parse('https://500px.com/tsyganov'));

    expect(user.canRip(user.url), isTrue);
    expect(user.getHost(), '500px');
    expect(user.getDomain(), '500px.com');

    final configs = <String, FivehundredpxConfig>{};
    for (final url in [
      'https://500px.com/tsyganov/stories/80675/galya',
      'https://500px.com/tsyganov/stories',
      'https://500px.com/tsyganov/favorites',
      'https://500px.com/tsyganov/galleries',
      'https://500px.com/getesmart86/galleries/olga',
      'https://500px.com/tsyganov',
    ]) {
      configs[url] = await FivehundredpxRipper.configureUrl(
        Uri.parse(url),
        userIdFetcher: fakeUserId,
      );
    }

    expect(configs['https://500px.com/tsyganov/stories/80675/galya']!.gid,
        'tsyganov_stories_80675');
    expect(
        configs['https://500px.com/tsyganov/stories']!.gid, 'tsyganov_stories');
    expect(
        configs['https://500px.com/tsyganov/favorites']!.gid, 'tsyganov_faves');
    expect(configs['https://500px.com/tsyganov/galleries']!.gid,
        'tsyganov_galleries');
    expect(configs['https://500px.com/getesmart86/galleries/olga']!.gid,
        'getesmart86_galleries_olga');
    expect(configs['https://500px.com/tsyganov']!.gid, 'tsyganov');

    expect(
      configs['https://500px.com/tsyganov']!.baseUrl,
      'https://api.500px.com/v1/photos?feature=user&username=tsyganov&rpp=100&image_size=5',
    );
  });

  test('extracts preload images and Java-style download filenames', () {
    expect(
      FivehundredpxRipper.preloadImageUrl(
        parse(
            '<div id="preload"><img src="https://drscdn.500px.org/full.jpg"></div>'),
      ),
      'https://drscdn.500px.org/full.jpg',
    );
    expect(FivehundredpxRipper.preloadImageUrl(parse('<main></main>')), isNull);
    expect(
      FivehundredpxRipper.downloadFileName(
        Uri.parse('https://drscdn.500px.org/photo/123456/m%3D2048/v2?sig=x'),
        9,
      ),
      '123456.jpg',
    );
  });
}
