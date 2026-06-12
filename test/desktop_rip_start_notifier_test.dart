import 'package:flutter_test/flutter_test.dart';
import 'package:ripme/desktop_rip_start_notifier.dart';
import 'package:ripme/desktop_tray_controller.dart';

void main() {
  test('does not notify while disabled', () async {
    final presented = <String>[];
    final notifier = DesktopRipStartNotifier(
      window: _FakeWindow(visible: false, focused: false),
      presenter: ({required title, required body}) async {
        presented.add('$title|$body');
      },
    );

    await notifier.notify('https://example.com/a', enabled: false);

    expect(presented, isEmpty);
  });

  test('does not notify while the main window is visible and focused',
      () async {
    final presented = <String>[];
    final notifier = DesktopRipStartNotifier(
      window: _FakeWindow(visible: true, focused: true),
      presenter: ({required title, required body}) async {
        presented.add('$title|$body');
      },
    );

    await notifier.notify('https://example.com/a', enabled: true);

    expect(presented, isEmpty);
  });

  test('uses Java notification title and body for an inactive window',
      () async {
    final presented = <String>[];
    final notifier = DesktopRipStartNotifier(
      window: _FakeWindow(visible: true, focused: false),
      presenter: ({required title, required body}) async {
        presented.add('$title|$body');
      },
    );

    await notifier.notify('https://example.com/a', enabled: true);

    if (DesktopTrayController.isSupportedDesktop) {
      expect(
        presented.single,
        'Ripping - RipMe v1.0.0|Started ripping https://example.com/a',
      );
    } else {
      expect(presented, isEmpty);
    }
  });
}

class _FakeWindow implements DesktopWindowOperations {
  _FakeWindow({required this.visible, required this.focused});

  final bool visible;
  final bool focused;

  @override
  Future<void> exit() async {}

  @override
  Future<void> hide() async {}

  @override
  Future<bool> isFocused() async => focused;

  @override
  Future<bool> isVisible() async => visible;

  @override
  Future<void> showAndFocus() async {}
}
