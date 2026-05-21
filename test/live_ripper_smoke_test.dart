import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ripme/ripper/rippers/reddit_ripper.dart';
import 'package:ripme/ripper/rippers/redgifs_ripper.dart';
import 'package:ripme/utils/http_utils.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'download.retries': 1,
      'download.retry.sleep': 0,
      'page.timeout': 10000,
    });
    await Utils.init();
  });

  test(
    'live Reddit smoke: configured URL returns extractable media or self-posts',
    () async {
      final url = Uri.parse(Platform.environment['RIPME_LIVE_REDDIT_URL']!);
      final json = await Http.getJSON(RedditRipper.getJsonUrl(url));
      final media = await RedditRipper.extractMediaFromJson(json);
      final selfPosts = RedditRipper.extractSelfPostHtmlFromJson(json);

      expect(media.isNotEmpty || selfPosts.isNotEmpty, isTrue);
    },
    skip: Platform.environment['RIPME_LIVE_REDDIT_URL'] == null
        ? 'Set RIPME_LIVE_REDDIT_URL to enable this fragile-site smoke test.'
        : false,
  );

  test(
    'live Redgifs smoke: configured singleton URL resolves a video URL',
    () async {
      final url = Uri.parse(Platform.environment['RIPME_LIVE_REDGIFS_URL']!);
      final videoUrl = await RedgifsRipper.getVideoUrl(url);

      expect(videoUrl, isNotEmpty);
      expect(Uri.parse(videoUrl).scheme, isIn(['http', 'https']));
    },
    skip: Platform.environment['RIPME_LIVE_REDGIFS_URL'] == null
        ? 'Set RIPME_LIVE_REDGIFS_URL to enable this fragile-site smoke test.'
        : false,
  );
}
