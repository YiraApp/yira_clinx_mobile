
class MedicationInsight {
  final String title;
  final String subTitle;
  final String message;
  final bool isCritical;

  MedicationInsight({
    required this.title,
    required this.subTitle,
    required this.message,
    this.isCritical = false,
  });
}