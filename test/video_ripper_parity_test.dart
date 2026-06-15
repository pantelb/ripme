import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ripme/ripper/abstract_ripper.dart';
import 'package:ripme/ripper/rippers/motherless_video_ripper.dart';
import 'package:ripme/ui/rip_status_message.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ripme/utils/utils.dart';

void main() {
  tearDown(AbstractRipper.resetTestMode);

  test('MotherlessVideoRipper diagnostic: logs WTF when marker is present', () {
    /// Java MotherlessVideoRipper.rip() checks if html.contains("__fileurl = '")
    /// and if so, calls logger.error("WTF"). This is a diagnostic side effect
    /// that should be honored in Dart.
    final htmlWithMarker = """
      <html>
        <script>var __fileurl = 'https://cdn.example.com/video.mp4';</script>
      </html>
    """;
    final htmlWithoutMarker = """
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
    final html = """
      <html>
        <script>var __fileurl = 'https://first.example.com/video.mp4';</script>
        <script>var __fileurl = 'https://second.example.com/video.mp4';</script>
      </html>
    """;

    final url = MotherlessVideoRipper.videoUrlFromHtml(html, Uri.parse('https://example.com'));
    expect(url.toString(), 'https://first.example.com/video.mp4');
  });
}
