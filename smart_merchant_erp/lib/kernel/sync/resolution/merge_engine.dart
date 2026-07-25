/// Governs field-level preference rules when merging local and remote dictionaries.
enum FieldMergePreference {
  /// Always prefer the local value if present and non-null.
  preferLocal,

  /// Always prefer the remote server value if present and non-null.
  preferRemote,

  /// Prefer whichever field has a non-null or non-empty value; if both exist, prefer remote.
  preferNonNullRemote,
}

/// Reusable field-level merge engine responsible for combining local offline records
/// and remote cloud server dictionaries without overwriting critical identifiers
/// or executing module-specific business rules.
class SyncMergeEngine {
  /// Standard set of protected structural keys that are never overwritten during field merges.
  static const Set<String> defaultProtectedKeys = {
    'id',
    'localUuid',
    'idempotencyKey',
    'createdAt',
  };

  /// Performs a field-level merge of [localMap] and [remoteMap].
  ///
  /// Protects critical identity fields listed in [protectedKeys], prevents unnecessary
  /// null overwrites, and applies [fieldPreferences] when specified.
  Map<String, dynamic> mergeDictionaries({
    required Map<String, dynamic> localMap,
    required Map<String, dynamic> remoteMap,
    Set<String> protectedKeys = defaultProtectedKeys,
    Map<String, FieldMergePreference> fieldPreferences = const {},
    FieldMergePreference defaultPreference = FieldMergePreference.preferRemote,
  }) {
    final merged = Map<String, dynamic>.from(localMap);

    for (final entry in remoteMap.entries) {
      final key = entry.key;
      final remoteValue = entry.value;
      final localValue = localMap[key];

      // 1. Skip protected structural identity keys
      if (protectedKeys.contains(key)) {
        continue;
      }

      // 2. If key doesn't exist locally, add from remote
      if (!localMap.containsKey(key)) {
        merged[key] = remoteValue;
        continue;
      }

      // 3. Determine preference for this specific field
      final pref = fieldPreferences[key] ?? defaultPreference;

      switch (pref) {
        case FieldMergePreference.preferLocal:
          if (localValue != null) {
            merged[key] = localValue;
          } else {
            merged[key] = remoteValue;
          }
          break;

        case FieldMergePreference.preferRemote:
          if (remoteValue != null) {
            merged[key] = remoteValue;
          } else {
            merged[key] = localValue;
          }
          break;

        case FieldMergePreference.preferNonNullRemote:
          if (remoteValue != null && remoteValue != '') {
            merged[key] = remoteValue;
          } else {
            merged[key] = localValue;
          }
          break;
      }
    }

    return merged;
  }
}
