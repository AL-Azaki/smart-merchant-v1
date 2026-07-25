import '../../../../kernel/storage/app_database.dart';
import '../../../../database/daos/hr_dao.dart';

/// Contract for HR & Employees domain data operations.
abstract class HrRepository {
  // Departments
  Future<Department?> getDepartmentById(String id, String businessId);
  Future<List<Department>> listDepartments(DepartmentFilter filter);
  Stream<List<Department>> watchDepartments(DepartmentFilter filter);
  Future<List<DepartmentNode>> getDepartmentTree(String businessId);
  Future<Department> insertDepartment(DepartmentsCompanion companion);
  Future<bool> updateDepartment(DepartmentsCompanion companion);
  Future<bool> deleteDepartment(String id, String businessId);
  Future<List<Department>> getPendingSyncDepartments(String businessId);
  Future<bool> markDepartmentAsSynced(String id, String businessId);

  // Job Titles
  Future<JobTitle?> getJobTitleById(String id, String businessId);
  Future<List<JobTitle>> listJobTitles(JobTitleFilter filter);
  Stream<List<JobTitle>> watchJobTitles(JobTitleFilter filter);
  Future<JobTitle> insertJobTitle(JobTitlesCompanion companion);
  Future<bool> updateJobTitle(JobTitlesCompanion companion);
  Future<bool> deleteJobTitle(String id, String businessId);
  Future<List<JobTitle>> getPendingSyncJobTitles(String businessId);
  Future<bool> markJobTitleAsSynced(String id, String businessId);

  // Employees
  Future<Employee?> getEmployeeById(
    String id,
    String businessId, {
    bool includeDeleted = false,
  });
  Future<Employee?> getEmployeeByCode(
    String employeeCode,
    String businessId, {
    bool includeDeleted = false,
  });
  Future<EmployeeWithDetails?> getEmployeeWithDetails(
    String id,
    String businessId, {
    bool includeDeleted = false,
  });
  Future<List<Employee>> listEmployees(EmployeeFilter filter);
  Future<List<EmployeeWithDetails>> listEmployeesWithDetails(
    EmployeeFilter filter,
  );
  Stream<List<Employee>> watchEmployees(EmployeeFilter filter);
  Stream<Employee?> watchEmployeeById(
    String id,
    String businessId, {
    bool includeDeleted = false,
  });
  Future<Employee> insertEmployee(EmployeesCompanion companion);
  Future<Employee> insertEmployeeWithDocuments(
    EmployeesCompanion companion,
    List<EmployeeDocumentsCompanion> documents,
  );
  Future<bool> updateEmployee(EmployeesCompanion companion);
  Future<bool> softDeleteEmployee(String id, String businessId);
  Future<bool> restoreEmployee(String id, String businessId);
  Future<List<Employee>> getPendingSyncEmployees(String businessId);
  Future<bool> markEmployeeAsSynced(String id, String businessId);

  // Employee Documents
  Future<EmployeeDocument?> getDocumentById(String id, String businessId);
  Future<List<EmployeeDocument>> listDocumentsByEmployeeId(
    String employeeId,
    String businessId,
  );
  Future<List<EmployeeDocument>> listDocuments(EmployeeDocumentFilter filter);
  Future<EmployeeDocument> insertDocument(EmployeeDocumentsCompanion companion);
  Future<bool> updateDocument(EmployeeDocumentsCompanion companion);
  Future<bool> deleteDocument(String id, String businessId);
  Future<List<EmployeeDocument>> getPendingSyncEmployeeDocuments(
    String businessId,
  );
  Future<bool> markEmployeeDocumentAsSynced(String id, String businessId);
}
