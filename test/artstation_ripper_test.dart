import 'package:flutter_test/flutter_test.dart';
import 'package:ripme/ripper/rippers/artstation_ripper.dart';

void main() {
  test('discovers project JSON links from ArtStation HTML', () {
    final parsed = ArtStationRipper.parseUrlFromHtml(
      Uri.parse('https://www.artstation.com/artwork/abc123'),
      "<script>window.app = '/projects/abc123.json';</script>",
    );

    expect(parsed.type, ArtStationUrlType.singleProject);
    expect(parsed.id, 'abc123');
    expect(parsed.jsonUrl.toString(),
        'https://www.artstation.com/projects/abc123.json');
  });

  test('discovers user portfolio JSON links from ArtStation HTML', () {
    final parsed = ArtStationRipper.parseUrlFromHtml(
      Uri.parse('https://www.artstation.com/example-user'),
      "<script>window.user = '/users/example-user/quick.json';</script>",
    );

    expect(parsed.type, ArtStationUrlType.userPortfolio);
    expect(parsed.id, 'example-user');
    expect(parsed.jsonUrl.toString(),
        'https://www.artstation.com/users/example-user/projects.json');
  });

  test('falls back from artwork URL to project JSON when HTML is unavailable',
      () {
    final parsed = ArtStationRipper.parseUrlFromHtml(
      Uri.parse('https://www.artstation.com/artwork/cloudflareId'),
      '',
    );

    expect(parsed.type, ArtStationUrlType.singleProject);
    expect(parsed.id, 'cloudflareId');
    expect(parsed.jsonUrl.toString(),
        'https://www.artstation.com/projects/cloudflareId.json');
  });

  test('extracts hosted image assets and ignores external embeds', () {
    final assets = ArtStationRipper.urlsFromProjectJson({
      'title': 'Project: One?',
      'assets': [
        {'image_url': 'https://cdn.artstation.com/p/assets/images/one.jpg'},
        {'image_url': ''},
        {'player_embedded': '<iframe></iframe>'},
        {'image_url': 'https://cdn.artstation.com/p/assets/images/two.png'},
      ],
    });

    expect(assets.map((asset) => asset.url.toString()), [
      'https://cdn.artstation.com/p/assets/images/one.jpg',
      'https://cdn.artstation.com/p/assets/images/two.png',
    ]);
    expect(assets.first.projectTitle, 'Project: One?');
  });

  test('uses Java-compatible metadata and portfolio folder sanitization', () {
    expect(ArtStationRipper.projectTitleFromJson({'title': 'Project Title'}),
        'Project Title');
    expect(ArtStationRipper.fullNameFromQuickJson({'full_name': 'Artist Name'}),
        'Artist Name');
    expect(ArtStationRipper.projectFolderName('A:B*C?D...   '), 'A_B_C_D');
  });
}
