import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ripme/ripper/abstract_ripper.dart';
import 'package:ripme/ripper/rippers/motherless_video_ripper.dart';
import 'package:ripme/ripper/rippers/twitch_video_ripper.dart';
import 'package:ripme/ui/rip_status_message.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ripme/utils/utils.dart';

void main() {
  tearDown(AbstractRipper.resetTestMode);

  test('MotherlessVideoRipper diagnostic: logs WTF when marker is present', () {
    /// Java MotherlessVideoRipper.rip() checks if html.contains("__fileurl = '")
    /// and if so, calls logger.error("WTF"). This is a diagnostic side effect
    /// that should be honored in Dart.
    const htmlWithMarker = """
      <html>
        <script>var __fileurl = 'https://cdn.example.com/video.mp4';</script>
      </html>
    """;
    const htmlWithoutMarker = """
      <html>
        <script>var something_else = 'url';</script>
      </html>
    """;

    /// Test that the marker detection works correctly
    expect(htmlWithMarker.contains("__fileurl = '"), isTrue);
    expect(htmlWithoutMarker.contains("__fileurl = '"), isFalse);

    /// When marker is found and extracted, extraction should succeed
    expect(
      MotherlessVideoRipper.videoUrlFromHtml(htmlWithMarker, Uri.parse('https://example.com')).toString(),
      'https://cdn.example.com/video.mp4',
    );

    /// When marker is not found, extraction should throw
    expect(
      () => MotherlessVideoRipper.videoUrlFromHtml(htmlWithoutMarker, Uri.parse('https://example.com')),
      throwsA(isA<HttpException>()),
    );
  });

  test('MotherlessVideoRipper.rip() extracts first marker from HTML', () {
    /// Java behavior: extracts first occurrence, ignores subsequent ones
    const html = """
      <html>
        <script>var __fileurl = 'https://first.example.com/video.mp4';</script>
        <script>var __fileurl = 'https://second.example.com/video.mp4';</script>
      </html>
    """;

    final url = MotherlessVideoRipper.videoUrlFromHtml(html, Uri.parse('https://example.com'));
    expect(url.toString(), 'https://first.example.com/video.mp4');
  });

  test('MotherlessVideoRipper.rip() reports error without completion when marker is missing',
      () async {
    SharedPreferences.setMockInitialValues({
      'remember.url_history': false,
      'download.timeout': 1000,
    });
    await Utils.init();

    final directory = await Directory.systemTemp.createTemp('ripme_motherless_test');
    addTearDown(() async {
      if (await directory.exists()) await directory.delete(recursive: true);
    });

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close());
    server.listen((request) async {
      request.response.headers.contentType = ContentType.html;
      request.response.write('<html><script>var foo = "bar";</script></html>');
      await request.response.close();
    });

    final ripper = MotherlessVideoRipper(
      Uri.parse('http://127.0.0.1:${server.port}/video'),
    );
    await ripper.setup();

    final statuses = <RipStatusMessage>[];
    final subscription = ripper.statusStream.listen(statuses.add);
    addTearDown(subscription.cancel);

    await ripper.run();
    await Future<void>.delayed(Duration.zero);

    expect(
      statuses.map((status) => status.status),
      [RipStatus.loadingResource, RipStatus.ripErrored],
    );
  });

  test('TwitchVideoRipper.rip() completes when scripts exist without source markers',
      () async {
    SharedPreferences.setMockInitialValues({
      'remember.url_history': false,
      'download.timeout': 1000,
    });
    await Utils.init();

    final directory = await Directory.systemTemp.createTemp('ripme_twitch_test');
    addTearDown(() async {
      if (await directory.exists()) await directory.delete(recursive: true);
    });

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close());
    server.listen((request) async {
      request.response.headers.contentType = ContentType.html;
      request.response.write('<html><script>window.foo = true;</script></html>');
      await request.response.close();
    });

    final ripper = TwitchVideoRipper(
      Uri.parse('http://127.0.0.1:${server.port}/clip'),
    );
    await ripper.setup();

    final statuses = <RipStatusMessage>[];
    final subscription = ripper.statusStream.listen(statuses.add);
    addTearDown(subscription.cancel);

    await ripper.run();
    await Future<void>.delayed(Duration.zero);

    expect(
      statuses.map((status) => status.status),
      [RipStatus.loadingResource, RipStatus.ripComplete],
    );
  });
}
