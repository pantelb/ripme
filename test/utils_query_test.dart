import 'package:flutter_test/flutter_test.dart';
import 'package:ripme/utils/utils.dart';

void main() {
  group('Utils.parseUrlQuery', () {
    test('returns an empty map for an empty query like Java', () {
      expect(Utils.parseUrlQuery(''), isEmpty);
      expect(Utils.parseUrlQueryValue('', 'missing'), isNull);
    });

    test('decodes keys and values with Java URLDecoder semantics', () {
      final result = Utils.parseUrlQuery(
        'plain=value&space=hello+world&encoded%20key=a%2Bb',
      );

      expect(result, {
        'plain': 'value',
        'space': 'hello world',
        'encoded key': 'a+b',
      });
      expect(
        Utils.parseUrlQueryValue(
          'plain=value&space=hello+world&encoded%20key=a%2Bb',
          'encoded key',
        ),
        'a+b',
      );
    });

    test('preserves empty values for parts without equals signs', () {
      expect(Utils.parseUrlQuery('flag&empty=&named=value'), {
        'flag': '',
        'empty': '',
        'named': 'value',
      });
      expect(Utils.parseUrlQueryValue('flag&empty=&named=value', 'flag'), '');
      expect(Utils.parseUrlQueryValue('flag&empty=&named=value', 'empty'), '');
      expect(Utils.parseUrlQueryValue('flag&empty=&named=value', 'missing'),
          isNull);
    });

    test('matches Java duplicate and equals-sign behavior', () {
      expect(Utils.parseUrlQuery('dup=first&dup=second&token=a=b=c'), {
        'dup': 'second',
        'token': 'a=b=c',
      });
      expect(
        Utils.parseUrlQueryValue('dup=first&dup=second&token=a=b=c', 'dup'),
        'first',
      );
      expect(
        Utils.parseUrlQueryValue('dup=first&dup=second&token=a=b=c', 'token'),
        'a=b=c',
      );
    });

    test('keeps Java split behavior for empty middle parts and trailing amps',
        () {
      expect(Utils.parseUrlQuery('a=1&&b=2&&'), {
        'a': '1',
        '': '',
        'b': '2',
      });
      expect(Utils.parseUrlQueryValue('a=1&&b=2&&', ''), '');
    });
  });
}
