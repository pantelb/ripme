import 'package:flutter_test/flutter_test.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('uses Java rip.properties defaults when preferences are unset',
      () async {
    SharedPreferences.setMockInitialValues({});
    await Utils.init();

    expect(Utils.getConfigInteger('threads.size', 10), 5);
    expect(Utils.getConfigInteger('download.retries', 0), 3);
    expect(Utils.getConfigInteger('download.retry.sleep', 5000), 0);
    expect(Utils.getConfigBoolean('file.overwrite', true), isFalse);
    expect(Utils.getConfigBoolean('download.save_order', false), isTrue);
    expect(Utils.getConfigBoolean('album_titles.save', false), isTrue);
    expect(Utils.getConfigBoolean('remember.url_history', false), isTrue);
    expect(Utils.getConfigBoolean('urls_only.save', true), isFalse);
    expect(Utils.getConfigString('twitter.auth', null), isNotEmpty);
    expect(Utils.getConfigString('tumblr.auth', null), isNotEmpty);
  });

  test('stored preferences override default config values', () async {
    SharedPreferences.setMockInitialValues({
      'threads.size': 2,
      'download.save_order': false,
    });
    await Utils.init();

    expect(Utils.getConfigInteger('threads.size', 10), 2);
    expect(Utils.getConfigBoolean('download.save_order', true), isFalse);
  });
}
