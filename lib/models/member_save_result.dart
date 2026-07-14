enum MemberSaveStatus { firestoreConfirmed, localPending, failed }

class MemberSaveResult {
  const MemberSaveResult({required this.status, this.lastError = ''});

  final MemberSaveStatus status;
  final String lastError;

  bool get isFirestoreConfirmed =>
      status == MemberSaveStatus.firestoreConfirmed;
  bool get isLocalPending => status == MemberSaveStatus.localPending;
  bool get isFailed => status == MemberSaveStatus.failed;
}
