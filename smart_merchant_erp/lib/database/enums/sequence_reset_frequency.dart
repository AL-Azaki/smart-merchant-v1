/// Sequence reset frequency enum.
enum SequenceResetFrequency {
  never('Never'),
  daily('Daily'),
  monthly('Monthly'),
  yearly('Yearly');

  final String value;
  const SequenceResetFrequency(this.value);

  static SequenceResetFrequency fromValue(String value) {
    return SequenceResetFrequency.values.firstWhere(
      (e) => e.value.toLowerCase() == value.toLowerCase(),
      orElse: () => SequenceResetFrequency.never,
    );
  }
}
