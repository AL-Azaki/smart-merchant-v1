import 'package:drift/drift.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/account_entity.dart';

/// Extension methods for converting Drift persistence objects ([UserAccount], [BusinessAccount])
/// into clean Domain Entities ([UserEntity], [AccountEntity]), preventing database leak into domain layer.
extension UserAccountMapper on UserAccount {
  UserEntity toEntity() => UserEntity(
    id: id,
    email: email,
    firstName: firstName,
    lastName: lastName,
    isActive: isActive,
    createdAt: createdAt,
  );
}

extension BusinessAccountMapper on BusinessAccount {
  AccountEntity toEntity() => AccountEntity(
    id: id,
    ownerId: ownerId,
    businessName: businessName,
    businessType: businessType,
    defaultCurrency: defaultCurrency,
    createdAt: createdAt,
  );
}

extension UserEntityMapper on UserEntity {
  UsersTableCompanion toCompanion({String? passwordHash}) =>
      UsersTableCompanion(
        id: Value(id),
        email: Value(email),
        passwordHash: passwordHash != null
            ? Value(passwordHash)
            : const Value.absent(),
        firstName: Value(firstName),
        lastName: Value(lastName),
        isActive: Value(isActive),
        createdAt: Value(createdAt),
      );
}

extension AccountEntityMapper on AccountEntity {
  AccountsTableCompanion toCompanion() => AccountsTableCompanion(
    id: Value(id),
    ownerId: Value(ownerId),
    businessName: Value(businessName),
    businessType: Value(businessType),
    defaultCurrency: Value(defaultCurrency),
    createdAt: Value(createdAt),
  );
}
