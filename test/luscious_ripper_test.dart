import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ripme/ripper/rippers/luscious_ripper.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('sanitizes Java URL forms and matches host, domain, and GID', () async {
    final original = Uri.parse(
      'https://luscious.net/albums/h-na-alice-wa-suki-desu-ka-do-you-like-alice-when_321609/',
    );
    final ripper = LusciousRipper(original);

    expect(
      LusciousRipper.sanitizeUrl(original).toString(),
      'https://old.luscious.net/albums/h-na-alice-wa-suki-desu-ka-do-you-like-alice-when_321609/',
    );
    expect(
      LusciousRipper.sanitizeUrl(
        Uri.parse('http://www.luscious.net/albums/title_1/'),
      ).toString(),
      'https://old.luscious.net/albums/title_1/',
    );
    expect(
      LusciousRipper.sanitizeUrl(
        Uri.parse('https://members.luscious.net/albums/title_1/'),
      ).toString(),
      'https://members.luscious.net/albums/title_1/',
    );
    expect(ripper.url.toString(), startsWith('https://old.luscious.net/'));
    expect(ripper.getHost(), 'luscious');
    expect(ripper.getDomain(), 'luscious.net');
    expect(ripper.canRip(original), isTrue);
    expect(
      ripper.canRip(Uri.parse('https://old.luscious.net/albums/name_2/')),
      isTrue,
    );
    expect(await ripper.getGID(ripper.url),
        'h-na-alice-wa-suki-desu-ka-do-you-like-alice-when_321609');
    expect(ripper.albumIdForTesting, '321609');

    await expectLater(
      ripper.getGID(Uri.parse('https://luscious.net/pictures/title_1/')),
      throwsA(isA<FormatException>()),
    );
  });

  test('builds Java-compatible encoded GraphQL API URLs', () {
    final ripper = LusciousRipper(
      Uri.parse('https://luscious.net/albums/title_321609/'),
    );

    expect(
      LusciousRipper.encodeVariablesPartOfURL(1, '321609'),
      '%7B%22input%22%3A%7B%22filters%22%3A%5B%7B%22name%22%3A%22album_id%22%2C%22value%22%3A%22321609%22%7D%5D%2C%22display%22%3A%22rating_all_time%22%2C%22items_per_page%22%3A50%2C%22page%22%3A1%7D%7D',
    );
    expect(
      ripper.buildApiUrl(2, '321609').toString(),
      contains('operationName=PictureListInsideAlbum'),
    );
    expect(
      ripper.buildApiUrl(2, '321609').toString(),
      contains('variables=%7B%22input%22'),
    );
    expect(
      ripper.buildApiUrl(2, '321609').toString(),
      contains('%22page%22%3A2'),
    );
  });

  test('extracts total pages and url_to_original values like Java', () {
    final json = {
      'data': {
        'picture': {
          'list': {
            'info': {'total_pages': 3},
            'items': [
              {'url_to_original': 'https://cdn.example.com/one.jpg'},
              {'url_to_video': 'https://cdn.example.com/skip.mp4'},
              {'url_to_original': 'https://cdn.example.com/two.png?token=1'},
            ],
          },
        },
      },
    };

    expect(LusciousRipper.totalPagesFromJson(json), 3);
    expect(LusciousRipper.urlsFromJson(json), [
      'https://cdn.example.com/one.jpg',
      'https://cdn.example.com/two.png?token=1',
    ]);
    expect(LusciousRipper.totalPagesFromJson({}), 1);
    expect(LusciousRipper.urlsFromJson({}), isEmpty);
  });

  test('uses Java-style ordered filename prefixes', () async {
    SharedPreferences.setMockInitialValues({'download.save_order': true});
    await Utils.init();
    expect(LusciousRipper.prefixForIndex(5), '005_');
    expect(
      LusciousRipper.fileNameForUrl(
        Uri.parse('https://cdn.example.com/path/file.jpg?token=1'),
        5,
      ),
      '005_file.jpg',
    );

    SharedPreferences.setMockInitialValues({'download.save_order': false});
    await Utils.init();
    expect(LusciousRipper.prefixForIndex(5), '');
    expect(
      LusciousRipper.fileNameForUrl(
        Uri.parse('https://cdn.example.com/path/file.jpg'),
        5,
      ),
      'file.jpg',
    );
  });

  test('requests API with Java Firefox user-agent and parses JSON body',
      () async {
    final requests = <Map<String, String>>[];
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    server.listen((request) async {
      requests.add({
        'path': request.uri.path,
        'query': request.uri.query,
        'userAgent': request.headers.value('user-agent') ?? '',
      });
      request.response
        ..statusCode = 200
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({
          'data': {
            'picture': {
              'list': {
                'info': {'total_pages': 1},
                'items': [
                  {'url_to_original': 'https://cdn.example.com/one.jpg'},
                ],
              },
            },
          },
        }));
      await request.response.close();
    });

    final apiBase =
        Uri.parse('http://127.0.0.1:${server.port}/graphql/nobatch/');
    final ripper = LusciousRipper(
      Uri.parse('https://luscious.net/albums/title_321609/'),
      apiBaseUri: apiBase,
    );
    final json = await ripper.getApiJson(ripper.buildApiUrl(1, '321609'));

    expect(
        LusciousRipper.urlsFromJson(json), ['https://cdn.example.com/one.jpg']);
    expect(requests.single['path'], '/graphql/nobatch/');
    expect(requests.single['query'],
        contains('operationName=PictureListInsideAlbum'));
    expect(
      requests.single['userAgent'],
      LusciousRipper.requestHeaders['User-Agent'],
    );
  });
}
