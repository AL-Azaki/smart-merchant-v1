import 'package:equatable/equatable.dart';

/// Pure domain entity representing a user account in the Smart Merchant ERP system.
/// Completely decoupled from database persistence (Drift) and API serialization models.
class UserEntity extends Equatable {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final bool isActive;
  final DateTime createdAt;

  const UserEntity({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.isActive,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    email,
    firstName,
    lastName,
    isActive,
    createdAt,
  ];
}
