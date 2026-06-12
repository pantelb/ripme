import 'package:flutter_test/flutter_test.dart';
import 'package:ripme/ripper/abstract_single_file_ripper.dart';
import 'package:ripme/ripper/rippers/ruleporn_ripper.dart';
import 'package:ripme/ripper/rippers/spankbang_ripper.dart';
import 'package:ripme/ripper/rippers/xvideos_ripper.dart';
import 'package:ripme/ripper/rippers/youporn_ripper.dart';
import 'package:ripme/utils/utils.dart';

void main() {
  test('formats bytes with Java IEC magnitude and precision', () {
    expect(Utils.bytesToHumanReadable(1023), '1023.00iB');
    expect(Utils.bytesToHumanReadable(1024), '1.00KiB');
    expect(Utils.bytesToHumanReadable(1572864), '1.50MiB');
    expect(
      Utils.getByteStatusText(50, 1024, 2048),
      '50%  - 1.00KiB / 2.00KiB',
    );
  });

  test('restores Java AbstractSingleFileRipper inheritance', () {
    expect(
      RulePornRipper(Uri.parse('https://ruleporn.com/example/')),
      isA<AbstractSingleFileRipper>(),
    );
    expect(
      SpankbangRipper(Uri.parse('https://spankbang.com/example/video/example')),
      isA<AbstractSingleFileRipper>(),
    );
    expect(
      XvideosRipper(Uri.parse('https://www.xvideos.com/video.123/example')),
      isA<AbstractSingleFileRipper>(),
    );
    expect(
      YoupornRipper(Uri.parse('https://www.youporn.com/watch/123/example')),
      isA<AbstractSingleFileRipper>(),
    );
  });
}
