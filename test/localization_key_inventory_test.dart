import 'package:flutter_test/flutter_test.dart';
import 'package:ripme/localization_key_inventory.dart';

void main() {
  test('extracts Java localized string call keys', () {
    const source = '''
      Utils.getLocalizedString("download.interrupted");
      Utils.getLocalizedString("queue.validation");
      other.getLocalizedString("not.a.java.lookup");
    ''';

    expect(
      JavaLocalizationKeyInventory.keysFromSources([source]),
      {'download.interrupted', 'queue.validation'},
    );
  });

  test('extracts active Java localization properties only', () {
    const properties = '''
      # ignored.key = value
      queue = Queue
      history.check.all=Check All
    ''';

    expect(
      JavaLocalizationKeyInventory.keysFromProperties(properties),
      {'queue', 'history.check.all'},
    );
  });
}
