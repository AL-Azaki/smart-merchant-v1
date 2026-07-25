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

  Future<bool> saveCustomer(Map<String, dynamic> data) async {
    try {
      final service = getIt<CustomerApplicationService>();
      final command = CustomerCommand(
        id: data['id'],
        name: data['name'],
        nameEn: data['name_en'],
        phone: data['phone'],
        email: data['email'],
        address: data['address'],
      );
      final result = await service.saveCustomer(command);
      return result.isRight();
    } catch (e) {
      return false;
    }
  }

  Future<bool> saveSupplier(Map<String, dynamic> data) async {
    try {
      final service = getIt<SupplierApplicationService>();
      final command = SupplierCommand(
        id: data['id'],
        name: data['name'],
        nameEn: data['name_en'],
        phone: data['phone'],
        email: data['email'],
        address: data['address'],
      );
      final result = await service.saveSupplier(command);
      return result.isRight();
    } catch (e) {
      return false;
    }
  }
}
