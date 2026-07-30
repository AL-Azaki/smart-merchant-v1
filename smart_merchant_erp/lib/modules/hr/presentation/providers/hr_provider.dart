import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../app/di/getit_providers.dart';
import '../../../../app/di/injection.dart';
import '../../../../kernel/core/application_context.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../../../database/daos/hr_dao.dart';
import '../../domain/repositories/hr_repository.dart';
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
        id: data['id']?.toString(),
        employeeCode: data['employee_code']?.toString() ?? 'EMP',
        name: data['name']?.toString() ?? '',
        nameEn: data['name_en']?.toString(),
        phone: data['phone']?.toString(),
        jobTitle: data['position']?.toString() ?? data['job_title']?.toString(),
        departmentId: data['department_id']?.toString(),
        isActive: data['status'] == 'active',
        salary: data['salary'] != null ? (data['salary'] as num?)?.toDouble() : null,
      );
      final result = await service.saveEmployee(command);
      return result.isRight();
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteEmployee(String id) async {
    try {
      final service = getIt<EmployeeApplicationService>();
      final result = await service.deleteEmployee(id);
      return result.isRight();
    } catch (e) {
      return false;
    }
  }
}

@riverpod
Stream<List<Employee>> employeesList(EmployeesListRef ref) {
  final repo = getIt<HrRepository>();
  final context = getIt<ApplicationContext>();
  final businessId = context.currentBusinessId ?? '';
  if (businessId.isEmpty) return Stream.value([]);
  
  return repo.watchEmployees(EmployeeFilter(
    businessId: businessId,
  ));
}

@riverpod
Stream<EmployeeWithDetails?> employeeDetails(EmployeeDetailsRef ref, String id) async* {
  final repo = getIt<HrRepository>();
  final context = getIt<ApplicationContext>();
  final businessId = context.currentBusinessId ?? '';
  if (businessId.isEmpty) {
    yield null;
    return;
  }
  
  // watchEmployeeById only returns Employee, but we need details. Since watchEmployeeWithDetails is not available,
  // we'll yield the Future result repeatedly or just use a FutureProvider.
  // Actually, let's just make it a FutureProvider.
}

@riverpod
Future<EmployeeWithDetails?> employeeDetailsFuture(EmployeeDetailsFutureRef ref, String id) {
  final repo = getIt<HrRepository>();
  final context = getIt<ApplicationContext>();
  final businessId = context.currentBusinessId ?? '';
  if (businessId.isEmpty) return Future.value(null);
  return repo.getEmployeeWithDetails(id, businessId);
}
