import 'package:flutter_test/flutter_test.dart';
import 'package:ripme/ripper/rippers/danbooru_ripper.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('matches Java host, domain, tags, and GIDs', () async {
    final first =
        Uri.parse('https://danbooru.donmai.us/posts?tags=brown_necktie');
    final second = Uri.parse(
      'https://danbooru.donmai.us/posts?page=1&tags=pink_sweater_vest',
    );
    final withZ =
        Uri.parse('https://danbooru.donmai.us/posts?tags=cat_ears&z=123');

    final ripper = DanbooruRipper(first);
    final secondRipper = DanbooruRipper(second);

    expect(ripper.canRip(first), isTrue);
    expect(ripper.getHost(), 'danbooru');
    expect(ripper.getDomain(), 'danbooru.donmai.us');
    expect(DanbooruRipper.getTag(first), 'brown_necktie');
    expect(DanbooruRipper.getTag(second), 'pink_sweater_vest');
    expect(DanbooruRipper.getTag(withZ), 'cat_ears');
    expect(await ripper.getGID(first), 'brown_necktie');
    expect(await secondRipper.getGID(second), 'pink_sweater_vest');
  });

  test('constructs Java-compatible posts.json page URLs', () {
    final ripper = DanbooruRipper(
      Uri.parse('https://danbooru.donmai.us/posts?tags=brown_necktie'),
    );

    expect(
      ripper.getPage(1).toString(),
      'https://danbooru.donmai.us/posts.json?page=1&tags=brown_necktie',
    );
    expect(
      ripper.getPage(2).toString(),
      'https://danbooru.donmai.us/posts.json?page=2&tags=brown_necktie',
    );
  });

  test('extracts file_url resources like Java', () {
    expect(
      DanbooruRipper.urlsFromJson({
        'resources': [
          {'file_url': 'https://cdn.example.com/one.jpg'},
          {'source': 'https://example.com/page'},
          {'file_url': 'https://cdn.example.com/two.png?token=1'},
        ],
      }),
      [
        'https://cdn.example.com/one.jpg',
        'https://cdn.example.com/two.png?token=1',
      ],
    );
  });

  test('uses Java-style ordered filename prefixes', () async {
    SharedPreferences.setMockInitialValues({
      'remember.url_history': false,
      'download.save_order': true,
    });
    await Utils.init();

    expect(
      DanbooruRipper.downloadFileName(
        Uri.parse('https://cdn.example.com/path/file.jpg?token=1'),
        12,
      ),
      '012_file.jpg',
    );

    SharedPreferences.setMockInitialValues({
      'remember.url_history': false,
      'download.save_order': false,
    });
    await Utils.init();

    expect(
      DanbooruRipper.downloadFileName(
        Uri.parse('https://cdn.example.com/path/file.jpg'),
        12,
      ),
      'file.jpg',
    );
  });
}
