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
  test('retries failed JSON requests', () async {
    SharedPreferences.setMockInitialValues({
      'download.retries': 1,
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

  test('enforces max download size', () async {
    SharedPreferences.setMockInitialValues({
      'download.max_size': 3,
      'download.retries': 0,
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

    expect(
      () => Http.downloadFile(
        Uri.parse('http://127.0.0.1:${server.port}/file'),
        File('${directory.path}/file.txt'),
      ),
      throwsA(isA<HttpException>()),
    );
  });

  test('uses download timeout for file downloads', () async {
    SharedPreferences.setMockInitialValues({
      'download.timeout': 1000,
      'page.timeout': 1,
      'download.retries': 0,
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
}
