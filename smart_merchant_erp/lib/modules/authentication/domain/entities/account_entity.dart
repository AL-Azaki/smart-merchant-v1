import 'package:equatable/equatable.dart';

/// Pure domain entity representing a business account in the Smart Merchant ERP system.
/// Completely decoupled from database persistence (Drift) and API serialization models.
class AccountEntity extends Equatable {
  final String id;
  final String ownerId;
  final String businessName;
  final String businessType;
  final String defaultCurrency;
  final DateTime createdAt;

  const AccountEntity({
    required this.id,
    required this.ownerId,
    required this.businessName,
    required this.businessType,
    required this.defaultCurrency,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    ownerId,
    businessName,
    businessType,
    defaultCurrency,
    createdAt,
  ];
}
