import 'dart:convert';
import 'package:drift/drift.dart';

/// Drift TypeConverter for JSON Map<String, dynamic> to/from String.
class JsonConverter extends TypeConverter<Map<String, dynamic>, String> {
  const JsonConverter();

  @override
  Map<String, dynamic> fromSql(String fromDb) {
    if (fromDb.isEmpty) return {};
    try {
      return jsonDecode(fromDb) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  @override
  String toSql(Map<String, dynamic> value) => jsonEncode(value);
}
