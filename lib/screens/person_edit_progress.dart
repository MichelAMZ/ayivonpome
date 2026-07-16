class ProfileRequiredField {
  const ProfileRequiredField({
    required this.id,
    required this.stepIndex,
    required this.label,
    required this.value,
  });

  final String id;
  final int stepIndex;
  final String label;
  final String Function() value;

  bool get isComplete => value().trim().isNotEmpty;
}

class ProfileProgress {
  const ProfileProgress({
    required this.totalRequired,
    required this.completedRequired,
    required this.stepTotals,
    required this.stepCompleted,
  });

  final int totalRequired;
  final int completedRequired;
  final Map<int, int> stepTotals;
  final Map<int, int> stepCompleted;

  int get missingRequired => totalRequired - completedRequired;

  int get percent => totalRequired == 0
      ? 100
      : ((completedRequired / totalRequired) * 100).round();

  int stepPercent(int stepIndex) {
    final total = stepTotals[stepIndex] ?? 0;
    if (total == 0) return 100;
    return (((stepCompleted[stepIndex] ?? 0) / total) * 100).round();
  }

  bool isStepComplete(int stepIndex) =>
      stepPercent(stepIndex) == 100 && (stepTotals[stepIndex] ?? 0) > 0;

  static ProfileProgress fromFields(Iterable<ProfileRequiredField> fields) {
    final totals = <int, int>{};
    final completed = <int, int>{};
    var totalRequired = 0;
    var completedRequired = 0;
    for (final field in fields) {
      totalRequired += 1;
      totals[field.stepIndex] = (totals[field.stepIndex] ?? 0) + 1;
      if (field.isComplete) {
        completedRequired += 1;
        completed[field.stepIndex] = (completed[field.stepIndex] ?? 0) + 1;
      }
    }
    return ProfileProgress(
      totalRequired: totalRequired,
      completedRequired: completedRequired,
      stepTotals: totals,
      stepCompleted: completed,
    );
  }
}
