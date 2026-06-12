import 'package:flutter_test/flutter_test.dart';
import 'package:ripme/config_defaults.dart';
import 'package:ripme/config_parity.dart';

void main() {
  test('classifies every Java configuration key exactly once', () {
    expect(
      ConfigParity.separatelyTrackedControlKeys.intersection(
        ConfigParity.hiddenKeyDispositions.keys.toSet(),
      ),
      isEmpty,
    );
    expect(ConfigParity.missingJavaKeys, isEmpty);
    expect(ConfigParity.unknownJavaKeys, isEmpty);
    expect(ConfigParity.coveredJavaKeys, ConfigDefaults.javaRuntimeKeys);
  });

  test('records source-backed hidden key exceptions explicitly', () {
    expect(
      ConfigParity.hiddenKeyDispositions['download.max_size'],
      HiddenConfigDisposition.sentinelOnly,
    );
    expect(
      ConfigParity.hiddenKeyDispositions['gw.api'],
      HiddenConfigDisposition.sentinelOnly,
    );
    expect(
      ConfigParity.hiddenKeyDispositions['error.skip404'],
      HiddenConfigDisposition.migrationAlias,
    );
    expect(
      ConfigParity.hiddenKeyDispositions['proxy.socks'],
      HiddenConfigDisposition.explicitlyUnsupported,
    );
    expect(
      ConfigParity.hiddenKeyDispositions['DeviantartLogin.cookies'],
      HiddenConfigDisposition.retired,
    );
  });
}
