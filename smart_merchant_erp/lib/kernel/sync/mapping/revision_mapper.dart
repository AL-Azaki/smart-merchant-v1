/// Explicit mapper between Flutter's `version` column (integer, per-record monotonic counter)
/// and Laravel's `revision` field (integer, monotonic).
///
/// Both represent the same concept — a monotonically increasing integer that tracks
/// how many times a record has been modified. Flutter uses `version` as the Drift column name;
/// Laravel uses `revision` as the API field name.
///
/// This mapper ensures we never confuse the two naming conventions and provides a
/// single place to adjust if semantics ever diverge.
class RevisionMapper {
  /// Convert Flutter's local `version` to the `revision` expected by Laravel's push API.
  static int toServerRevision(int localVersion) => localVersion;

  /// Convert Laravel's `revision` from pull/push response to the local `version` value.
  static int toLocalVersion(int serverRevision) => serverRevision;
}
