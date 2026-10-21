import 'package:equatable/equatable.dart';

/// Immutable model representing an online order status feedback event destined for Laravel.
///
/// Ensures offline durability, idempotency, and retry capability without coupling
/// to sales invoices or stock deduction logic.
class OrderStatusFeedbackItem extends Equatable {
  final String id;
  final String orderId;
  final String status;
  final String idempotencyKey;
  final String? invoiceId;
  final String? invoiceNumber;
  final String? completedAt;
  final int retryCount;
  final bool isSynced;
  final String? lastError;
  final int? lastErrorCode;
  final DateTime? nextRetryAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const OrderStatusFeedbackItem({
    required this.id,
    required this.orderId,
    required this.status,
    required this.idempotencyKey,
    required this.createdAt,
    required this.updatedAt,
    this.invoiceId,
    this.invoiceNumber,
    this.completedAt,
    this.retryCount = 0,
    this.isSynced = false,
    this.lastError,
    this.lastErrorCode,
    this.nextRetryAt,
  });

  OrderStatusFeedbackItem copyWith({
    String? id,
    String? orderId,
    String? status,
    String? idempotencyKey,
    String? invoiceId,
    String? invoiceNumber,
    String? completedAt,
    int? retryCount,
    bool? isSynced,
    String? lastError,
    int? lastErrorCode,
    DateTime? nextRetryAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrderStatusFeedbackItem(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      status: status ?? this.status,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      invoiceId: invoiceId ?? this.invoiceId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      completedAt: completedAt ?? this.completedAt,
      retryCount: retryCount ?? this.retryCount,
      isSynced: isSynced ?? this.isSynced,
      lastError: lastError ?? this.lastError,
      lastErrorCode: lastErrorCode ?? this.lastErrorCode,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'status': status,
      'idempotency_key': idempotencyKey,
      if (invoiceId != null) 'invoice_id': invoiceId,
      if (invoiceNumber != null) 'invoice_number': invoiceNumber,
      if (completedAt != null) 'completed_at': completedAt,
      'retry_count': retryCount,
      'is_synced': isSynced,
      if (lastError != null) 'last_error': lastError,
      if (lastErrorCode != null) 'last_error_code': lastErrorCode,
      if (nextRetryAt != null) 'next_retry_at': nextRetryAt!.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory OrderStatusFeedbackItem.fromJson(Map<String, dynamic> json) {
    return OrderStatusFeedbackItem(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      status: json['status'] as String,
      idempotencyKey: json['idempotency_key'] as String,
      invoiceId: json['invoice_id'] as String?,
      invoiceNumber: json['invoice_number'] as String?,
      completedAt: json['completed_at'] as String?,
      retryCount: (json['retry_count'] as num?)?.toInt() ?? 0,
      isSynced: json['is_synced'] as bool? ?? false,
      lastError: json['last_error'] as String?,
      lastErrorCode: (json['last_error_code'] as num?)?.toInt(),
      nextRetryAt: json['next_retry_at'] != null
          ? DateTime.parse(json['next_retry_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  @override
  List<Object?> get props => [
        id,
        orderId,
        status,
        idempotencyKey,
        invoiceId,
        invoiceNumber,
        completedAt,
        retryCount,
        isSynced,
        lastError,
        lastErrorCode,
        nextRetryAt,
        createdAt,
        updatedAt,
      ];
}
