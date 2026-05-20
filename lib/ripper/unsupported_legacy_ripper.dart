import '../ui/rip_status_message.dart';
import 'abstract_ripper.dart';
import 'ripper_migration_catalog.dart';

class UnsupportedLegacyRipper extends AbstractRipper {
  final LegacyRipperMatch match;

  UnsupportedLegacyRipper(super.url, this.match);

  @override
  Future<void> setup() async {}

  @override
  Future<void> rip() async {
    sendUpdate(
      RipStatus.ripErrored,
      '${match.displayName} is supported by the Java RipMe application '
      '(${match.javaClass}) but has not been ported to Flutter/Dart yet.',
    );
  }

  @override
  String getHost() => match.displayName.toLowerCase();

  @override
  Future<String> getGID(Uri url) async => url.host;

  @override
  bool canRip(Uri url) =>
      RipperMigrationCatalog.findUnportedLegacyRipper(url)?.javaClass ==
      match.javaClass;
}
