enum RipStatus {
  loadingResource,
  downloadStarted,
  downloadComplete,
  downloadErrored,
  ripComplete,
  downloadWarn,
  downloadSkip,
  ripErrored,
}

class RipStatusMessage {
  final RipStatus status;
  final dynamic object;

  RipStatusMessage(this.status, this.object);

  @override
  String toString() {
    return "${status.name}: $object";
  }
}
