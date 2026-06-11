import 'package:flutter_test/flutter_test.dart';
import 'package:ripme/ripper/legacy_ripper_inventory.dart';

void main() {
  test('extracts unique Java ripper classes from base and video paths', () {
    final classes = LegacyRipperInventory.classNamesFromPaths(const [
      'src/main/java/com/rarchives/ripme/ripper/rippers/ImgurRipper.java',
      'src/main/java/com/rarchives/ripme/ripper/rippers/video/VkRipper.java',
      'src/main/java/com/rarchives/ripme/ripper/rippers/VkRipper.java',
      r'src\main\java\com\rarchives\ripme\ripper\rippers\ZizkiRipper.java',
      'src/main/java/com/rarchives/ripme/ripper/rippers/ripperhelpers/ChanSite.java',
    ]);

    expect(classes, {'ImgurRipper', 'VkRipper', 'ZizkiRipper'});
  });
}
