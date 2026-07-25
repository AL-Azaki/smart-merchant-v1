import 'dart:math' as math;
import 'package:equatable/equatable.dart';

/// Governs retry scheduling, exponential backoff intervals, and permanent failure boundaries
/// for background synchronization operations across all ERP modules.
class SyncRetryPolicy extends Equatable {
  /// Maximum number of attempts allowed before marking the queued task as permanently failed.
  final int maxAttempts;

  /// Base delay duration before executing the first retry attempt.
  final Duration initialDelay;

  /// Multiplier applied to the previous delay for each subsequent attempt (`Exponential Backoff`).
  final double backoffFactor;

  /// Maximum upper limit cap on the retry delay duration.
  final Duration maxDelay;

  /// Set of HTTP status codes indicating a permanent client or authentication error (`400`, `401`, `403`, `404`, `422`).
  /// Operations failing with these codes are never retried to prevent duplicate uploads or infinite loops.
  final Set<int> nonRetryableStatusCodes;

  const SyncRetryPolicy({
    this.maxAttempts = 5,
    this.initialDelay = const Duration(seconds: 5),
    this.backoffFactor = 2.0,
    this.maxDelay = const Duration(minutes: 30),
    this.nonRetryableStatusCodes = const {400, 401, 403, 404, 422},
  });

  /// Standard enterprise retry policy for transactional financial uploads.
  factory SyncRetryPolicy.transactional() => const SyncRetryPolicy(
    maxAttempts: 7,
    initialDelay: Duration(seconds: 3),
    maxDelay: Duration(hours: 1),
  );

  /// Standard retry policy for background analytical or telemetry logs.
  factory SyncRetryPolicy.telemetry() => const SyncRetryPolicy(
    maxAttempts: 3,
    initialDelay: Duration(seconds: 10),
    backoffFactor: 1.5,
    maxDelay: Duration(minutes: 10),
  );

  /// Calculates the delay duration before the next retry attempt given the `currentAttempt` number.
  /// Uses exponential backoff clamped by `maxDelay`.
  Duration calculateNextDelay(int currentAttempt) {
    if (currentAttempt <= 0) {
      return initialDelay;
    }
    final calculatedMillis =
        initialDelay.inMilliseconds * math.pow(backoffFactor, currentAttempt);
    final clampedMillis = math.min(
      calculatedMillis,
      maxDelay.inMilliseconds.toDouble(),
    );
    return Duration(milliseconds: clampedMillis.toInt());
  }

  /// Determines whether a failed synchronization attempt is eligible for another retry attempt.
  bool shouldRetry(
    int currentAttempt, {
    int? statusCode,
    bool canRetryError = true,
  }) {
    if (!canRetryError) {
      return false;
    }
    if (currentAttempt >= maxAttempts) {
      return false;
    }
    if (statusCode != null && nonRetryableStatusCodes.contains(statusCode)) {
      return false;
    }
    return true;
  }

  @override
  List<Object?> get props => [
    maxAttempts,
    initialDelay,
    backoffFactor,
    maxDelay,
    nonRetryableStatusCodes,
  ];
}
