import 'package:intl/intl.dart';

String formatProfileDate(String value, String localeName) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '';
  final parsed = DateTime.tryParse(trimmed);
  if (parsed == null) return trimmed;
  return DateFormat.yMMMMd(localeName).format(parsed);
}

String formatProfileGender(String value, String maleLabel, String femaleLabel) {
  final normalized = value.trim().toLowerCase();
  if (normalized == 'm' || normalized == 'male' || normalized == 'homme') {
    return maleLabel;
  }
  if (normalized == 'f' || normalized == 'female' || normalized == 'femme') {
    return femaleLabel;
  }
  return value.trim();
}
