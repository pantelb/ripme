import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' show parse;
import 'package:ripme/ripper/rippers/fapwiz_ripper.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('matches Java host, domain, URL support, and GIDs', () async {
    final category =
        FapwizRipper(Uri.parse('https://fapwiz.com/category/asian/'));
    final user =
        FapwizRipper(Uri.parse('https://fapwiz.com/desperate_bug_7776/'));
    final post = FapwizRipper(Uri.parse(
        'https://fapwiz.com/petiteasiantravels/riding-at-9-months-pregnant/'));
    final emoji = FapwizRipper(Uri.parse(
        'https://fapwiz.com/miaipanema/my-grip-needs-a-name-%f0%9f%a4%ad%f0%9f%91%87%f0%9f%8f%bc/'));

    expect(post.canRip(post.url), isTrue);
    expect(category.getHost(), 'fapwiz');
    expect(category.getDomain(), 'fapwiz.com');
    expect(await category.getGID(category.url), 'category_asian');
    expect(await user.getGID(user.url), 'user_desperate_bug_7776');
    expect(
      await post.getGID(post.url),
      'post_petiteasiantravels_riding-at-9-months-pregnant',
    );
    expect(
      await emoji.getGID(emoji.url),
      'post_miaipanema_my-grip-needs-a-name-%f0%9f%a4%ad%f0%9f%91%87%f0%9f%8f%bc',
    );
    expect(
      Utils.filesystemSafe('fapwiz_${await emoji.getGID(emoji.url)}'),
      'fapwiz_post_miaipanema_my-grip-needs-a-name-f09fa4adf09f9187f09f8fbc',
    );
  });

  test('extracts user/category thumbnails as mp4 URLs and skips icons', () {
    final page = parse('''
      <div class="post-items-holder">
        <img src="https://cdn.fapwiz.com/user-thumbnail-icon.jpg">
        <img src="https://cdn.fapwiz.com/one-thumbnail.jpg">
        <img src="https://cdn.fapwiz.com/two.jpg">
      </div>
      <video><source src="https://cdn.fapwiz.com/post-video.mp4"></video>
    ''');

    expect(
      FapwizRipper.mediaFromPage(
        Uri.parse('https://fapwiz.com/desperate_bug_7776/'),
        page,
      ),
      [
        'https://cdn.fapwiz.com/one.mp4',
        'https://cdn.fapwiz.com/two.jpg',
      ],
    );
  });

  test('category pages also process post video sources like Java', () {
    final page = parse('''
      <div class="post-items-holder">
        <img src="https://cdn.fapwiz.com/one-thumbnail.jpg">
      </div>
      <video><source src="https://cdn.fapwiz.com/category-video.mp4"></video>
    ''');

    expect(
      FapwizRipper.mediaFromPage(
        Uri.parse('https://fapwiz.com/category/asian/'),
        page,
      ),
      [
        'https://cdn.fapwiz.com/one.mp4',
        'https://cdn.fapwiz.com/category-video.mp4',
      ],
    );
  });

  test('post pages extract video sources and next page links', () async {
    final ripper = FapwizRipper(Uri.parse(
        'https://fapwiz.com/petiteasiantravels/riding-at-9-months-pregnant/'));
    final page = parse('''
      <video>
        <source src="https://cdn.fapwiz.com/video-1.mp4">
        <source src="https://cdn.fapwiz.com/video-2.mp4">
      </video>
      <a class="next" href="https://fapwiz.com/user/page/2/">next</a>
    ''');

    expect(FapwizRipper.mediaFromPage(ripper.url, page), [
      'https://cdn.fapwiz.com/video-1.mp4',
      'https://cdn.fapwiz.com/video-2.mp4',
    ]);
    expect(
      (await ripper.getNextPage(page)).toString(),
      'https://fapwiz.com/user/page/2/',
    );
    expect(await ripper.getNextPage(parse('<main></main>')), isNull);
  });

  test('uses Java-style ordered filenames', () async {
    SharedPreferences.setMockInitialValues({'download.save_order': true});
    await Utils.init();
    expect(
      FapwizRipper.fileNameForUrl(
        Uri.parse('https://cdn.fapwiz.com/path/video.mp4?download=1'),
        4,
      ),
      '004_video.mp4',
    );

    SharedPreferences.setMockInitialValues({'download.save_order': false});
    await Utils.init();
    expect(
      FapwizRipper.fileNameForUrl(
        Uri.parse('https://cdn.fapwiz.com/path/video.mp4'),
        4,
      ),
      'video.mp4',
    );
  });
}
