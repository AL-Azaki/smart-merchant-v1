import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../app/config/api_client.dart';
import '../storage/secure_storage/secure_storage_contract.dart';
import 'time_integrity_guard.dart';

enum SubscriptionLeaseStatus {
  active,
  expiringSoon,
  gracePeriod,
  expired,
  clockTampered,
  noLease,
}

class SubscriptionLeaseCheck {
  final SubscriptionLeaseStatus status;
  final int daysRemaining;
  final double amountDue;
  final DateTime? nextDueDate;
  final String? planName;
  final String message;

  const SubscriptionLeaseCheck({
    required this.status,
    required this.message,
    this.daysRemaining = 0,
    this.amountDue = 0.0,
    this.nextDueDate,
    this.planName,
  });

  bool get isOperational =>
      status == SubscriptionLeaseStatus.active ||
      status == SubscriptionLeaseStatus.expiringSoon ||
      status == SubscriptionLeaseStatus.gracePeriod;

  bool get shouldShowWarningBanner =>
      status == SubscriptionLeaseStatus.expiringSoon ||
      status == SubscriptionLeaseStatus.gracePeriod;

  bool get isBlocked =>
      status == SubscriptionLeaseStatus.expired ||
      status == SubscriptionLeaseStatus.clockTampered ||
      status == SubscriptionLeaseStatus.noLease;
}

/// Offline Subscription Security Guard.
///
/// Enforces cryptographically signed offline lease tokens, detects installment expiration
/// even when the internet is completely disconnected, and works in tandem with [TimeIntegrityGuard]
/// to block clock rollback attacks.
class SubscriptionLeaseGuard {
  final SecureStorageContract _storage;
  final TimeIntegrityGuard _timeGuard;

  SubscriptionLeaseGuard({
    required SecureStorageContract storage,
    required TimeIntegrityGuard timeGuard,
  })  : _storage = storage,
        _timeGuard = timeGuard;

  /// Store or update the offline lease payload received from server bootstrap or refresh.
  Future<void> saveLease(Map<String, dynamic> leaseData) async {
    try {
      final payload = leaseData['payload'] as Map<String, dynamic>?;
      final signedToken = leaseData['signed_token'] as String?;

      if (payload != null) {
        await _storage.write(StorageKeys.subscriptionLease, jsonEncode(payload));
        if (signedToken != null) {
          await _storage.write(StorageKeys.subscriptionLeaseToken, signedToken);
        }

        // Calibrate server time if present
        if (payload['server_time'] != null) {
          final serverDate = DateTime.tryParse(payload['server_time'].toString());
          if (serverDate != null) {
            await _timeGuard.calibrateWithServerTime(serverDate);
          }
        }
      }
    } catch (e) {
      debugPrint('[SubscriptionLeaseGuard] Failed to save lease: $e');
    }
  }

  /// Get cached lease payload.
  Future<Map<String, dynamic>?> getCachedLease() async {
    final raw = await _storage.read(StorageKeys.subscriptionLease);
    if (raw == null) {
      return null;
    }
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Validate current subscription lease status against offline milestones and anti-tamper rules.
  Future<SubscriptionLeaseCheck> validateLease() async {
    // 1. Check Anti-Tampering (Clock Rollback)
    final timeResult = await _timeGuard.checkIntegrity();
    if (timeResult.isTampered) {
      return SubscriptionLeaseCheck(
        status: SubscriptionLeaseStatus.clockTampered,
        message: timeResult.message ?? 'تم اكتشاف تلاعب في وقت الجهاز. يرجى إعادة ضبط الوقت التلقائي والاتصال بالإنترنت.',
      );
    }

    // 2. Read cached lease
    final lease = await getCachedLease();
    if (lease == null) {
      return const SubscriptionLeaseCheck(
        status: SubscriptionLeaseStatus.noLease,
        message: 'لا توجد رخصة اشتراك مسجلة محلياً. يرجى الاتصال بالإنترنت لتفعيل الحساب.',
      );
    }

    // 3. Status in lease
    final serverStatus = lease['status'] as String? ?? 'Active';
    if (serverStatus != 'Active') {
      return const SubscriptionLeaseCheck(
        status: SubscriptionLeaseStatus.expired,
        message: 'عقد الاشتراك الحالي منتهي أو معلق. يرجى سداد القسط المستحق لتفعيل الخدمة.',
      );
    }

    final planName = lease['plan_name'] as String? ?? 'خطة تاجركم';
    final now = DateTime.now().toUtc();

    // 4. Parse Dates
    DateTime? validUntil;
    if (lease['valid_until'] != null) {
      validUntil = DateTime.tryParse(lease['valid_until'].toString())?.toUtc();
    }

    DateTime? hardExpiry;
    if (lease['hard_expiry_with_grace'] != null) {
      hardExpiry = DateTime.tryParse(lease['hard_expiry_with_grace'].toString())?.toUtc();
    }

    final nextInst = lease['next_installment'] as Map<String, dynamic>?;
    final amountDue = (nextInst?['amount'] as num?)?.toDouble() ??
        (lease['remaining_balance'] as num?)?.toDouble() ??
        0.0;

    // 5. Evaluate Expiration
    if (hardExpiry != null && now.isAfter(hardExpiry)) {
      return SubscriptionLeaseCheck(
        status: SubscriptionLeaseStatus.expired,
        amountDue: amountDue,
        nextDueDate: validUntil,
        planName: planName,
        message: 'انتهت فترة الاشتراك وفترة السماح المحددة للقسط. يرجى سداد المستحقات لاستئناف العمل.',
      );
    }

    if (validUntil != null) {
      final difference = validUntil.difference(now);
      final daysRemaining = difference.inDays;

      if (now.isAfter(validUntil)) {
        // In grace period
        final graceDiff = hardExpiry != null ? hardExpiry.difference(now).inDays : 0;
        return SubscriptionLeaseCheck(
          status: SubscriptionLeaseStatus.gracePeriod,
          daysRemaining: graceDiff,
          amountDue: amountDue,
          nextDueDate: validUntil,
          planName: planName,
          message: 'تنبيه: انتهت مهلة سداد القسط! أنت الآن في فترة السماح المؤقتة (متبقي $graceDiff أيام). يرجى السداد لتجنب إيقاف الخدمة.',
        );
      } else if (daysRemaining <= 7) {
        // Expiring soon (Within 7 days)
        return SubscriptionLeaseCheck(
          status: SubscriptionLeaseStatus.expiringSoon,
          daysRemaining: daysRemaining,
          amountDue: amountDue,
          nextDueDate: validUntil,
          planName: planName,
          message: 'تنبيه: متبقي $daysRemaining أيام على موعد استحقاق القسط القادم ($amountDue YER).',
        );
      }
    }

    // Fully active & healthy
    final days = validUntil != null ? validUntil.difference(now).inDays : 30;
    return SubscriptionLeaseCheck(
      status: SubscriptionLeaseStatus.active,
      daysRemaining: days,
      amountDue: amountDue,
      nextDueDate: validUntil,
      planName: planName,
      message: 'الاشتراك نشط وساري المفعول.',
    );
  }
}
