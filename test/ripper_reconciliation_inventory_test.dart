import 'package:flutter_test/flutter_test.dart';
import 'package:ripme/ripper/ripper_reconciliation_inventory.dart';

void main() {
  test('keeps duplicate Java album and video classes distinct in Dart', () {
    expect(
      RipperReconciliationInventory.dartClassForJavaPath(
        '${RipperReconciliationInventory.javaRoot}PornhubRipper.java',
      ),
      'PornhubRipper',
    );
    expect(
      RipperReconciliationInventory.dartClassForJavaPath(
        '${RipperReconciliationInventory.javaRoot}video/PornhubRipper.java',
      ),
      'PornhubVideoRipper',
    );
    expect(
      RipperReconciliationInventory.dartClassForJavaPath(
        '${RipperReconciliationInventory.javaRoot}video/VkRipper.java',
      ),
      'VkVideoRipper',
    );
    expect(
      RipperReconciliationInventory.dartClassForJavaPath(
        '${RipperReconciliationInventory.javaRoot}video/YuvutuRipper.java',
      ),
      'YuvutuVideoRipper',
    );
  });

  test('preserves unique video classes and identifies helper paths', () {
    expect(
      RipperReconciliationInventory.dartClassForJavaPath(
        '${RipperReconciliationInventory.javaRoot}video/ViddmeRipper.java',
      ),
      'ViddmeRipper',
    );
    const helper =
        '${RipperReconciliationInventory.javaRoot}ripperhelpers/ChanSite.java';
    expect(
        RipperReconciliationInventory.dartClassForJavaPath(helper), 'ChanSite');
    expect(RipperReconciliationInventory.isHelperPath(helper), isTrue);
    expect(RipperReconciliationInventory.isVideoPath(helper), isFalse);
  });

  test('rejects non-Java source paths', () {
    expect(
      () => RipperReconciliationInventory.dartClassForJavaPath(
        'lib/ripper/rippers/vk_ripper.dart',
      ),
      throwsArgumentError,
    );
  });
}
