import 'package:flutter_test/flutter_test.dart';
import 'package:ripme/utils/proxy_config.dart';

void main() {
  test('parses Java host and optional port forms', () {
    final hostOnly = ProxyConfig.parseJavaServer('proxy.example');
    final withPort = ProxyConfig.parseJavaServer('proxy.example:3128');

    expect(hostOnly.server, 'proxy.example');
    expect(hostOnly.port, isNull);
    expect(withPort.server, 'proxy.example');
    expect(withPort.port, 3128);
  });

  test('uses the last at sign and Java credential splitting', () {
    final config = ProxyConfig.parseJavaServer(
      'user:password:ignored@proxy.example:8080',
    );

    expect(config.user, 'user');
    expect(config.password, 'password');
    expect(config.server, 'proxy.example');
    expect(config.port, 8080);
  });

  test('rejects malformed Java proxy credentials and ports', () {
    expect(
      () => ProxyConfig.parseJavaServer('user@proxy.example'),
      throwsFormatException,
    );
    expect(
      () => ProxyConfig.parseJavaServer('proxy.example:not-a-port'),
      throwsFormatException,
    );
  });
}
