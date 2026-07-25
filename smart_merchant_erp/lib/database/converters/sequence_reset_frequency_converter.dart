import 'package:drift/drift.dart';
import '../enums/sequence_reset_frequency.dart';

/// Drift TypeConverter for [SequenceResetFrequency] enum to/from String.
class SequenceResetFrequencyConverter
    extends TypeConverter<SequenceResetFrequency, String> {
  const SequenceResetFrequencyConverter();

  @override
  SequenceResetFrequency fromSql(String fromDb) =>
      SequenceResetFrequency.fromValue(fromDb);

  @override
  String toSql(SequenceResetFrequency value) => value.value;
}
