import 'package:drift/drift.dart';
import '../../kernel/error/exceptions.dart';
import '../../kernel/storage/app_database.dart';
import '../tables/core/branches_table.dart';
import '../tables/core/businesses_table.dart';
import '../tables/hr/departments_table.dart';
import '../tables/hr/employee_documents_table.dart';
import '../tables/hr/employees_table.dart';
import '../tables/hr/job_titles_table.dart';
import 'dao_exceptions.dart';

part 'hr_dao.g.dart';

/// Filter DTO for [Departments] queries.
class DepartmentFilter {
  final String businessId;
  final String? parentId;
  final String? managerId;
  final bool? isActive;
  final String? searchQuery;
  final int limit;
  final int offset;

  const DepartmentFilter({
    required this.businessId,
    this.parentId,
    this.managerId,
    this.isActive,
    this.searchQuery,
    this.limit = 50,
    this.offset = 0,
  });
}

/// Node representation for a hierarchical department tree.
class DepartmentNode {
  final Department department;
  final List<DepartmentNode> children;
  final Employee? manager;

  const DepartmentNode({
    required this.department,
    required this.children,
    this.manager,
  });
}

/// Filter DTO for [JobTitles] queries.
class JobTitleFilter {
  final String businessId;
  final bool? isActive;
  final String? searchQuery;
  final int limit;
  final int offset;

  const JobTitleFilter({
    required this.businessId,
    this.isActive,
    this.searchQuery,
    this.limit = 50,
    this.offset = 0,
  });
}

/// Filter DTO for [Employees] queries.
class EmployeeFilter {
  final String businessId;
  final String? departmentId;
  final String? jobTitleId;
  final String? status;
  final bool includeDeleted;
  final String? searchQuery;
  final int limit;
  final int offset;

  const EmployeeFilter({
    required this.businessId,
    this.departmentId,
    this.jobTitleId,
    this.status,
    this.includeDeleted = false,
    this.searchQuery,
    this.limit = 50,
    this.offset = 0,
  });
}

/// Composite DTO combining an [Employee] with their [Department] and [JobTitle].
class EmployeeWithDetails {
  final Employee employee;
  final Department? department;
  final JobTitle? jobTitle;

  const EmployeeWithDetails({
    required this.employee,
    this.department,
    this.jobTitle,
  });
}

/// Filter DTO for [EmployeeDocuments] queries.
class EmployeeDocumentFilter {
  final String businessId;
  final String? employeeId;
  final String? documentType;
  final int limit;
  final int offset;

  const EmployeeDocumentFilter({
    required this.businessId,
    this.employeeId,
    this.documentType,
    this.limit = 50,
    this.offset = 0,
  });
}

/// Data Access Object for the Human Resources (HR) domain.
///
/// Manages [Departments], [EmployeeDocuments], [Employees], and [JobTitles] tables.
@DriftAccessor(
  tables: [
    Departments,
    EmployeeDocuments,
    Employees,
    JobTitles,
    Branches,
    Businesses,
  ],
)
class HrDao extends DatabaseAccessor<AppDatabase> with _$HrDaoMixin {
  HrDao(super.db);

  // ============================================================================
  // 1. DEPARTMENTS OPERATIONS (Tenant Scoped)
  // ============================================================================

  /// Retrieves a department by ID within a business.
  Future<Department?> getDepartmentById(String id, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getDepartmentById requires businessId.',
      );
    }
    return (select(departments)
          ..where((d) => d.id.equals(id) & d.businessId.equals(businessId)))
        .getSingleOrNull();
  }

  /// Lists departments matching the provided filter with pagination.
  Future<List<Department>> listDepartments(DepartmentFilter filter) {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'listDepartments requires businessId.',
      );
    }
    final query = select(departments)
      ..where((d) => d.businessId.equals(filter.businessId));

    if (filter.parentId != null) {
      query.where((d) => d.parentId.equals(filter.parentId!));
    }
    if (filter.managerId != null) {
      query.where((d) => d.managerId.equals(filter.managerId!));
    }
    if (filter.isActive != null) {
      query.where((d) => d.isActive.equals(filter.isActive!));
    }
    if (filter.searchQuery != null && filter.searchQuery!.trim().isNotEmpty) {
      final q = '%${filter.searchQuery!.trim()}%';
      query.where((d) => d.departmentName.like(q) | d.departmentCode.like(q));
    }

    query
      ..orderBy([
        (d) => OrderingTerm(expression: d.departmentName),
        (d) => OrderingTerm(expression: d.id),
      ])
      ..limit(filter.limit, offset: filter.offset);

    return query.get();
  }

  /// Reactive stream of departments matching the filter.
  Stream<List<Department>> watchDepartments(DepartmentFilter filter) {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'watchDepartments requires businessId.',
      );
    }
    final query = select(departments)
      ..where((d) => d.businessId.equals(filter.businessId));

    if (filter.parentId != null) {
      query.where((d) => d.parentId.equals(filter.parentId!));
    }
    if (filter.managerId != null) {
      query.where((d) => d.managerId.equals(filter.managerId!));
    }
    if (filter.isActive != null) {
      query.where((d) => d.isActive.equals(filter.isActive!));
    }
    if (filter.searchQuery != null && filter.searchQuery!.trim().isNotEmpty) {
      final q = '%${filter.searchQuery!.trim()}%';
      query.where((d) => d.departmentName.like(q) | d.departmentCode.like(q));
    }

    query
      ..orderBy([
        (d) => OrderingTerm(expression: d.departmentName),
        (d) => OrderingTerm(expression: d.id),
      ])
      ..limit(filter.limit, offset: filter.offset);

    return query.watch();
  }

  /// Builds and returns the hierarchical tree of departments for a business.
  Future<List<DepartmentNode>> getDepartmentTree(String businessId) async {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getDepartmentTree requires businessId.',
      );
    }
    final allDepts =
        await (select(departments)
              ..where((d) => d.businessId.equals(businessId))
              ..orderBy([(d) => OrderingTerm(expression: d.departmentName)]))
            .get();

    final allMgrs =
        await (select(employees)..where(
              (e) => e.businessId.equals(businessId) & e.deletedAt.isNull(),
            ))
            .get();
    final mgrMap = {for (final e in allMgrs) e.id: e};

    // Helper to recursively build tree from parent ID
    List<DepartmentNode> buildNodes(String? parentId) {
      final children = allDepts.where((d) => d.parentId == parentId).toList();
      return children.map((d) {
        return DepartmentNode(
          department: d,
          children: buildNodes(d.id),
          manager: d.managerId != null ? mgrMap[d.managerId] : null,
        );
      }).toList();
    }

    return buildNodes(null);
  }

  /// Inserts a new department.
  Future<Department> insertDepartment(DepartmentsCompanion companion) async {
    final busId = companion.businessId.value;
    if (busId.trim().isEmpty) {
      throw const TenantScopingException(
        'insertDepartment requires businessId.',
      );
    }

    final toInsert = companion.copyWith(
      syncStatus: companion.syncStatus.present
          ? companion.syncStatus
          : const Value('pending'),
      version: companion.version.present ? companion.version : const Value(1),
      createdAt: companion.createdAt.present
          ? companion.createdAt
          : Value(DateTime.now()),
      updatedAt: companion.updatedAt.present
          ? companion.updatedAt
          : Value(DateTime.now()),
    );

    try {
      final rowId = await into(departments).insert(toInsert);
      final id = companion.id.value;
      final inserted =
          await (select(departments)
                ..where((d) => d.id.equals(id) & d.businessId.equals(busId)))
              .getSingleOrNull();
      if (inserted != null) {
        return inserted;
      }
      return (await (select(
        departments,
      )..where((d) => d.rowId.equals(rowId))).getSingle());
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('unique constraint failed')) {
        throw const DuplicateRecordException(
          'Department with exact code or id already exists.',
        );
      } else if (msg.contains('foreign key constraint failed')) {
        throw const ForeignKeyConstraintException(
          'Invalid businessId, parentId, or managerId reference.',
        );
      }
      rethrow;
    }
  }

  /// Updates an existing department.
  Future<bool> updateDepartment(DepartmentsCompanion companion) async {
    if (!companion.id.present || !companion.businessId.present) {
      throw const TenantScopingException(
        'updateDepartment requires both id and businessId.',
      );
    }
    final id = companion.id.value;
    final busId = companion.businessId.value;

    final existing = await getDepartmentById(id, busId);
    if (existing == null) {
      throw const RecordNotFoundException('Department not found for update.');
    }

    final toUpdate = companion.copyWith(
      version: Value(existing.version + 1),
      syncStatus: const Value('pending'),
      updatedAt: Value(DateTime.now()),
    );

    try {
      final count =
          await (update(departments)
                ..where((d) => d.id.equals(id) & d.businessId.equals(busId)))
              .write(toUpdate);
      return count > 0;
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('unique constraint failed')) {
        throw const DuplicateRecordException(
          'Department update violates unique code constraint.',
        );
      } else if (msg.contains('foreign key constraint failed')) {
        throw const ForeignKeyConstraintException(
          'Invalid parentId or managerId reference.',
        );
      }
      rethrow;
    }
  }

  /// Deletes a department physically from the database.
  Future<bool> deleteDepartment(String id, String businessId) async {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'deleteDepartment requires businessId.',
      );
    }
    final existing = await getDepartmentById(id, businessId);
    if (existing == null) {
      throw const RecordNotFoundException('Department not found for deletion.');
    }

    try {
      final count = await (delete(
        departments,
      )..where((d) => d.id.equals(id) & d.businessId.equals(businessId))).go();
      return count > 0;
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('foreign key constraint failed')) {
        throw const ForeignKeyConstraintException(
          'Cannot delete department because it is referenced by employees or child departments.',
        );
      }
      rethrow;
    }
  }

  // ============================================================================
  // 2. JOB TITLES OPERATIONS (Tenant Scoped)
  // ============================================================================

  /// Retrieves a job title by ID within a business.
  Future<JobTitle?> getJobTitleById(String id, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getJobTitleById requires businessId.',
      );
    }
    return (select(jobTitles)
          ..where((j) => j.id.equals(id) & j.businessId.equals(businessId)))
        .getSingleOrNull();
  }

  /// Lists job titles matching the provided filter with pagination.
  Future<List<JobTitle>> listJobTitles(JobTitleFilter filter) {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException('listJobTitles requires businessId.');
    }
    final query = select(jobTitles)
      ..where((j) => j.businessId.equals(filter.businessId));

    if (filter.isActive != null) {
      query.where((j) => j.isActive.equals(filter.isActive!));
    }
    if (filter.searchQuery != null && filter.searchQuery!.trim().isNotEmpty) {
      final q = '%${filter.searchQuery!.trim()}%';
      query.where((j) => j.titleName.like(q));
    }

    query
      ..orderBy([
        (j) => OrderingTerm(expression: j.titleName),
        (j) => OrderingTerm(expression: j.id),
      ])
      ..limit(filter.limit, offset: filter.offset);

    return query.get();
  }

  /// Reactive stream of job titles matching the filter.
  Stream<List<JobTitle>> watchJobTitles(JobTitleFilter filter) {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException('watchJobTitles requires businessId.');
    }
    final query = select(jobTitles)
      ..where((j) => j.businessId.equals(filter.businessId));

    if (filter.isActive != null) {
      query.where((j) => j.isActive.equals(filter.isActive!));
    }
    if (filter.searchQuery != null && filter.searchQuery!.trim().isNotEmpty) {
      final q = '%${filter.searchQuery!.trim()}%';
      query.where((j) => j.titleName.like(q));
    }

    query
      ..orderBy([
        (j) => OrderingTerm(expression: j.titleName),
        (j) => OrderingTerm(expression: j.id),
      ])
      ..limit(filter.limit, offset: filter.offset);

    return query.watch();
  }

  /// Inserts a new job title.
  Future<JobTitle> insertJobTitle(JobTitlesCompanion companion) async {
    final busId = companion.businessId.value;
    if (busId.trim().isEmpty) {
      throw const TenantScopingException('insertJobTitle requires businessId.');
    }

    final toInsert = companion.copyWith(
      syncStatus: companion.syncStatus.present
          ? companion.syncStatus
          : const Value('pending'),
      version: companion.version.present ? companion.version : const Value(1),
      createdAt: companion.createdAt.present
          ? companion.createdAt
          : Value(DateTime.now()),
      updatedAt: companion.updatedAt.present
          ? companion.updatedAt
          : Value(DateTime.now()),
    );

    try {
      final rowId = await into(jobTitles).insert(toInsert);
      final id = companion.id.value;
      final inserted =
          await (select(jobTitles)
                ..where((j) => j.id.equals(id) & j.businessId.equals(busId)))
              .getSingleOrNull();
      if (inserted != null) {
        return inserted;
      }
      return (await (select(
        jobTitles,
      )..where((j) => j.rowId.equals(rowId))).getSingle());
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('unique constraint failed')) {
        throw const DuplicateRecordException(
          'Job title with exact name or id already exists.',
        );
      } else if (msg.contains('foreign key constraint failed')) {
        throw const ForeignKeyConstraintException(
          'Invalid businessId reference for job title.',
        );
      }
      rethrow;
    }
  }

  /// Updates an existing job title.
  Future<bool> updateJobTitle(JobTitlesCompanion companion) async {
    if (!companion.id.present || !companion.businessId.present) {
      throw const TenantScopingException(
        'updateJobTitle requires both id and businessId.',
      );
    }
    final id = companion.id.value;
    final busId = companion.businessId.value;

    final existing = await getJobTitleById(id, busId);
    if (existing == null) {
      throw const RecordNotFoundException('JobTitle not found for update.');
    }

    final toUpdate = companion.copyWith(
      version: Value(existing.version + 1),
      syncStatus: const Value('pending'),
      updatedAt: Value(DateTime.now()),
    );

    try {
      final count =
          await (update(jobTitles)
                ..where((j) => j.id.equals(id) & j.businessId.equals(busId)))
              .write(toUpdate);
      return count > 0;
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('unique constraint failed')) {
        throw const DuplicateRecordException(
          'Job title update violates unique name constraint.',
        );
      }
      rethrow;
    }
  }

  /// Deletes a job title physically from the database.
  Future<bool> deleteJobTitle(String id, String businessId) async {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException('deleteJobTitle requires businessId.');
    }
    final existing = await getJobTitleById(id, businessId);
    if (existing == null) {
      throw const RecordNotFoundException('JobTitle not found for deletion.');
    }

    try {
      final count = await (delete(
        jobTitles,
      )..where((j) => j.id.equals(id) & j.businessId.equals(businessId))).go();
      return count > 0;
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('foreign key constraint failed')) {
        throw const ForeignKeyConstraintException(
          'Cannot delete job title because it is referenced by employees.',
        );
      }
      rethrow;
    }
  }

  // ============================================================================
  // 3. EMPLOYEES OPERATIONS (Tenant Scoped, Soft Delete Support)
  // ============================================================================

  /// Retrieves an employee by ID within a business.
  Future<Employee?> getEmployeeById(
    String id,
    String businessId, {
    bool includeDeleted = false,
  }) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getEmployeeById requires businessId.',
      );
    }
    final query = select(employees)
      ..where((e) => e.id.equals(id) & e.businessId.equals(businessId));
    if (!includeDeleted) {
      query.where((e) => e.deletedAt.isNull());
    }
    return query.getSingleOrNull();
  }

  /// Retrieves an employee by unique employee code within a business.
  Future<Employee?> getEmployeeByCode(
    String employeeCode,
    String businessId, {
    bool includeDeleted = false,
  }) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getEmployeeByCode requires businessId.',
      );
    }
    final query = select(employees)
      ..where(
        (e) =>
            e.employeeCode.equals(employeeCode) &
            e.businessId.equals(businessId),
      );
    if (!includeDeleted) {
      query.where((e) => e.deletedAt.isNull());
    }
    return query.getSingleOrNull();
  }

  /// Retrieves an employee along with their assigned department and job title.
  Future<EmployeeWithDetails?> getEmployeeWithDetails(
    String id,
    String businessId, {
    bool includeDeleted = false,
  }) async {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getEmployeeWithDetails requires businessId.',
      );
    }
    final query = select(employees).join(
      [
        leftOuterJoin(
          departments,
          departments.id.equalsExp(employees.departmentId) &
              departments.businessId.equalsExp(employees.businessId),
        ),
        leftOuterJoin(
          jobTitles,
          jobTitles.id.equalsExp(employees.jobTitleId) &
              jobTitles.businessId.equalsExp(employees.businessId),
        ),
      ],
    )..where(employees.id.equals(id) & employees.businessId.equals(businessId));

    if (!includeDeleted) {
      query.where(employees.deletedAt.isNull());
    }

    final row = await query.getSingleOrNull();
    if (row == null) {
      return null;
    }

    return EmployeeWithDetails(
      employee: row.readTable(employees),
      department: row.readTableOrNull(departments),
      jobTitle: row.readTableOrNull(jobTitles),
    );
  }

  /// Lists employees matching the provided filter with pagination.
  Future<List<Employee>> listEmployees(EmployeeFilter filter) {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException('listEmployees requires businessId.');
    }
    final query = select(employees)
      ..where((e) => e.businessId.equals(filter.businessId));

    if (!filter.includeDeleted) {
      query.where((e) => e.deletedAt.isNull());
    }
    if (filter.departmentId != null) {
      query.where((e) => e.departmentId.equals(filter.departmentId!));
    }
    if (filter.jobTitleId != null) {
      query.where((e) => e.jobTitleId.equals(filter.jobTitleId!));
    }
    if (filter.status != null && filter.status!.trim().isNotEmpty) {
      query.where((e) => e.status.equals(filter.status!.trim()));
    }
    if (filter.searchQuery != null && filter.searchQuery!.trim().isNotEmpty) {
      final q = '%${filter.searchQuery!.trim()}%';
      query.where(
        (e) =>
            e.firstName.like(q) |
            e.lastName.like(q) |
            e.employeeCode.like(q) |
            e.email.like(q),
      );
    }

    query
      ..orderBy([
        (e) => OrderingTerm(expression: e.lastName),
        (e) => OrderingTerm(expression: e.firstName),
        (e) => OrderingTerm(expression: e.id),
      ])
      ..limit(filter.limit, offset: filter.offset);

    return query.get();
  }

  /// Lists composite [EmployeeWithDetails] records matching the provided filter.
  Future<List<EmployeeWithDetails>> listEmployeesWithDetails(
    EmployeeFilter filter,
  ) async {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'listEmployeesWithDetails requires businessId.',
      );
    }
    final query = select(employees).join([
      leftOuterJoin(
        departments,
        departments.id.equalsExp(employees.departmentId) &
            departments.businessId.equalsExp(employees.businessId),
      ),
      leftOuterJoin(
        jobTitles,
        jobTitles.id.equalsExp(employees.jobTitleId) &
            jobTitles.businessId.equalsExp(employees.businessId),
      ),
    ])..where(employees.businessId.equals(filter.businessId));

    if (!filter.includeDeleted) {
      query.where(employees.deletedAt.isNull());
    }
    if (filter.departmentId != null) {
      query.where(employees.departmentId.equals(filter.departmentId!));
    }
    if (filter.jobTitleId != null) {
      query.where(employees.jobTitleId.equals(filter.jobTitleId!));
    }
    if (filter.status != null && filter.status!.trim().isNotEmpty) {
      query.where(employees.status.equals(filter.status!.trim()));
    }
    if (filter.searchQuery != null && filter.searchQuery!.trim().isNotEmpty) {
      final q = '%${filter.searchQuery!.trim()}%';
      query.where(
        employees.firstName.like(q) |
            employees.lastName.like(q) |
            employees.employeeCode.like(q) |
            employees.email.like(q),
      );
    }

    query
      ..orderBy([
        OrderingTerm(expression: employees.lastName),
        OrderingTerm(expression: employees.firstName),
        OrderingTerm(expression: employees.id),
      ])
      ..limit(filter.limit, offset: filter.offset);

    final rows = await query.get();
    return rows.map((row) {
      return EmployeeWithDetails(
        employee: row.readTable(employees),
        department: row.readTableOrNull(departments),
        jobTitle: row.readTableOrNull(jobTitles),
      );
    }).toList();
  }

  /// Reactive stream of employees matching the filter.
  Stream<List<Employee>> watchEmployees(EmployeeFilter filter) {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException('watchEmployees requires businessId.');
    }
    final query = select(employees)
      ..where((e) => e.businessId.equals(filter.businessId));

    if (!filter.includeDeleted) {
      query.where((e) => e.deletedAt.isNull());
    }
    if (filter.departmentId != null) {
      query.where((e) => e.departmentId.equals(filter.departmentId!));
    }
    if (filter.jobTitleId != null) {
      query.where((e) => e.jobTitleId.equals(filter.jobTitleId!));
    }
    if (filter.status != null && filter.status!.trim().isNotEmpty) {
      query.where((e) => e.status.equals(filter.status!.trim()));
    }
    if (filter.searchQuery != null && filter.searchQuery!.trim().isNotEmpty) {
      final q = '%${filter.searchQuery!.trim()}%';
      query.where(
        (e) =>
            e.firstName.like(q) |
            e.lastName.like(q) |
            e.employeeCode.like(q) |
            e.email.like(q),
      );
    }

    query
      ..orderBy([
        (e) => OrderingTerm(expression: e.lastName),
        (e) => OrderingTerm(expression: e.firstName),
        (e) => OrderingTerm(expression: e.id),
      ])
      ..limit(filter.limit, offset: filter.offset);

    return query.watch();
  }

  /// Reactive stream of a single employee by ID.
  Stream<Employee?> watchEmployeeById(
    String id,
    String businessId, {
    bool includeDeleted = false,
  }) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'watchEmployeeById requires businessId.',
      );
    }
    final query = select(employees)
      ..where((e) => e.id.equals(id) & e.businessId.equals(businessId));
    if (!includeDeleted) {
      query.where((e) => e.deletedAt.isNull());
    }
    return query.watchSingleOrNull();
  }

  /// Inserts a new employee record.
  Future<Employee> insertEmployee(EmployeesCompanion companion) async {
    final busId = companion.businessId.value;
    if (busId.trim().isEmpty) {
      throw const TenantScopingException('insertEmployee requires businessId.');
    }

    final toInsert = companion.copyWith(
      syncStatus: companion.syncStatus.present
          ? companion.syncStatus
          : const Value('pending'),
      version: companion.version.present ? companion.version : const Value(1),
      createdAt: companion.createdAt.present
          ? companion.createdAt
          : Value(DateTime.now()),
      updatedAt: companion.updatedAt.present
          ? companion.updatedAt
          : Value(DateTime.now()),
      deletedAt: const Value(null),
    );

    try {
      final rowId = await into(employees).insert(toInsert);
      final id = companion.id.value;
      final inserted =
          await (select(employees)
                ..where((e) => e.id.equals(id) & e.businessId.equals(busId)))
              .getSingleOrNull();
      if (inserted != null) {
        return inserted;
      }
      return (await (select(
        employees,
      )..where((e) => e.rowId.equals(rowId))).getSingle());
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('unique constraint failed')) {
        throw const DuplicateRecordException(
          'Employee with exact id, code, or user assignment already exists.',
        );
      } else if (msg.contains('foreign key constraint failed')) {
        throw const ForeignKeyConstraintException(
          'Invalid businessId, departmentId, jobTitleId, or currencyId reference.',
        );
      } else if (msg.contains('check constraint failed')) {
        throw const LocalDatabaseException(
          'Check constraint violation on employee fields (e.g. termination_date >= hire_date or salary >= 0).',
        );
      }
      rethrow;
    }
  }

  /// Atomically inserts an employee along with their document attachments.
  Future<Employee> insertEmployeeWithDocuments(
    EmployeesCompanion employeeCompanion,
    List<EmployeeDocumentsCompanion> documents,
  ) async {
    final busId = employeeCompanion.businessId.value;
    final empId = employeeCompanion.id.value;
    if (busId.trim().isEmpty || empId.trim().isEmpty) {
      throw const TenantScopingException(
        'insertEmployeeWithDocuments requires businessId and employee id.',
      );
    }

    return transaction(() async {
      final employee = await insertEmployee(employeeCompanion);
      for (final doc in documents) {
        final docToInsert = doc.copyWith(
          businessId: Value(busId),
          employeeId: Value(employee.id),
        );
        await insertDocument(docToInsert);
      }
      return employee;
    });
  }

  /// Updates an existing employee record.
  Future<bool> updateEmployee(EmployeesCompanion companion) async {
    if (!companion.id.present || !companion.businessId.present) {
      throw const TenantScopingException(
        'updateEmployee requires both id and businessId.',
      );
    }
    final id = companion.id.value;
    final busId = companion.businessId.value;

    final existing = await getEmployeeById(id, busId, includeDeleted: true);
    if (existing == null) {
      throw const RecordNotFoundException('Employee not found for update.');
    }

    final toUpdate = companion.copyWith(
      version: Value(existing.version + 1),
      syncStatus: const Value('pending'),
      updatedAt: Value(DateTime.now()),
    );

    try {
      final count =
          await (update(employees)
                ..where((e) => e.id.equals(id) & e.businessId.equals(busId)))
              .write(toUpdate);
      return count > 0;
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('unique constraint failed')) {
        throw const DuplicateRecordException(
          'Employee update violates unique constraint.',
        );
      } else if (msg.contains('foreign key constraint failed')) {
        throw const ForeignKeyConstraintException(
          'Invalid departmentId, jobTitleId, or currencyId.',
        );
      } else if (msg.contains('check constraint failed')) {
        throw const LocalDatabaseException(
          'Check constraint violation on employee fields.',
        );
      }
      rethrow;
    }
  }

  /// Soft deletes an employee by setting [deletedAt].
  Future<bool> softDeleteEmployee(String id, String businessId) async {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'softDeleteEmployee requires businessId.',
      );
    }
    final existing = await getEmployeeById(id, businessId);
    if (existing == null) {
      throw const RecordNotFoundException(
        'Active employee not found for soft deletion.',
      );
    }

    final count =
        await (update(employees)
              ..where((e) => e.id.equals(id) & e.businessId.equals(businessId)))
            .write(
              EmployeesCompanion(
                deletedAt: Value(DateTime.now()),
                syncStatus: const Value('pending_delete'),
                version: Value(existing.version + 1),
                updatedAt: Value(DateTime.now()),
              ),
            );
    return count > 0;
  }

  /// Restores a soft-deleted employee record.
  Future<bool> restoreEmployee(String id, String businessId) async {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'restoreEmployee requires businessId.',
      );
    }
    final existing = await getEmployeeById(
      id,
      businessId,
      includeDeleted: true,
    );
    if (existing == null || existing.deletedAt == null) {
      throw const RecordNotFoundException(
        'Soft-deleted employee not found for restoration.',
      );
    }

    final count =
        await (update(employees)
              ..where((e) => e.id.equals(id) & e.businessId.equals(businessId)))
            .write(
              EmployeesCompanion(
                deletedAt: const Value(null),
                syncStatus: const Value('pending'),
                version: Value(existing.version + 1),
                updatedAt: Value(DateTime.now()),
              ),
            );
    return count > 0;
  }

  // ============================================================================
  // 4. EMPLOYEE DOCUMENTS OPERATIONS (Tenant Scoped)
  // ============================================================================

  /// Retrieves an employee document by ID within a business.
  Future<EmployeeDocument?> getDocumentById(String id, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getDocumentById requires businessId.',
      );
    }
    return (select(employeeDocuments)
          ..where((d) => d.id.equals(id) & d.businessId.equals(businessId)))
        .getSingleOrNull();
  }

  /// Lists documents belonging to a specific employee within a business.
  Future<List<EmployeeDocument>> listDocumentsByEmployeeId(
    String employeeId,
    String businessId,
  ) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'listDocumentsByEmployeeId requires businessId.',
      );
    }
    return (select(employeeDocuments)
          ..where(
            (d) =>
                d.employeeId.equals(employeeId) &
                d.businessId.equals(businessId),
          )
          ..orderBy([
            (d) =>
                OrderingTerm(expression: d.createdAt, mode: OrderingMode.desc),
            (d) => OrderingTerm(expression: d.id),
          ]))
        .get();
  }

  /// Lists documents matching the provided filter with pagination.
  Future<List<EmployeeDocument>> listDocuments(EmployeeDocumentFilter filter) {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException('listDocuments requires businessId.');
    }
    final query = select(employeeDocuments)
      ..where((d) => d.businessId.equals(filter.businessId));

    if (filter.employeeId != null) {
      query.where((d) => d.employeeId.equals(filter.employeeId!));
    }
    if (filter.documentType != null && filter.documentType!.trim().isNotEmpty) {
      query.where((d) => d.documentType.equals(filter.documentType!.trim()));
    }

    query
      ..orderBy([
        (d) => OrderingTerm(expression: d.createdAt, mode: OrderingMode.desc),
        (d) => OrderingTerm(expression: d.id),
      ])
      ..limit(filter.limit, offset: filter.offset);

    return query.get();
  }

  /// Inserts a new employee document record.
  Future<EmployeeDocument> insertDocument(
    EmployeeDocumentsCompanion companion,
  ) async {
    final busId = companion.businessId.value;
    if (busId.trim().isEmpty) {
      throw const TenantScopingException('insertDocument requires businessId.');
    }

    final toInsert = companion.copyWith(
      syncStatus: companion.syncStatus.present
          ? companion.syncStatus
          : const Value('pending'),
      version: companion.version.present ? companion.version : const Value(1),
      createdAt: companion.createdAt.present
          ? companion.createdAt
          : Value(DateTime.now()),
      updatedAt: companion.updatedAt.present
          ? companion.updatedAt
          : Value(DateTime.now()),
    );

    try {
      final rowId = await into(employeeDocuments).insert(toInsert);
      final id = companion.id.value;
      final inserted =
          await (select(employeeDocuments)
                ..where((d) => d.id.equals(id) & d.businessId.equals(busId)))
              .getSingleOrNull();
      if (inserted != null) {
        return inserted;
      }
      return (await (select(
        employeeDocuments,
      )..where((d) => d.rowId.equals(rowId))).getSingle());
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('unique constraint failed')) {
        throw const DuplicateRecordException('Document ID already exists.');
      } else if (msg.contains('foreign key constraint failed')) {
        throw const ForeignKeyConstraintException(
          'Invalid employeeId or businessId reference for document.',
        );
      }
      rethrow;
    }
  }

  /// Updates an existing employee document record.
  Future<bool> updateDocument(EmployeeDocumentsCompanion companion) async {
    if (!companion.id.present || !companion.businessId.present) {
      throw const TenantScopingException(
        'updateDocument requires both id and businessId.',
      );
    }
    final id = companion.id.value;
    final busId = companion.businessId.value;

    final existing = await getDocumentById(id, busId);
    if (existing == null) {
      throw const RecordNotFoundException(
        'EmployeeDocument not found for update.',
      );
    }

    final toUpdate = companion.copyWith(
      version: Value(existing.version + 1),
      syncStatus: const Value('pending'),
      updatedAt: Value(DateTime.now()),
    );

    try {
      final count =
          await (update(employeeDocuments)
                ..where((d) => d.id.equals(id) & d.businessId.equals(busId)))
              .write(toUpdate);
      return count > 0;
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('foreign key constraint failed')) {
        throw const ForeignKeyConstraintException(
          'Invalid employeeId reference.',
        );
      }
      rethrow;
    }
  }

  /// Deletes an employee document physically from the database.
  Future<bool> deleteDocument(String id, String businessId) async {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException('deleteDocument requires businessId.');
    }
    final existing = await getDocumentById(id, businessId);
    if (existing == null) {
      throw const RecordNotFoundException(
        'EmployeeDocument not found for deletion.',
      );
    }

    final count = await (delete(
      employeeDocuments,
    )..where((d) => d.id.equals(id) & d.businessId.equals(businessId))).go();
    return count > 0;
  }

  // ============================================================================
  // 5. OFFLINE-FIRST SYNCHRONIZATION HELPERS
  // ============================================================================

  /// Retrieves all [Departments] records currently pending synchronization.
  Future<List<Department>> getPendingSyncDepartments(String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getPendingSyncDepartments requires businessId.',
      );
    }
    return (select(departments)..where(
          (d) =>
              d.businessId.equals(businessId) &
              d.syncStatus.isNotValue('synced'),
        ))
        .get();
  }

  /// Marks a [Department] record as successfully synchronized.
  Future<bool> markDepartmentAsSynced(String id, String businessId) async {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'markDepartmentAsSynced requires businessId.',
      );
    }
    final count =
        await (update(departments)
              ..where((d) => d.id.equals(id) & d.businessId.equals(businessId)))
            .write(const DepartmentsCompanion(syncStatus: Value('synced')));
    return count > 0;
  }

  /// Retrieves all [JobTitles] records currently pending synchronization.
  Future<List<JobTitle>> getPendingSyncJobTitles(String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getPendingSyncJobTitles requires businessId.',
      );
    }
    return (select(jobTitles)..where(
          (j) =>
              j.businessId.equals(businessId) &
              j.syncStatus.isNotValue('synced'),
        ))
        .get();
  }

  /// Marks a [JobTitle] record as successfully synchronized.
  Future<bool> markJobTitleAsSynced(String id, String businessId) async {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'markJobTitleAsSynced requires businessId.',
      );
    }
    final count =
        await (update(jobTitles)
              ..where((j) => j.id.equals(id) & j.businessId.equals(businessId)))
            .write(const JobTitlesCompanion(syncStatus: Value('synced')));
    return count > 0;
  }

  /// Retrieves all [Employees] records currently pending synchronization.
  Future<List<Employee>> getPendingSyncEmployees(String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getPendingSyncEmployees requires businessId.',
      );
    }
    return (select(employees)..where(
          (e) =>
              e.businessId.equals(businessId) &
              e.syncStatus.isNotValue('synced'),
        ))
        .get();
  }

  /// Marks an [Employee] record as successfully synchronized.
  Future<bool> markEmployeeAsSynced(String id, String businessId) async {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'markEmployeeAsSynced requires businessId.',
      );
    }
    final count =
        await (update(employees)
              ..where((e) => e.id.equals(id) & e.businessId.equals(businessId)))
            .write(const EmployeesCompanion(syncStatus: Value('synced')));
    return count > 0;
  }

  /// Retrieves all [EmployeeDocuments] records currently pending synchronization.
  Future<List<EmployeeDocument>> getPendingSyncEmployeeDocuments(
    String businessId,
  ) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getPendingSyncEmployeeDocuments requires businessId.',
      );
    }
    return (select(employeeDocuments)..where(
          (d) =>
              d.businessId.equals(businessId) &
              d.syncStatus.isNotValue('synced'),
        ))
        .get();
  }

  /// Marks an [EmployeeDocument] record as successfully synchronized.
  Future<bool> markEmployeeDocumentAsSynced(
    String id,
    String businessId,
  ) async {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'markEmployeeDocumentAsSynced requires businessId.',
      );
    }
    final count =
        await (update(employeeDocuments)
              ..where((d) => d.id.equals(id) & d.businessId.equals(businessId)))
            .write(
              const EmployeeDocumentsCompanion(syncStatus: Value('synced')),
            );
    return count > 0;
  }
}
