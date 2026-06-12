import 'package:flutter_test/flutter_test.dart';
import 'package:ripme/config_key_inventory.dart';

void main() {
  test('extracts literal, constant, dynamic, and required Java config keys',
      () {
    const source = '''
      private static final String AUTH_CONFIG_KEY = "tumblr.auth";
      private final String ignored = "not.a.config.key";

      Utils.getConfigString("proxy.http", null);
      Utils.setConfigBoolean("download.save_order", true);
      Utils.getConfigString("cookies." + domain, "");
      Utils.getConfigString(AUTH_CONFIG_KEY, "");
      config.containsKey("download.max_size");
    ''';

    expect(
      JavaConfigKeyInventory.keysFromSources([source]),
      {
        'proxy.http',
        'download.save_order',
        'cookies.*',
        'tumblr.auth',
        'download.max_size',
      },
    );
  });

  test('extracts active Java property defaults only', () {
    const properties = '''
      # ignored.key = value
      threads.size = 5

      file.overwrite=false
    ''';

    expect(
      JavaConfigKeyInventory.keysFromProperties(properties),
      {'threads.size', 'file.overwrite'},
    );
  });
}
