import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ripme/utils/http_utils.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<HttpServer> _server(Future<void> Function(HttpRequest request) handler) {
  return HttpServer.bind(InternetAddress.loopbackIPv4, 0)
    ..then((server) {
      server.listen(handler);
    });
}

void main() {
  tearDown(() {
    Http.delay = Future.delayed;
  });

  test('detects Java image extensions from stream signatures', () {
    expect(Http.fileExtensionFromBytes([0xff, 0xd8, 0xff, 0xe0]), 'jpeg');
    expect(
      Http.fileExtensionFromBytes([0xff, 0xd8, 0xff, 0xdb, 0]),
      'jpeg',
    );
    expect(
      Http.fileExtensionFromBytes(
        [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a],
      ),
      'png',
    );
    expect(
      Http.fileExtensionFromBytes([0x47, 0x49, 0x46, 0x38, 0x39, 0x61]),
      'gif',
    );
    expect(
      Http.fileExtensionFromBytes([0x89, 0x50, 0x4e, 0x47, 0x0d]),
      'png',
    );
    expect(Http.fileExtensionFromBytes([0x49, 0x49, 0x2a, 0]), 'tiff');
    expect(Http.fileExtensionFromBytes([0xff, 0xd8, 0xff, 0xd9]), isNull);
    expect(Http.fileExtensionFromBytes([1, 2, 3, 4, 5]), isNull);
  });

  test('uses Java configured value as the total request attempt count',
      () async {
    SharedPreferences.setMockInitialValues({
      'download.retries': 2,
      'download.retry.sleep': 0,
      'page.timeout': 1000,
    });
    await Utils.init();

    var attempts = 0;
    final server = await _server((request) async {
      attempts++;
      if (attempts == 1) {
        request.response.statusCode = 500;
        await request.response.close();
        return;
      }
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({'ok': true}));
      await request.response.close();
    });
    addTearDown(server.close);

    final json =
        await Http.getJSON(Uri.parse('http://127.0.0.1:${server.port}/data'));

    expect(json['ok'], isTrue);
    expect(attempts, 2);
  });

  test('sends the exact Java AbstractRipper user agent', () async {
    SharedPreferences.setMockInitialValues({
      'download.retries': 1,
      'page.timeout': 1000,
    });
    await Utils.init();

    String? userAgent;
    final server = await _server((request) async {
      userAgent = request.headers.value('user-agent');
      request.response.write('<html></html>');
      await request.response.close();
    });
    addTearDown(server.close);

    await Http.get(Uri.parse('http://127.0.0.1:${server.port}/page'));

    const javaUserAgent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) '
        'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 '
        'Safari/537.36';
    expect(Http.userAgent, javaUserAgent);
    expect(userAgent, javaUserAgent);
  });

  test('does not enforce Java inactive download.max_size key', () async {
    SharedPreferences.setMockInitialValues({
      'download.max_size': 3,
      'download.retries': 1,
      'page.timeout': 1000,
    });
    await Utils.init();

    final server = await _server((request) async {
      request.response.write('large');
      await request.response.close();
    });
    addTearDown(server.close);

    final directory = await Directory.systemTemp.createTemp('ripme_http_test');
    addTearDown(() => directory.delete(recursive: true));

    final saveAs = File('${directory.path}/file.txt');
    await Http.downloadFile(
      Uri.parse('http://127.0.0.1:${server.port}/file'),
      saveAs,
    );

    expect(await saveAs.readAsString(), 'large');
  });

  test('uses download timeout for file downloads', () async {
    SharedPreferences.setMockInitialValues({
      'download.timeout': 1000,
      'page.timeout': 1,
      'download.retries': 1,
    });
    await Utils.init();

    final server = await _server((request) async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      request.response.write('ok');
      await request.response.close();
    });
    addTearDown(server.close);

    final directory = await Directory.systemTemp.createTemp('ripme_http_test');
    addTearDown(() => directory.delete(recursive: true));
    final saveAs = File('${directory.path}/file.txt');

    await Http.downloadFile(
      Uri.parse('http://127.0.0.1:${server.port}/file'),
      saveAs,
    );

    expect(await saveAs.readAsString(), 'ok');
  });

  test('interrupts a streamed file download between chunks', () async {
    SharedPreferences.setMockInitialValues({
      'download.timeout': 1000,
      'download.retries': 0,
      'download.retry.sleep': 0,
    });
    await Utils.init();

    final firstChunkSent = Completer<void>();
    final releaseSecondChunk = Completer<void>();
    final server = await _server((request) async {
      request.response.bufferOutput = false;
      request.response.add([1, 2, 3]);
      await request.response.flush();
      firstChunkSent.complete();
      await releaseSecondChunk.future;
      request.response.add([4, 5, 6]);
      await request.response.close();
    });
    addTearDown(server.close);

    final directory = await Directory.systemTemp.createTemp('ripme_http_test');
    addTearDown(() => directory.delete(recursive: true));
    final saveAs = File('${directory.path}/file.bin');
    var stopChecks = 0;

    final download = Http.downloadFile(
      Uri.parse('http://127.0.0.1:${server.port}/file'),
      saveAs,
      shouldStop: () {
        stopChecks++;
        return stopChecks >= 3;
      },
    );
    await firstChunkSent.future;
    releaseSecondChunk.complete();

    await expectLater(
      download,
      throwsA(isA<DownloadInterruptedException>()),
    );
    expect(await saveAs.readAsBytes(), [1, 2, 3]);
  });

  test('page requests enforce the configured page timeout', () async {
    SharedPreferences.setMockInitialValues({
      'page.timeout': 20,
      'download.timeout': 1000,
      'download.retries': 1,
      'download.retry.sleep': 0,
    });
    await Utils.init();

    var attempts = 0;
    final server = await _server((request) async {
      attempts++;
      await Future<void>.delayed(const Duration(milliseconds: 200));
      try {
        request.response.write('late');
        await request.response.close();
      } on HttpException {
        // The client is expected to close the socket when its timeout expires.
      }
    });
    addTearDown(server.close);

    await expectLater(
      Http.get(Uri.parse('http://127.0.0.1:${server.port}/slow-page')),
      throwsA(isA<TimeoutException>()),
    );
    expect(attempts, 1);
  });

  test('file downloads enforce the configured download timeout', () async {
    SharedPreferences.setMockInitialValues({
      'download.timeout': 20,
      'page.timeout': 1000,
      'download.retries': 1,
      'download.retry.sleep': 0,
    });
    await Utils.init();

    var attempts = 0;
    final server = await _server((request) async {
      attempts++;
      await Future<void>.delayed(const Duration(milliseconds: 200));
      try {
        request.response.write('late');
        await request.response.close();
      } on HttpException {
        // The client is expected to close the socket when its timeout expires.
      }
    });
    addTearDown(server.close);
    final directory = await Directory.systemTemp.createTemp('ripme_http_test');
    addTearDown(() => directory.delete(recursive: true));
    final saveAs = File('${directory.path}/file.txt');

    await expectLater(
      Http.downloadFile(
        Uri.parse('http://127.0.0.1:${server.port}/slow-file'),
        saveAs,
      ),
      throwsA(isA<TimeoutException>()),
    );
    expect(attempts, 1);
    expect(await saveAs.exists(), isFalse);
  });

  test('sends custom headers and cookies on downloads', () async {
    SharedPreferences.setMockInitialValues({
      'download.retries': 1,
      'download.timeout': 1000,
    });
    await Utils.init();

    late String? referer;
    late String? cookie;
    final server = await _server((request) async {
      referer = request.headers.value('referer');
      cookie = request.headers.value('cookie');
      request.response.write('ok');
      await request.response.close();
    });
    addTearDown(server.close);

    final directory = await Directory.systemTemp.createTemp('ripme_http_test');
    addTearDown(() => directory.delete(recursive: true));

    await Http.downloadFile(
      Uri.parse('http://127.0.0.1:${server.port}/file'),
      File('${directory.path}/file.txt'),
      headers: {'Referer': 'https://example.com/page'},
      cookies: {'session': 'abc', 'pref': 'dark'},
    );

    expect(referer, 'https://example.com/page');
    expect(cookie, contains('session=abc'));
    expect(cookie, contains('pref=dark'));
  });

  test('download headers match Java defaults and exclude configured cookies',
      () async {
    SharedPreferences.setMockInitialValues({
      'download.retries': 1,
      'download.timeout': 1000,
      'cookies.127.0.0.1': 'configured=ignored',
    });
    await Utils.init();

    late String? accept;
    late String? cookie;
    final server = await _server((request) async {
      accept = request.headers.value('accept');
      cookie = request.headers.value('cookie');
      request.response.write('ok');
      await request.response.close();
    });
    addTearDown(server.close);

    final directory = await Directory.systemTemp.createTemp('ripme_http_test');
    addTearDown(() => directory.delete(recursive: true));
    await Http.downloadFile(
      Uri.parse('http://127.0.0.1:${server.port}/file'),
      File('${directory.path}/file.txt'),
    );

    expect(accept, '*/*');
    expect(cookie, '');
  });

  test('adds configured domain cookies to requests', () async {
    SharedPreferences.setMockInitialValues({
      'download.retries': 1,
      'page.timeout': 1000,
      'cookies.127.0.0.1': 'session=abc; pref=dark',
    });
    await Utils.init();

    late String? cookie;
    final server = await _server((request) async {
      cookie = request.headers.value('cookie');
      request.response.write('<html></html>');
      await request.response.close();
    });
    addTearDown(server.close);

    await Http.get(Uri.parse('http://127.0.0.1:${server.port}/page'));

    expect(cookie, contains('session=abc'));
    expect(cookie, contains('pref=dark'));
  });

  test('configured cookies use Java parent lookup and parser edge cases',
      () async {
    SharedPreferences.setMockInitialValues({
      'cookies.www.example.com': '',
      'cookies.example.com': ' token=abc==; spaced= value ;',
      'cookies.com': 'ignored=tld',
    });
    await Utils.init();

    expect(
      Http.configuredCookiesForUrl(
        Uri.parse('https://www.example.com/gallery'),
      ),
      {
        'token': 'abc',
        'spaced': ' value ',
      },
    );
  });

  test('configured cookie parser fails on malformed Java pairs', () async {
    SharedPreferences.setMockInitialValues({
      'cookies.example.com': 'session=abc; malformed',
    });
    await Utils.init();

    expect(
      () => Http.configuredCookiesForUrl(Uri.parse('https://example.com')),
      throwsRangeError,
    );
  });

  test('semicolon cookie parser matches Java RipUtils split behavior', () {
    expect(
      Http.cookiesFromString(' first=one;second=two=ignored; third= spaced '),
      {
        'first': 'one',
        'second': 'two',
        'third': ' spaced ',
      },
    );
    expect(
      () => Http.cookiesFromString('valid=one; malformed'),
      throwsRangeError,
    );
    expect(() => Http.cookiesFromString('empty='), throwsRangeError);
  });

  test('routes requests through configured HTTP proxy', () async {
    SharedPreferences.setMockInitialValues({
      'download.retries': 1,
      'page.timeout': 1000,
      'proxy.enabled': true,
    });
    await Utils.init();

    late Uri proxyRequestUri;
    final proxy = await _server((request) async {
      proxyRequestUri = request.uri;
      request.response.write('<html></html>');
      await request.response.close();
    });
    addTearDown(proxy.close);

    await Utils.setConfigString('proxy.host', '127.0.0.1');
    await Utils.setConfigInteger('proxy.port', proxy.port);

    await Http.get(Uri.parse('http://example.invalid/proxied'));

    expect(proxyRequestUri.toString(), 'http://example.invalid/proxied');
  });

  test('uses Java proxy.http config with credentials and key precedence',
      () async {
    SharedPreferences.setMockInitialValues({
      'proxy.http': 'user:secret@proxy.example:3128',
      'proxy.socks': 'socks.example:1080',
      'proxy.enabled': false,
    });
    await Utils.init();
    final client = _RecordingHttpClient();

    Http.configureProxy(client);

    expect(
      client.recordedFindProxy?.call(Uri.parse('https://example.com')),
      'PROXY proxy.example:3128',
    );
    expect(client.proxyCredentialHost, 'proxy.example');
    expect(client.proxyCredentialPort, 3128);
    expect(client.proxyCredentialRealm, '');
    expect(client.proxyCredentials, isA<HttpClientBasicCredentials>());
  });

  test('rejects configured Java SOCKS proxy explicitly', () async {
    SharedPreferences.setMockInitialValues({
      'proxy.socks': 'user:secret@socks.example:1080',
    });
    await Utils.init();

    expect(
      () => Http.configureProxy(_RecordingHttpClient()),
      throwsA(
        isA<UnsupportedError>().having(
          (error) => error.message,
          'message',
          contains('SOCKS proxy is not supported'),
        ),
      ),
    );
  });

  test('disables certificate verification only when Java setting is enabled',
      () async {
    SharedPreferences.setMockInitialValues({'ssl.verify.off': false});
    await Utils.init();
    final verifiedClient = _RecordingHttpClient();

    Http.configureCertificateVerification(verifiedClient);

    expect(verifiedClient.recordedBadCertificateCallback, isNull);

    await Utils.setConfigBoolean('ssl.verify.off', true);
    final unverifiedClient = _RecordingHttpClient();

    Http.configureCertificateVerification(unverifiedClient);

    expect(unverifiedClient.recordedBadCertificateCallback, isNotNull);
  });

  test('ignores retry-after and uses Java configured retry sleep', () async {
    SharedPreferences.setMockInitialValues({
      'download.retries': 2,
      'download.retry.sleep': 25,
      'page.timeout': 1000,
    });
    await Utils.init();

    final delays = <Duration>[];
    Http.delay = (duration) async {
      delays.add(duration);
    };

    var attempts = 0;
    final server = await _server((request) async {
      attempts++;
      if (attempts == 1) {
        request.response.statusCode = 429;
        request.response.headers.set('Retry-After', '3');
      } else {
        request.response.write(jsonEncode({'ok': true}));
      }
      await request.response.close();
    });
    addTearDown(server.close);

    final json =
        await Http.getJSON(Uri.parse('http://127.0.0.1:${server.port}/data'));

    expect(json['ok'], isTrue);
    expect(attempts, 2);
    expect(delays, [const Duration(milliseconds: 25)]);
  });

  test('page retries use Java 5000 ms fallback when the key is absent',
      () async {
    SharedPreferences.setMockInitialValues({
      'download.retries': 2,
      'page.timeout': 1000,
    });
    await Utils.init();
    final delays = <Duration>[];
    Http.delay = (duration) async {
      delays.add(duration);
    };

    var attempts = 0;
    final server = await _server((request) async {
      attempts++;
      if (attempts == 1) {
        request.response.statusCode = 500;
      } else {
        request.response.write('ok');
      }
      await request.response.close();
    });
    addTearDown(server.close);

    final response =
        await Http.get(Uri.parse('http://127.0.0.1:${server.port}/page'));

    expect(response.body?.text, 'ok');
    expect(delays, [const Duration(milliseconds: 5000)]);
  });

  test('file retries use Java zero-delay fallback when the key is absent',
      () async {
    SharedPreferences.setMockInitialValues({
      'download.retries': 1,
      'download.timeout': 1000,
    });
    await Utils.init();
    final delays = <Duration>[];
    Http.delay = (duration) async {
      delays.add(duration);
    };

    var attempts = 0;
    final server = await _server((request) async {
      attempts++;
      if (attempts == 1) {
        request.response.statusCode = 500;
      } else {
        request.response.add([1, 2, 3]);
      }
      await request.response.close();
    });
    addTearDown(server.close);
    final directory =
        await Directory.systemTemp.createTemp('ripme_retry_default_test');
    addTearDown(() => directory.delete(recursive: true));

    await Http.downloadFile(
      Uri.parse('http://127.0.0.1:${server.port}/file'),
      File('${directory.path}/file.bin'),
    );

    expect(attempts, 2);
    expect(delays, isEmpty);
  });

  test('waits after every failed Java attempt including the final one',
      () async {
    SharedPreferences.setMockInitialValues({
      'download.retries': 2,
      'download.retry.sleep': 25,
      'page.timeout': 1000,
    });
    await Utils.init();

    final delays = <Duration>[];
    Http.delay = (duration) async {
      delays.add(duration);
    };

    final server = await _server((request) async {
      request.response.statusCode = 500;
      await request.response.close();
    });
    addTearDown(server.close);

    await expectLater(
      Http.get(Uri.parse('http://127.0.0.1:${server.port}/failure')),
      throwsA(isA<HttpException>()),
    );
    expect(delays, [
      const Duration(milliseconds: 25),
      const Duration(milliseconds: 25),
    ]);
  });

  test('parses JSON and HTML without relying on content type', () async {
    SharedPreferences.setMockInitialValues({
      'download.retries': 1,
      'page.timeout': 1000,
    });
    await Utils.init();

    final server = await _server((request) async {
      request.response.headers.contentType = ContentType.text;
      if (request.uri.path == '/json') {
        request.response.write(jsonEncode({'ok': true}));
      } else {
        request.response.write('<html><body><h1>ok</h1></body></html>');
      }
      await request.response.close();
    });
    addTearDown(server.close);

    final json =
        await Http.getJSON(Uri.parse('http://127.0.0.1:${server.port}/json'));
    final html =
        await Http.get(Uri.parse('http://127.0.0.1:${server.port}/html'));

    expect(json['ok'], isTrue);
    expect(html.querySelector('h1')?.text, 'ok');
  });

  test('stores the final response URL as the Java document location', () async {
    SharedPreferences.setMockInitialValues({
      'download.retries': 1,
      'page.timeout': 1000,
    });
    await Utils.init();

    final server = await _server((request) async {
      if (request.uri.path == '/redirect') {
        request.response
          ..statusCode = HttpStatus.found
          ..headers.set(HttpHeaders.locationHeader, '/final');
      } else {
        request.response.write('<html><body>final</body></html>');
      }
      await request.response.close();
    });
    addTearDown(server.close);

    final document = await Http.get(
      Uri.parse('http://127.0.0.1:${server.port}/redirect'),
    );

    expect(
      Http.documentLocation(document),
      Uri.parse('http://127.0.0.1:${server.port}/final'),
    );
  });

  test('Java-style request builder applies headers cookies and form data',
      () async {
    SharedPreferences.setMockInitialValues({
      'download.retries': 1,
      'page.timeout': 1000,
    });
    await Utils.init();

    late String method;
    late String? referer;
    late String? userAgent;
    late String? customHeader;
    late String? cookie;
    late String body;
    final server = await _server((request) async {
      method = request.method;
      referer = request.headers.value('referer');
      userAgent = request.headers.value('user-agent');
      customHeader = request.headers.value('x-test');
      cookie = request.headers.value('cookie');
      body = await utf8.decoder.bind(request).join();
      request.response.write('<html><body>posted</body></html>');
      await request.response.close();
    });
    addTearDown(server.close);

    final document = await Http.url(
      'http://127.0.0.1:${server.port}/form',
    )
        .ignoreContentType()
        .referrer('https://example.com/source')
        .userAgent('custom-agent')
        .header('X-Test', 'value')
        .cookies({'session': 'abc'})
        .data({'first': 'one'})
        .data('second', 'two')
        .method('GET')
        .post();

    expect(method, 'POST');
    expect(referer, 'https://example.com/source');
    expect(userAgent, 'custom-agent');
    expect(customHeader, 'value');
    expect(cookie, 'session=abc');
    expect(Uri.splitQueryString(body), {
      'first': 'one',
      'second': 'two',
    });
    expect(document.body?.text, 'posted');
  });

  test('Java-style request builder supports JSON objects and arrays', () async {
    SharedPreferences.setMockInitialValues({
      'download.retries': 1,
      'page.timeout': 1000,
    });
    await Utils.init();

    final server = await _server((request) async {
      request.response.headers.contentType = ContentType.text;
      request.response.write(
        request.uri.path == '/object' ? '{"ok":true}' : '[1,2,3]',
      );
      await request.response.close();
    });
    addTearDown(server.close);

    final object = await Http.url(
      'http://127.0.0.1:${server.port}/object',
    ).getJSON();
    final array = await Http.url(
      'http://127.0.0.1:${server.port}/array',
    ).getJSONArray();

    expect(object, {'ok': true});
    expect(array, [1, 2, 3]);
  });

  test('Java-style request builder honors retry and timeout overrides',
      () async {
    SharedPreferences.setMockInitialValues({
      'download.retries': 1,
      'page.timeout': 1000,
      'download.retry.sleep': 0,
    });
    await Utils.init();

    var attempts = 0;
    final server = await _server((request) async {
      attempts++;
      request.response.statusCode = 500;
      await request.response.close();
    });
    addTearDown(server.close);

    await expectLater(
      Http.url('http://127.0.0.1:${server.port}/retry')
          .retries(2)
          .timeout(100)
          .response(),
      throwsA(isA<HttpException>()),
    );
    expect(attempts, 2);
  });

  test('page requests never retry Java 404 responses', () async {
    SharedPreferences.setMockInitialValues({
      'download.retries': 2,
      'page.timeout': 1000,
      'errors.skip404': false,
      'error.skip404': false,
    });
    await Utils.init();

    var attempts = 0;
    final server = await _server((request) async {
      attempts++;
      request.response.statusCode = 404;
      request.response.write('<html></html>');
      await request.response.close();
    });
    addTearDown(server.close);

    final url = Uri.parse('http://127.0.0.1:${server.port}/missing');
    await expectLater(
      Http.get(url),
      throwsA(
        isA<HttpException>().having(
          (error) => error.message,
          'message',
          'File not found $url: Status Code 404. ',
        ),
      ),
    );
    expect(attempts, 1);
  });

  for (final status in [401, 403]) {
    test('page status $status stops with Java cookie guidance', () async {
      SharedPreferences.setMockInitialValues({
        'download.retries': 3,
        'download.retry.sleep': 25,
        'page.timeout': 1000,
      });
      await Utils.init();
      final delays = <Duration>[];
      Http.delay = (duration) async {
        delays.add(duration);
      };

      var attempts = 0;
      final server = await _server((request) async {
        attempts++;
        request.response.statusCode = status;
        await request.response.close();
      });
      addTearDown(server.close);
      final url = Uri.parse('http://127.0.0.1:${server.port}/restricted');

      await expectLater(
        Http.get(url),
        throwsA(
          isA<HttpException>().having(
            (error) => error.message,
            'message',
            'Failed to load $url: Status Code $status. You might be able to '
                'circumvent this error by setting cookies for this domain',
          ),
        ),
      );
      expect(attempts, 1);
      expect(delays, isEmpty);
    });
  }

  test('download 404 is non-retriable before Java skip key branch', () async {
    SharedPreferences.setMockInitialValues({
      'download.retries': 2,
      'download.retry.sleep': 0,
      'download.timeout': 1000,
      'errors.skip404': false,
      'error.skip404': true,
    });
    await Utils.init();

    var attempts = 0;
    final server = await _server((request) async {
      attempts++;
      request.response.statusCode = 404;
      await request.response.close();
    });
    addTearDown(server.close);
    final directory = await Directory.systemTemp.createTemp('ripme_http_test');
    addTearDown(() => directory.delete(recursive: true));

    await expectLater(
      Http.downloadFile(
        Uri.parse('http://127.0.0.1:${server.port}/missing'),
        File('${directory.path}/missing.jpg'),
      ),
      throwsA(
        isA<HttpException>().having(
          (error) => error.message,
          'message',
          'Non-retriable status code 404 while downloading '
              'http://127.0.0.1:${server.port}/missing',
        ),
      ),
    );
    expect(attempts, 1);

    await Utils.setConfigBoolean('errors.skip404', true);
    attempts = 0;

    await expectLater(
      Http.downloadFile(
        Uri.parse('http://127.0.0.1:${server.port}/missing'),
        File('${directory.path}/missing.jpg'),
      ),
      throwsA(isA<HttpException>()),
    );
    expect(attempts, 1);
  });

  test('download 5xx uses Java initial attempt plus configured retries',
      () async {
    SharedPreferences.setMockInitialValues({
      'download.retries': 2,
      'download.retry.sleep': 0,
      'download.timeout': 1000,
    });
    await Utils.init();

    var attempts = 0;
    final server = await _server((request) async {
      attempts++;
      request.response.statusCode = 503;
      await request.response.close();
    });
    addTearDown(server.close);
    final directory = await Directory.systemTemp.createTemp('ripme_http_test');
    addTearDown(() => directory.delete(recursive: true));
    final url = Uri.parse('http://127.0.0.1:${server.port}/unavailable');

    await expectLater(
      Http.downloadFile(url, File('${directory.path}/file.jpg')),
      throwsA(
        isA<HttpException>().having(
          (error) => error.message,
          'message',
          'Retriable status code 503 while downloading $url',
        ),
      ),
    );
    expect(attempts, 3);
  });

  test('performs no request when Java attempt count is zero', () async {
    SharedPreferences.setMockInitialValues({
      'download.retries': 0,
      'page.timeout': 1000,
    });
    await Utils.init();

    var attempts = 0;
    final server = await _server((request) async {
      attempts++;
      request.response.write('<html></html>');
      await request.response.close();
    });
    addTearDown(server.close);

    await expectLater(
      Http.get(Uri.parse('http://127.0.0.1:${server.port}/unused')),
      throwsA(isA<HttpException>()),
    );
    expect(attempts, 0);
  });
}

class _RecordingHttpClient implements HttpClient {
  bool Function(X509Certificate certificate, String host, int port)?
      recordedBadCertificateCallback;
  String Function(Uri url)? recordedFindProxy;
  String? proxyCredentialHost;
  int? proxyCredentialPort;
  String? proxyCredentialRealm;
  HttpClientCredentials? proxyCredentials;

  @override
  set badCertificateCallback(
    bool Function(X509Certificate certificate, String host, int port)? callback,
  ) {
    recordedBadCertificateCallback = callback;
  }

  @override
  set findProxy(String Function(Uri url)? callback) {
    recordedFindProxy = callback;
  }

  @override
  void addProxyCredentials(
    String host,
    int port,
    String realm,
    HttpClientCredentials credentials,
  ) {
    proxyCredentialHost = host;
    proxyCredentialPort = port;
    proxyCredentialRealm = realm;
    proxyCredentials = credentials;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
