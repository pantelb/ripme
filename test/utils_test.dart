import 'package:flutter_test/flutter_test.dart';
import 'package:ripme/utils/utils.dart';

void main() {
  test('Utils filesystemSafe', () {
    expect(Utils.filesystemSafe('hello/world?'), equals('helloworld'));
    expect(Utils.filesystemSafe('valid-name_123'), equals('valid-name_123'));
  });

  test('Utils sanitizeSaveAs', () {
    expect(Utils.sanitizeSaveAs('file*name.jpg'), equals('file_name.jpg'));
  });
}
