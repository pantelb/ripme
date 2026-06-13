import 'package:flutter_test/flutter_test.dart';
import 'package:ripme/ripper/rippers/erofus_ripper.dart';
import 'package:ripme/ripper/rippers/hentaiimage_ripper.dart';
import 'package:ripme/ripper/rippers/jabarchives_ripper.dart';
import 'package:ripme/ripper/rippers/jagodibuja_ripper.dart';
import 'package:ripme/ripper/rippers/mrcong_ripper.dart';
import 'package:ripme/ripper/rippers/myhentaigallery_ripper.dart';
import 'package:ripme/ripper/rippers/porncomix_ripper.dart';
import 'package:ripme/ripper/rippers/readcomic_ripper.dart';

void main() {
  test('preserves audited Java malformed GID messages including typos',
      () async {
    final invalid = Uri.parse('https://example.com/invalid');
    final cases = <String, Future<String> Function()>{
      'Expected myhentaicomics.com URL format: '
              'myhentaigallery.com/gallery/thumbnails/ID - got $invalid instead':
          () => MyhentaigalleryRipper(invalid).getGID(invalid),
      'Expected proncomix URL format: '
              'porncomix.info/comic - got $invalid instead':
          () => PorncomixRipper(invalid).getGID(invalid),
      'Expected URL format: '
              'http://www.8muses.com/index/category/albumname, got: $invalid':
          () => ErofusRipper(invalid).getGID(invalid),
      'Expected hitomi URL format: '
              'https://hentai-img-xxx.com/image/ID - got $invalid instead':
          () => HentaiimageRipper(invalid).getGID(invalid),
      'Expected jagodibuja.com gallery formats '
              'hwww.jagodibuja.com/Comic name/ got $invalid instead':
          () => JagodibujaRipper(invalid).getGID(invalid),
      'Expected misskon.com URL format: '
              'misskon.com/GALLERY_NAME (or /PAGE_NUMBER/) - got $invalid instead':
          () => MrCongRipper(invalid).getGID(invalid),
      'Expected view-comic URL format: '
              'read-comic.com/COMIC_NAME - got $invalid instead':
          () => ReadcomicRipper(invalid).getGID(invalid),
      'Expected javarchives.com URL format: '
              'jabarchives.com/main/view/albumname - got $invalid instead':
          () => JabArchivesRipper(invalid).getGID(invalid),
    };

    for (final entry in cases.entries) {
      try {
        await entry.value();
        fail('Expected malformed URL failure for ${entry.key}');
      } on FormatException catch (error) {
        expect(error.message, entry.key);
      }
    }
  });
}
