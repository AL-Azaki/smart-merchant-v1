import 'package:injectable/injectable.dart';
import '../../domain/repositories/hr_repository.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../../../kernel/error/repository_exceptions.dart';
import '../../../../database/daos/hr_dao.dart';

@LazySingleton(as: HrRepository)
class HrRepositoryImpl implements HrRepository {
  final HrDao _dao;

  HrRepositoryImpl(this._dao);

  // Departments
  @override
  Future<Department?> getDepartmentById(String id, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.getDepartmentById(id, businessId),
    );
  }

  @override
  Future<List<Department>> listDepartments(DepartmentFilter filter) {
    return RepositoryErrorGuard.run(() => _dao.listDepartments(filter));
  }

  @override
  Stream<List<Department>> watchDepartments(DepartmentFilter filter) {
    return RepositoryErrorGuard.guardStream(_dao.watchDepartments(filter));
  }

  @override
  Future<List<DepartmentNode>> getDepartmentTree(String businessId) {
    return RepositoryErrorGuard.run(() => _dao.getDepartmentTree(businessId));
  }

  @override
  Future<Department> insertDepartment(DepartmentsCompanion companion) {
    return RepositoryErrorGuard.run(() => _dao.insertDepartment(companion));
  }

  @override
  Future<bool> updateDepartment(DepartmentsCompanion companion) {
    return RepositoryErrorGuard.run(() => _dao.updateDepartment(companion));
  }

  @override
  Future<bool> deleteDepartment(String id, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.deleteDepartment(id, businessId),
    );
  }

  @override
  Future<List<Department>> getPendingSyncDepartments(String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.getPendingSyncDepartments(businessId),
    );
  }

  @override
  Future<bool> markDepartmentAsSynced(String id, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.markDepartmentAsSynced(id, businessId),
    );
  }

  // Job Titles
  @override
  Future<JobTitle?> getJobTitleById(String id, String businessId) {
    return RepositoryErrorGuard.run(() => _dao.getJobTitleById(id, businessId));
  }

  @override
  Future<List<JobTitle>> listJobTitles(JobTitleFilter filter) {
    return RepositoryErrorGuard.run(() => _dao.listJobTitles(filter));
  }

  @override
  Stream<List<JobTitle>> watchJobTitles(JobTitleFilter filter) {
    return RepositoryErrorGuard.guardStream(_dao.watchJobTitles(filter));
  }

  @override
  Future<JobTitle> insertJobTitle(JobTitlesCompanion companion) {
    return RepositoryErrorGuard.run(() => _dao.insertJobTitle(companion));
  }

  @override
  Future<bool> updateJobTitle(JobTitlesCompanion companion) {
    return RepositoryErrorGuard.run(() => _dao.updateJobTitle(companion));
  }

  @override
  Future<bool> deleteJobTitle(String id, String businessId) {
    return RepositoryErrorGuard.run(() => _dao.deleteJobTitle(id, businessId));
  }

  @override
  Future<List<JobTitle>> getPendingSyncJobTitles(String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.getPendingSyncJobTitles(businessId),
    );
  }

  @override
  Future<bool> markJobTitleAsSynced(String id, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.markJobTitleAsSynced(id, businessId),
    );
  }

  // Employees
  @override
  Future<Employee?> getEmployeeById(
    String id,
    String businessId, {
    bool includeDeleted = false,
  }) {
    return RepositoryErrorGuard.run(
      () =>
          _dao.getEmployeeById(id, businessId, includeDeleted: includeDeleted),
    );
  }

  @override
  Future<Employee?> getEmployeeByCode(
    String employeeCode,
    String businessId, {
    bool includeDeleted = false,
  }) {
    return RepositoryErrorGuard.run(
      () => _dao.getEmployeeByCode(
        employeeCode,
        businessId,
        includeDeleted: includeDeleted,
      ),
    );
  }

  @override
  Future<EmployeeWithDetails?> getEmployeeWithDetails(
    String id,
    String businessId, {
    bool includeDeleted = false,
  }) {
    return RepositoryErrorGuard.run(
      () => _dao.getEmployeeWithDetails(
        id,
        businessId,
        includeDeleted: includeDeleted,
      ),
    );
  }

  @override
  Future<List<Employee>> listEmployees(EmployeeFilter filter) {
    return RepositoryErrorGuard.run(() => _dao.listEmployees(filter));
  }

  @override
  Future<List<EmployeeWithDetails>> listEmployeesWithDetails(
    EmployeeFilter filter,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.listEmployeesWithDetails(filter),
    );
  }

  @override
  Stream<List<Employee>> watchEmployees(EmployeeFilter filter) {
    return RepositoryErrorGuard.guardStream(_dao.watchEmployees(filter));
  }

  @override
  Stream<Employee?> watchEmployeeById(
    String id,
    String businessId, {
    bool includeDeleted = false,
  }) {
    return RepositoryErrorGuard.guardStream(
      _dao.watchEmployeeById(id, businessId, includeDeleted: includeDeleted),
    );
  }

  @override
  Future<Employee> insertEmployee(EmployeesCompanion companion) {
    return RepositoryErrorGuard.run(() => _dao.insertEmployee(companion));
  }

  @override
  Future<Employee> insertEmployeeWithDocuments(
    EmployeesCompanion companion,
    List<EmployeeDocumentsCompanion> documents,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.insertEmployeeWithDocuments(companion, documents),
    );
  }

  @override
  Future<bool> updateEmployee(EmployeesCompanion companion) {
    return RepositoryErrorGuard.run(() => _dao.updateEmployee(companion));
  }

  @override
  Future<bool> softDeleteEmployee(String id, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.softDeleteEmployee(id, businessId),
    );
  }

  @override
  Future<bool> restoreEmployee(String id, String businessId) {
    return RepositoryErrorGuard.run(() => _dao.restoreEmployee(id, businessId));
  }

  @override
  Future<List<Employee>> getPendingSyncEmployees(String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.getPendingSyncEmployees(businessId),
    );
  }

  @override
  Future<bool> markEmployeeAsSynced(String id, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.markEmployeeAsSynced(id, businessId),
    );
  }

  // Employee Documents
  @override
  Future<EmployeeDocument?> getDocumentById(String id, String businessId) {
    return RepositoryErrorGuard.run(() => _dao.getDocumentById(id, businessId));
  }

  @override
  Future<List<EmployeeDocument>> listDocumentsByEmployeeId(
    String employeeId,
    String businessId,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.listDocumentsByEmployeeId(employeeId, businessId),
    );
  }

  @override
  Future<List<EmployeeDocument>> listDocuments(EmployeeDocumentFilter filter) {
    return RepositoryErrorGuard.run(() => _dao.listDocuments(filter));
  }

  @override
  Future<EmployeeDocument> insertDocument(
    EmployeeDocumentsCompanion companion,
  ) {
    return RepositoryErrorGuard.run(() => _dao.insertDocument(companion));
  }

  @override
  Future<bool> updateDocument(EmployeeDocumentsCompanion companion) {
    return RepositoryErrorGuard.run(() => _dao.updateDocument(companion));
  }

  @override
  Future<bool> deleteDocument(String id, String businessId) {
    return RepositoryErrorGuard.run(() => _dao.deleteDocument(id, businessId));
  }

  @override
  Future<List<EmployeeDocument>> getPendingSyncEmployeeDocuments(
    String businessId,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.getPendingSyncEmployeeDocuments(businessId),
    );
  }

  @override
  Future<bool> markEmployeeDocumentAsSynced(String id, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.markEmployeeDocumentAsSynced(id, businessId),
    );
  }
}
