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

  test('maps every Flutter-only compatibility key to Java behavior', () {
    expect(
      ConfigParity.flutterOnlyReplacementKeys,
      {
        'history.skip_downloaded_urls':
            'Legacy Flutter fallback for Java remember.url_history',
        'proxy.enabled': 'Structured Flutter UI for Java proxy.http',
        'proxy.host': 'Structured Flutter UI for Java proxy.http',
        'proxy.port': 'Structured Flutter UI for Java proxy.http',
        'proxy.username': 'Structured Flutter UI for Java proxy.http',
        'proxy.password': 'Structured Flutter UI for Java proxy.http',
      },
    );
    expect(
      ConfigParity.flutterOnlyReplacementKeys.keys
          .toSet()
          .intersection(ConfigDefaults.javaRuntimeKeys),
      isEmpty,
    );
  });
}
