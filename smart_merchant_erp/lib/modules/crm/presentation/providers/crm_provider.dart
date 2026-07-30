import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../app/di/getit_providers.dart';
import '../../../../app/di/injection.dart';
import '../../../sales/application/services/customer_application_service.dart';
import '../../../purchasing/application/services/supplier_application_service.dart';

part 'crm_provider.g.dart';

@riverpod
class CrmNotifier extends _$CrmNotifier {
  @override
  void build() {
    return;
  }

  Future<String?> saveCustomer(Map<String, dynamic> data) async {
    try {
      final service = getIt<CustomerApplicationService>();
      final command = CustomerCommand(
        id: data['id']?.toString(),
        name: data['name']?.toString() ?? '',
        nameEn: data['name_en']?.toString(),
        phone: data['phone']?.toString(),
        email: data['email']?.toString(),
        address: data['address']?.toString(),
        creditLimit: data['credit_limit'] != null ? double.tryParse(data['credit_limit'].toString()) : null,
        openingBalance: data['opening_balance'] != null ? double.tryParse(data['opening_balance'].toString()) : null,
        openingBalanceType: data['opening_balance_type']?.toString(),
        openingBalanceDate: data['opening_balance_date'] != null ? DateTime.tryParse(data['opening_balance_date'].toString()) : null,
      );
      final result = await service.saveCustomer(command);
      return result.fold((l) => null, (r) => r);
    } catch (e) {
      return null;
    }
  }

  Future<String?> saveSupplier(Map<String, dynamic> data) async {
    try {
      final service = getIt<SupplierApplicationService>();
      final command = SupplierCommand(
        id: data['id']?.toString(),
        name: data['name']?.toString() ?? '',
        nameEn: data['name_en']?.toString(),
        contactPerson: data['contact_person']?.toString(),
        phone: data['phone']?.toString(),
        email: data['email']?.toString(),
        address: data['address']?.toString(),
        creditLimit: data['credit_limit'] != null ? double.tryParse(data['credit_limit'].toString()) : null,
        openingBalance: data['opening_balance'] != null ? double.tryParse(data['opening_balance'].toString()) : null,
        openingBalanceType: data['opening_balance_type']?.toString(),
        openingBalanceDate: data['opening_balance_date'] != null ? DateTime.tryParse(data['opening_balance_date'].toString()) : null,
      );
      final result = await service.saveSupplier(command);
      return result.fold((l) => null, (r) => r);
    } catch (e) {
      return null;
    }
  }
}
