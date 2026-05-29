import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ripme/ripper/rippers/scrolller_ripper.dart';

void main() {
  test('ScrolllerRipper matches Java URL detection, host, domain, and GID',
      () async {
    final urls = {
      'https://scrolller.com/r/CatsStandingUp': 'CatsStandingUp',
      'https://scrolller.com/r/CatsStandingUp?filter=pictures':
          'CatsStandingUp',
      'https://scrolller.com/r/CatsStandingUp?sort=top&filter=pictures':
          'CatsStandingUp',
      'https://scrolller.com/r/CatsStandingUp?filter=pictures&sort=top':
          'CatsStandingUp',
    };

    for (final entry in urls.entries) {
      final url = Uri.parse(entry.key);
      final ripper = ScrolllerRipper(url);
      expect(ripper.getHost(), 'scrolller');
      expect(ripper.getDomain(), 'scrolller.com');
      expect(ripper.canRip(url), isTrue);
      expect(await ripper.getGID(url), entry.value);
    }

    expect(
      ScrolllerRipper(Uri.parse('https://www.scrolller.com/r/Cats'))
          .canRip(Uri.parse('https://www.scrolller.com/r/Cats')),
      isFalse,
    );
    expect(
      await ScrolllerRipper(Uri.parse('https://scrolller.com/r/Cats-Standing'))
          .getGID(Uri.parse('https://scrolller.com/r/Cats-Standing')),
      'Cats',
    );
  });

  test('ScrolllerRipper matches Java filter and parameter handling', () {
    final cases = {
      'https://scrolller.com/r/CatsStandingUp': 'NOFILTER',
      'https://scrolller.com/r/CatsStandingUp?filter=pictures': 'PICTURE',
      'https://scrolller.com/r/CatsStandingUp?filter=videos': 'VIDEO',
      'https://scrolller.com/r/CatsStandingUp?filter=albums': 'ALBUM',
      'https://scrolller.com/r/CatsStandingUp?sort=top&filter=pictures':
          'PICTURE',
      'https://scrolller.com/r/CatsStandingUp?filter=videos&sort=top': 'VIDEO',
    };

    for (final entry in cases.entries) {
      final ripper = ScrolllerRipper(Uri.parse(entry.key));
      expect(
        ripper.convertFilterString(ripper.getParameter(ripper.url, 'filter')),
        entry.value,
      );
    }

    final ripper = ScrolllerRipper(
      Uri.parse('https://scrolller.com/r/CatsStandingUp?filter=bad'),
    );
    expect(
      ripper.convertFilterString(ripper.getParameter(ripper.url, 'filter')),
      '',
    );
  });

  test('ScrolllerRipper prepares Java GraphQL query variables', () async {
    final requests = <Map<String, dynamic>>[];
    final ripper = ScrolllerRipper(
      Uri.parse('https://scrolller.com/r/CatsStandingUp?filter=pictures'),
      apiClient: MockClient((request) async {
        requests.add(jsonDecode(request.body) as Map<String, dynamic>);
        return http.Response(
          jsonEncode({
            'data': {
              'getSubreddit': {
                'children': {'iterator': null, 'items': []},
              },
            },
          }),
          200,
        );
      }),
    );

    await ripper.getFirstPage();

    expect(requests.single['variables'], {
      'url': '/r/CatsStandingUp',
      'sortBy': '',
      'filter': 'PICTURE',
    });
    expect(requests.single['query'], contains('query SubredditQuery'));
  });

  test('ScrolllerRipper extracts media source using Java bestArea state', () {
    final json = {
      'data': {
        'getSubreddit': {
          'children': {
            'iterator': 'next',
            'items': [
              {
                'mediaSources': [
                  {'url': 'https://img/large.jpg', 'width': 100, 'height': 100},
                  {'url': 'https://img/narrow.jpg', 'width': 2, 'height': 100},
                ],
              },
            ],
          },
        },
      },
    };

    expect(ScrolllerRipper.urlsFromJson(json), ['https://img/narrow.jpg']);
    expect(ScrolllerRipper.iteratorFromJson(json), 'next');
  });

  test('ScrolllerRipper extracts sorted websocket response shape', () {
    final json = {
      'iterator': {
        'data': {
          'fetchSubreddit': {'iterator': null},
        },
      },
      'posts': [
        {
          'data': {
            'fetchSubreddit': {
              'mediaSources': [
                {'url': 'https://img/one.jpg', 'width': 1, 'height': 1},
              ],
            },
          },
        },
        {
          'data': {
            'fetchSubreddit': {'iterator': null},
          },
        },
      ],
    };

    expect(ScrolllerRipper.urlsFromJson(json), ['https://img/one.jpg']);
    expect(ScrolllerRipper.iteratorFromJson(json), isNull);
  });

  test('ScrolllerRipper uses Java-style ordered filenames', () {
    expect(
      ScrolllerRipper.fileNameForUrl(
        Uri.parse('https://img.example.com/path/image.jpg'),
        7,
      ),
      '007_image.jpg',
    );
  });
}
