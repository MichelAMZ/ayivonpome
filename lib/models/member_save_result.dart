enum MemberSaveStatus {
  firestoreConfirmed,
  localPending,
  authorizationRequired,
  failed,
}

class MemberSaveResult {
  const MemberSaveResult({
    required this.status,
    this.lastError = '',
    this.lastErrorCode = '',
  });

  final MemberSaveStatus status;
  final String lastError;
  final String lastErrorCode;

  bool get isFirestoreConfirmed =>
      status == MemberSaveStatus.firestoreConfirmed;
  bool get isLocalPending => status == MemberSaveStatus.localPending;
  bool get isAuthorizationRequired =>
      status == MemberSaveStatus.authorizationRequired;
  bool get isFailed => status == MemberSaveStatus.failed;
}
