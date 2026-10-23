import 'package:flutter/foundation.dart';
import '../../app/config/api_client.dart';
import '../storage/secure_storage/secure_storage_contract.dart';

enum TimeIntegrityStatus {
  valid,
  clockRollbackDetected,
}

class TimeIntegrityResult {
  final TimeIntegrityStatus status;
  final DateTime currentTime;
  final DateTime? lastTrustedTime;
  final String? message;

  const TimeIntegrityResult({
    required this.status,
    required this.currentTime,
    this.lastTrustedTime,
    this.message,
  });

  bool get isValid => status == TimeIntegrityStatus.valid;
  bool get isTampered => status == TimeIntegrityStatus.clockRollbackDetected;
}

/// Anti-Clock Tampering Engine for offline security.
///
/// Prevents merchants or users from rolling back the device system date
/// to bypass subscription expiration while operating offline.
class TimeIntegrityGuard {
  final SecureStorageContract _storage;

  // Small tolerance (5 minutes) for legitimate minor NTP network adjustments
  static const int _toleranceMillis = 5 * 60 * 1000;

  TimeIntegrityGuard({required SecureStorageContract storage}) : _storage = storage;

  /// Calibrate the trusted clock mark using verified server time received from API response.
  Future<void> calibrateWithServerTime(DateTime serverTime) async {
    try {
      final serverMillis = serverTime.toUtc().millisecondsSinceEpoch;
      await _storage.write(StorageKeys.lastServerTime, serverMillis.toString());
      await _storage.write(StorageKeys.lastTrustedTimestamp, serverMillis.toString());
      debugPrint('[TimeIntegrityGuard] Calibrated trusted time with server: $serverTime');
    } catch (e) {
      debugPrint('[TimeIntegrityGuard] Failed to calibrate server time: $e');
    }
  }

  /// Check whether the current device time is consistent with historical trusted milestones.
  /// If the current device time is earlier than the last known trusted timestamp,
  /// a clock manipulation (rollback) is detected.
  Future<TimeIntegrityResult> checkIntegrity() async {
    final now = DateTime.now().toUtc();
    final currentMillis = now.millisecondsSinceEpoch;

    final stored = await _storage.read(StorageKeys.lastTrustedTimestamp);
    if (stored == null) {
      // First boot or initial record
      await _storage.write(StorageKeys.lastTrustedTimestamp, currentMillis.toString());
      return TimeIntegrityResult(
        status: TimeIntegrityStatus.valid,
        currentTime: now,
      );
    }

    final lastTrustedMillis = int.tryParse(stored);
    if (lastTrustedMillis == null) {
      await _storage.write(StorageKeys.lastTrustedTimestamp, currentMillis.toString());
      return TimeIntegrityResult(
        status: TimeIntegrityStatus.valid,
        currentTime: now,
      );
    }

    // Check if device clock was turned backwards beyond tolerance
    if (currentMillis < (lastTrustedMillis - _toleranceMillis)) {
      final lastTrustedDate = DateTime.fromMillisecondsSinceEpoch(lastTrustedMillis, isUtc: true);
      debugPrint('[TimeIntegrityGuard] ⚠️ CLOCK ROLLBACK TAMPER DETECTED! Current: $now < LastTrusted: $lastTrustedDate');
      return TimeIntegrityResult(
        status: TimeIntegrityStatus.clockRollbackDetected,
        lastTrustedTime: lastTrustedDate,
        currentTime: now,
        message: 'تم اكتشاف تلاعب في ساعة وتاريخ الجهاز. يرجى ضبط الوقت التلقائي من الشبكة والمزامنة عبر الإنترنت.',
      );
    }

    // Device time is monotonic and moving forward; update high-water mark
    if (currentMillis > lastTrustedMillis) {
      await _storage.write(StorageKeys.lastTrustedTimestamp, currentMillis.toString());
    }

    return TimeIntegrityResult(
      status: TimeIntegrityStatus.valid,
      lastTrustedTime: DateTime.fromMillisecondsSinceEpoch(lastTrustedMillis, isUtc: true),
      currentTime: now,
    );
  }
}
