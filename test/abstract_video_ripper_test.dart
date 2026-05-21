import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' show parse;
import 'package:ripme/ripper/abstract_video_ripper.dart';
import 'package:ripme/ui/rip_status_message.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TestVideoRipper extends AbstractVideoRipper {
  TestVideoRipper(super.url, this.directory, this.videoUrl,
      {this.downloadRequest, this.captureDownload = false});

  final Directory directory;
  final Uri videoUrl;
  final VideoDownloadRequest? downloadRequest;
  final bool captureDownload;
  Uri? receivedDownloadUrl;
  File? receivedSaveAs;
  Map<String, String>? receivedHeaders;
  Map<String, String>? receivedCookies;

  @override
  Future<void> setup() async {
    workingDir = directory;
  }

  @override
  bool canRip(Uri url) => true;

  @override
  Future<String> getGID(Uri url) async => 'video';

  @override
  String getHost() => 'test';

  @override
  Future<Uri> getVideoURLForRip(Uri url) async => videoUrl;

  @override
  Future<VideoDownloadRequest> getVideoDownloadForRip(Uri url) async {
    return downloadRequest ?? await super.getVideoDownloadForRip(url);
  }

  @override
  Future<void> downloadFile(Uri url, File saveAs,
      {Map<String, String>? headers,
      Map<String, String>? cookies,
      bool allowDuplicate = false}) async {
    if (!captureDownload) {
      return super.downloadFile(
        url,
        saveAs,
        headers: headers,
        cookies: cookies,
        allowDuplicate: allowDuplicate,
      );
    }
    receivedDownloadUrl = url;
    receivedSaveAs = saveAs;
    receivedHeaders = headers;
    receivedCookies = cookies;
    await saveAs.writeAsString('video');
    sendUpdate(RipStatus.downloadComplete, saveAs.path);
  }
}

void main() {
  test('uses shared download path for video rips', () async {
    SharedPreferences.setMockInitialValues({
      'remember.url_history': false,
      'download.ignore_extensions': 'mp4',
    });
    await Utils.init();

    final directory = await Directory.systemTemp.createTemp('ripme_video_test');
    addTearDown(() => directory.delete(recursive: true));

    final ripper = TestVideoRipper(
      Uri.parse('https://example.com/video-page'),
      directory,
      Uri.parse('https://example.com/video.mp4'),
    );
    await ripper.setup();

    final statuses = <RipStatusMessage>[];
    final sub = ripper.statusStream.listen(statuses.add);
    addTearDown(sub.cancel);

    await ripper.rip();
    await Future<void>.delayed(Duration.zero);

    expect(
      statuses.map((status) => status.status),
      containsAllInOrder([
        RipStatus.loadingResource,
        RipStatus.downloadSkip,
        RipStatus.ripComplete,
      ]),
    );
    expect(statuses[1].object.toString(), contains('ignored extension'));
    expect(await File('${directory.path}/video.mp4').exists(), isFalse);
  });

  test('uses videos album title and default page referer for video downloads',
      () async {
    SharedPreferences.setMockInitialValues({
      'remember.url_history': false,
    });
    await Utils.init();

    final directory = await Directory.systemTemp.createTemp('ripme_video_test');
    addTearDown(() => directory.delete(recursive: true));

    final ripper = TestVideoRipper(
      Uri.parse('https://example.com/video-page'),
      directory,
      Uri.parse('https://cdn.example.com/video-source'),
      captureDownload: true,
    );
    await ripper.setup();

    await ripper.rip();

    expect(await ripper.getAlbumTitle(ripper.url), 'videos');
    expect(ripper.receivedDownloadUrl.toString(),
        'https://cdn.example.com/video-source');
    expect(
        ripper.receivedHeaders, {'Referer': 'https://example.com/video-page'});
    expect(ripper.receivedSaveAs?.path, '${directory.path}/video-source.mp4');
  });

  test('honors explicit video filenames, referers, and cookies', () async {
    SharedPreferences.setMockInitialValues({
      'remember.url_history': false,
    });
    await Utils.init();

    final directory = await Directory.systemTemp.createTemp('ripme_video_test');
    addTearDown(() => directory.delete(recursive: true));

    final ripper = TestVideoRipper(
      Uri.parse('https://example.com/video-page'),
      directory,
      Uri.parse('https://cdn.example.com/fallback.mp4'),
      downloadRequest: VideoDownloadRequest(
        url: Uri.parse('https://cdn.example.com/best'),
        fileName: 'unsafe:name',
        headers: {'Referer': 'https://example.com/embed'},
        cookies: {'session': 'abc'},
      ),
      captureDownload: true,
    );
    await ripper.setup();

    await ripper.rip();

    expect(
        ripper.receivedDownloadUrl.toString(), 'https://cdn.example.com/best');
    expect(ripper.receivedHeaders, {'Referer': 'https://example.com/embed'});
    expect(ripper.receivedCookies, {'session': 'abc'});
    expect(ripper.receivedSaveAs?.path, '${directory.path}/unsafe_name.mp4');
  });

  test('selects highest DASH representation from manifest', () {
    final manifest = parse('''
      <MPD><Period><AdaptationSet>
        <Representation height="360"><BaseURL>DASH_360.mp4</BaseURL></Representation>
        <Representation height="720"><BaseURL>DASH_720.mp4</BaseURL></Representation>
      </AdaptationSet></Period></MPD>
    ''');

    final best = AbstractVideoRipper.bestDashVideoUrl(
      manifest,
      Uri.parse('https://v.redd.it/abc/DASHPlaylist.mpd'),
    );

    expect(best.toString(), 'https://v.redd.it/abc/DASH_720.mp4');
  });

  test('selects highest HLS variant from manifest', () {
    final best = AbstractVideoRipper.bestHlsVideoUrl('''
#EXTM3U
#EXT-X-STREAM-INF:BANDWIDTH=200000,RESOLUTION=426x240
low/index.m3u8
#EXT-X-STREAM-INF:BANDWIDTH=1200000,RESOLUTION=1280x720
high/index.m3u8
''', Uri.parse('https://video.example.com/master.m3u8'));

    expect(best.toString(), 'https://video.example.com/high/index.m3u8');
  });
}
