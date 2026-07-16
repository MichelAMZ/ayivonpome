sealed class FamilyRelationshipError implements Exception {
  const FamilyRelationshipError(this.code);

  final String code;

  @override
  String toString() => code;
}

final class RelationshipAlreadyExists extends FamilyRelationshipError {
  const RelationshipAlreadyExists() : super('relationship_already_exists');
}

final class RelationshipCycleDetected extends FamilyRelationshipError {
  const RelationshipCycleDetected() : super('relationship_cycle_detected');
}

final class ParentAlreadyAssigned extends FamilyRelationshipError {
  const ParentAlreadyAssigned() : super('parent_already_assigned');
}

final class InvalidFamilyRelationship extends FamilyRelationshipError {
  const InvalidFamilyRelationship() : super('invalid_family_relationship');
}

final class MemberNotFound extends FamilyRelationshipError {
  const MemberNotFound() : super('member_not_found');
}
