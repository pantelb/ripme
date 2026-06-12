import 'package:flutter_test/flutter_test.dart';
import 'package:ripme/ui/rip_status_message.dart';

void main() {
  test('renders Java status display labels', () {
    const labels = {
      RipStatus.loadingResource: 'Loading Resource',
      RipStatus.downloadStarted: 'Download Started',
      RipStatus.downloadComplete: 'Download Complete',
      RipStatus.downloadCompleteHistory: 'Download Complete History',
      RipStatus.downloadErrored: 'Download Errored',
      RipStatus.ripComplete: 'Rip Complete',
      RipStatus.downloadWarn: 'Download problem',
      RipStatus.downloadSkip: 'Download Skipped',
      RipStatus.ripErrored: 'Rip Errored',
      RipStatus.queueAdd: 'Queue Add',
      RipStatus.totalBytes: 'Total bytes',
      RipStatus.completedBytes: 'Completed bytes',
    };

    for (final entry in labels.entries) {
      expect(
        RipStatusMessage(entry.key, 'value').toString(),
        '${entry.value}: value',
      );
    }
  });
}
