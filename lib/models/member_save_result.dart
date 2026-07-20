enum RemoteSaveStatus {
  confirmed,
  permissionRequired,
  unavailable,
  timedOut,
  failed,
}

class MemberSaveResult {
  const MemberSaveResult({
    required this.localSaved,
    required this.remoteStatus,
    this.operationIds = const [],
    this.firebaseCode,
    this.lastError = '',
  });

  final bool localSaved;
  final RemoteSaveStatus remoteStatus;
  final List<String> operationIds;
  final String? firebaseCode;
  final String lastError;

  bool get isFirestoreConfirmed =>
      localSaved && remoteStatus == RemoteSaveStatus.confirmed;
  bool get isLocalPending =>
      localSaved &&
      (remoteStatus == RemoteSaveStatus.unavailable ||
          remoteStatus == RemoteSaveStatus.timedOut ||
          remoteStatus == RemoteSaveStatus.failed);
  bool get isAuthorizationRequired =>
      localSaved && remoteStatus == RemoteSaveStatus.permissionRequired;
  bool get isFailed => !localSaved;
}
