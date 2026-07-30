import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/di/getit_providers.dart';
import '../../../../app/di/getit_instance.dart';
import '../../../../kernel/core/application_context.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../../../database/daos/hr_dao.dart';
import '../../domain/repositories/hr_repository.dart';
import '../../application/services/employee_application_service.dart';

final hrNotifierProvider = AutoDisposeNotifierProvider<HrNotifier, void>(() => HrNotifier());

class HrNotifier extends AutoDisposeNotifier<void> {
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

final employeesListProvider = StreamProvider.autoDispose<List<Employee>>((ref) => _employeesList(ref));

Stream<List<Employee>> _employeesList(Ref ref)  {
  final repo = getIt<HrRepository>();
  final context = getIt<ApplicationContext>();
  final businessId = context.currentBusinessId ?? '';
  if (businessId.isEmpty) return Stream.value([]);

  return repo.watchEmployees(EmployeeFilter(businessId: businessId));
}

final employeeDetailsProvider = StreamProvider.autoDispose.family<EmployeeWithDetails?, String>((ref, id) => _employeeDetails(ref, id));

Stream<EmployeeWithDetails?> _employeeDetails(
  Ref ref,
  String id,
) async* {
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

final employeeDetailsFutureProvider = FutureProvider.autoDispose.family<EmployeeWithDetails?, String>((ref, id) => _employeeDetailsFuture(ref, id));

Future<EmployeeWithDetails?> _employeeDetailsFuture(
  Ref ref,
  String id,
) {
  final repo = getIt<HrRepository>();
  final context = getIt<ApplicationContext>();
  final businessId = context.currentBusinessId ?? '';
  if (businessId.isEmpty) return Future.value(null);
  return repo.getEmployeeWithDetails(id, businessId);
}
