import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' show parse;
import 'package:ripme/ripper/rippers/dribbble_ripper.dart';
import 'package:ripme/utils/http_utils.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('matches Java host, domain, URL support, and GIDs', () async {
    final ripper = DribbbleRipper(Uri.parse('https://dribbble.com/typogriff'));

    expect(ripper.canRip(ripper.url), isTrue);
    expect(
      ripper.canRip(Uri.parse('https://www.dribbble.com/typogriff')),
      isTrue,
    );
    expect(ripper.getHost(), 'dribbble');
    expect(ripper.getDomain(), 'dribbble.com');
    expect(await ripper.getGID(ripper.url), 'typogriff');
    expect(
      await ripper.getGID(Uri.parse('https://www.dribbble.com/abc123/shots')),
      'abc123',
    );
  });

  test('selects the largest srcset URL like Java', () {
    expect(
      DribbbleRipper.largestImageUrl(
        'https://cdn.example/small.jpg 400w, https://cdn.example/large.jpg 1200w, malformed',
      ),
      'https://cdn.example/large.jpg',
    );
    expect(
      DribbbleRipper.largestImageUrl(
        'https://cdn.example/no-width.jpg, https://cdn.example/not-int.jpg nope',
      ),
      isNull,
    );
  });

  test('extracts thumbnail images from Java selector', () {
    final page = parse('''
      <div class="shot-thumbnail-base">
        <figure>
          <img data-srcset="https://cdn.example/one.jpg 400w, https://cdn.example/one2x.jpg 800w">
        </figure>
      </div>
      <figure><img data-srcset="https://ignored.example/two.jpg 800w"></figure>
    ''');

    expect(
      DribbbleRipper.urlsFromPage(page),
      ['https://cdn.example/one2x.jpg'],
    );
  });

  test('constructs next page URLs with Java host and delay', () async {
    final originalDelay = Http.delay;
    final delays = <Duration>[];
    Http.delay = (duration) async {
      delays.add(duration);
    };
    addTearDown(() {
      Http.delay = originalDelay;
    });

    final ripper = DribbbleRipper(Uri.parse('https://dribbble.com/typogriff'));
    final page =
        parse('<a class="next_page" href="/typogriff?page=2">Next</a>');

    expect(
      (await ripper.getNextPage(page)).toString(),
      'https://www.dribbble.com/typogriff?page=2',
    );
    expect(delays, [const Duration(milliseconds: 500)]);
    expect(await ripper.getNextPage(parse('<main></main>')), isNull);
  });

  test('uses Java-style ordered filename prefixes', () async {
    SharedPreferences.setMockInitialValues({
      'remember.url_history': false,
      'download.save_order': true,
    });
    await Utils.init();

    expect(
      DribbbleRipper.downloadFileName(
        Uri.parse('https://cdn.example/path/file.jpg?token=1'),
        8,
      ),
      '008_file.jpg',
    );

    SharedPreferences.setMockInitialValues({
      'remember.url_history': false,
      'download.save_order': false,
    });
    await Utils.init();

    expect(
      DribbbleRipper.downloadFileName(
        Uri.parse('https://cdn.example/path/file.jpg'),
        8,
      ),
      'file.jpg',
    );
  });
}
