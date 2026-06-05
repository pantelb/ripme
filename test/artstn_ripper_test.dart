import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ripme/ripper/rippers/artstn_ripper.dart';

void main() {
  test('matches Java short-domain canRip behavior', () {
    final ripper = ArtstnRipper(Uri.parse('https://artstn.co/p/JlE15Z'));

    expect(ripper.canRip(Uri.parse('https://artstn.co/p/JlE15Z')), isTrue);
    expect(
        ripper.canRip(Uri.parse('https://www.artstation.com/artwork/JlE15Z')),
        isFalse);
  });

  test('resolves absolute redirect locations recursively like the Java ripper',
      () {
    expect(
      ArtstnRipper.redirectTarget(
        Uri.parse('https://artstn.co/p/JlE15Z'),
        302,
        'https://www.artstation.com/artwork/JlE15Z',
      ).toString(),
      'https://www.artstation.com/artwork/JlE15Z',
    );
    expect(
      () => ArtstnRipper.redirectTarget(
        Uri.parse('https://artstn.co/p/JlE15Z'),
        301,
        '/artwork/JlE15Z',
      ),
      throwsFormatException,
    );
    expect(
      ArtstnRipper.redirectTarget(
          Uri.parse('https://artstn.co/p/JlE15Z'), 200, null),
      isNull,
    );
  });

  test('surfaces unresolved redirect failures through null path like Java',
      () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    server.listen((request) async {
      request.response.statusCode = 200;
      await request.response.close();
    });
    final url = Uri.parse('http://127.0.0.1:${server.port}/p/JlE15Z');
    final ripper = ArtstnRipper(url);

    await expectLater(
      ripper.getGID(url),
      throwsA(isA<TypeError>()),
    );
  });
}
