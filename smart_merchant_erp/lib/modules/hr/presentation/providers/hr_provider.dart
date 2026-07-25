import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../app/di/getit_providers.dart';
import '../../../../app/di/injection.dart';
import '../../application/services/employee_application_service.dart';

part 'hr_provider.g.dart';

@riverpod
class HrNotifier extends _$HrNotifier {
  @override
  void build() {
    return;
  }

  Future<bool> saveEmployee(Map<String, dynamic> data) async {
    try {
      final service = getIt<EmployeeApplicationService>();
      final command = EmployeeCommand(
        id: data['id'],
        employeeCode: data['employee_code'] ?? 'EMP',
        name: data['name'],
        nameEn: data['name_en'],
        jobTitle: data['position'],
        departmentId: data['department_id'],
        isActive: data['is_active'] ?? true,
      );
      final result = await service.saveEmployee(command);
      return result.isRight();
    } catch (e) {
      return false;
    }
  }
}
