enum RipStatus {
  loadingResource,
  downloadStarted,
  downloadComplete,
  downloadCompleteHistory,
  downloadErrored,
  ripComplete,
  downloadWarn,
  downloadSkip,
  ripErrored,
  queueAdd,
  totalBytes,
  completedBytes,
}

extension RipStatusDisplayName on RipStatus {
  String get displayName {
    switch (this) {
      case RipStatus.loadingResource:
        return 'Loading Resource';
      case RipStatus.downloadStarted:
        return 'Download Started';
      case RipStatus.downloadComplete:
        return 'Download Complete';
      case RipStatus.downloadCompleteHistory:
        return 'Download Complete History';
      case RipStatus.downloadErrored:
        return 'Download Errored';
      case RipStatus.ripComplete:
        return 'Rip Complete';
      case RipStatus.downloadWarn:
        return 'Download problem';
      case RipStatus.downloadSkip:
        return 'Download Skipped';
      case RipStatus.ripErrored:
        return 'Rip Errored';
      case RipStatus.queueAdd:
        return 'Queue Add';
      case RipStatus.totalBytes:
        return 'Total bytes';
      case RipStatus.completedBytes:
        return 'Completed bytes';
    }
  }
}

class RipStatusMessage {
  final RipStatus status;
  final dynamic object;

  RipStatusMessage(this.status, this.object);

  @override
  String toString() {
    return '${status.displayName}: $object';
  }
}
