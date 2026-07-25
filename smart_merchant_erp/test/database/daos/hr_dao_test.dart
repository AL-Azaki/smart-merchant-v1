import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:smart_merchant_erp/kernel/storage/app_database.dart';
import 'package:smart_merchant_erp/database/daos/hr_dao.dart';
import 'package:smart_merchant_erp/database/daos/dao_exceptions.dart';

void main() {
  late AppDatabase database;
  late HrDao hrDao;

  setUp(() async {
    database = AppDatabase(connection: NativeDatabase.memory());
    hrDao = HrDao(database);

    // Seed required parent User, Account, Businesses, Branches, and Currencies
    await database
        .into(database.usersTable)
        .insert(
          UsersTableCompanion.insert(
            id: const drift.Value('u-owner'),
            email: 'owner@hr.com',
            passwordHash: 'hash',
            firstName: 'HR',
            lastName: 'Admin',
          ),
        );
    await database
        .into(database.accountsTable)
        .insert(
          AccountsTableCompanion.insert(
            id: const drift.Value('acc-hr-01'),
            ownerId: 'u-owner',
            businessName: 'HR Enterprise',
            businessType: 'Enterprise',
            defaultCurrency: 'SAR',
          ),
        );
    await database
        .into(database.businesses)
        .insert(
          BusinessesCompanion.insert(
            id: 'BUS_A',
            accountId: 'acc-hr-01',
            businessName: 'Business Alpha',
          ),
        );
    await database
        .into(database.businesses)
        .insert(
          BusinessesCompanion.insert(
            id: 'BUS_B',
            accountId: 'acc-hr-01',
            businessName: 'Business Beta',
          ),
        );
    await database
        .into(database.branches)
        .insert(
          BranchesCompanion.insert(
            id: 'BRANCH_1',
            businessId: 'BUS_A',
            branchName: 'Main Branch Alpha',
            branchCode: 'BR-A1',
            isDefault: const drift.Value(true),
          ),
        );
    await database
        .into(database.branches)
        .insert(
          BranchesCompanion.insert(
            id: 'BRANCH_2',
            businessId: 'BUS_A',
            branchName: 'Sub Branch Alpha',
            branchCode: 'BR-A2',
            isDefault: const drift.Value(false),
          ),
        );
    await database
        .into(database.currencies)
        .insert(
          CurrenciesCompanion.insert(
            id: 'curr-sar',
            currencyCode: 'SAR',
            currencyNameAr: 'ريال سعودي',
            currencyNameEn: 'Saudi Riyal',
            currencySymbol: 'SAR',
            decimalPlaces: const drift.Value(2),
            exchangeRate: const drift.Value(1.0),
            isBaseCurrency: const drift.Value(true),
          ),
        );
  });

  tearDown(() async {
    await database.close();
  });

  group('HrDao Phase 08 Test Suite -', () {
    test(
      '1. Core CRUD & Hierarchy: Departments, JobTitles, Employees, EmployeeDocuments',
      () async {
        // 1. Departments CRUD and Tree Hierarchy
        await hrDao.insertDepartment(
          DepartmentsCompanion.insert(
            id: 'dept-exec',
            businessId: 'BUS_A',
            departmentName: 'Executive Department',
            departmentCode: const drift.Value('EXEC'),
          ),
        );
        await hrDao.insertDepartment(
          DepartmentsCompanion.insert(
            id: 'dept-tech',
            businessId: 'BUS_A',
            departmentName: 'Technology & Engineering',
            departmentCode: const drift.Value('TECH'),
            parentId: const drift.Value('dept-exec'),
          ),
        );

        final dept = await hrDao.getDepartmentById('dept-exec', 'BUS_A');
        expect(dept, isNotNull);
        expect(dept!.departmentName, equals('Executive Department'));

        final tree = await hrDao.getDepartmentTree('BUS_A');
        expect(tree.length, equals(1)); // Only root 'dept-exec' is at top level
        expect(tree.first.department.id, equals('dept-exec'));
        expect(tree.first.children.length, equals(1));
        expect(tree.first.children.first.department.id, equals('dept-tech'));

        // 2. JobTitles CRUD
        await hrDao.insertJobTitle(
          JobTitlesCompanion.insert(
            id: 'jt-dev',
            businessId: 'BUS_A',
            titleName: 'Senior Software Engineer',
            description: const drift.Value('Lead developer'),
          ),
        );

        final jt = await hrDao.getJobTitleById('jt-dev', 'BUS_A');
        expect(jt, isNotNull);
        expect(jt!.titleName, equals('Senior Software Engineer'));

        // 3. Employees CRUD, Composite details, & Soft Delete
        await hrDao.insertEmployee(
          EmployeesCompanion.insert(
            id: 'emp-1',
            businessId: 'BUS_A',
            employeeCode: 'EMP-001',
            firstName: 'John',
            lastName: 'Doe',
            email: const drift.Value('john.doe@company.com'),
            hireDate: DateTime(2025, 1, 15),
            departmentId: const drift.Value('dept-tech'),
            jobTitleId: const drift.Value('jt-dev'),
            salary: const drift.Value(15000.0),
            currencyId: 'curr-sar',
          ),
        );

        final emp = await hrDao.getEmployeeByCode('EMP-001', 'BUS_A');
        expect(emp, isNotNull);
        expect(emp!.firstName, equals('John'));
        expect(emp.salary, equals(15000.0));

        final empDetails = await hrDao.getEmployeeWithDetails('emp-1', 'BUS_A');
        expect(empDetails, isNotNull);
        expect(
          empDetails!.department?.departmentName,
          equals('Technology & Engineering'),
        );
        expect(
          empDetails.jobTitle?.titleName,
          equals('Senior Software Engineer'),
        );

        // Update Employee
        await hrDao.updateEmployee(
          const EmployeesCompanion(
            id: drift.Value('emp-1'),
            businessId: drift.Value('BUS_A'),
            salary: drift.Value(16500.0),
          ),
        );
        final updatedEmp = await hrDao.getEmployeeById('emp-1', 'BUS_A');
        expect(updatedEmp!.salary, equals(16500.0));
        expect(updatedEmp.version, equals(2));

        // Soft Delete & Restore
        await hrDao.softDeleteEmployee('emp-1', 'BUS_A');
        expect(await hrDao.getEmployeeById('emp-1', 'BUS_A'), isNull);
        expect(
          await hrDao.getEmployeeById('emp-1', 'BUS_A', includeDeleted: true),
          isNotNull,
        );

        await hrDao.restoreEmployee('emp-1', 'BUS_A');
        expect(await hrDao.getEmployeeById('emp-1', 'BUS_A'), isNotNull);

        // 4. EmployeeDocuments CRUD
        await hrDao.insertDocument(
          EmployeeDocumentsCompanion.insert(
            id: 'doc-1',
            businessId: 'BUS_A',
            employeeId: 'emp-1',
            documentType: 'National ID',
            documentNumber: const drift.Value('1029384756'),
            filePath: '/documents/id_001.pdf',
          ),
        );

        final docs = await hrDao.listDocumentsByEmployeeId('emp-1', 'BUS_A');
        expect(docs.length, equals(1));
        expect(docs.first.documentType, equals('National ID'));
        expect(docs.first.filePath, equals('/documents/id_001.pdf'));
      },
    );

    test(
      '2. Tenant Isolation: BUS_A queries never return BUS_B records and throwing on empty businessId',
      () async {
        await hrDao.insertDepartment(
          DepartmentsCompanion.insert(
            id: 'dept-bus-a',
            businessId: 'BUS_A',
            departmentName: 'Alpha HR',
          ),
        );
        await hrDao.insertDepartment(
          DepartmentsCompanion.insert(
            id: 'dept-bus-b',
            businessId: 'BUS_B',
            departmentName: 'Beta HR',
          ),
        );

        final listA = await hrDao.listDepartments(
          const DepartmentFilter(businessId: 'BUS_A'),
        );
        expect(listA.any((d) => d.id == 'dept-bus-b'), isFalse);
        expect(listA.any((d) => d.id == 'dept-bus-a'), isTrue);

        final listB = await hrDao.listDepartments(
          const DepartmentFilter(businessId: 'BUS_B'),
        );
        expect(listB.any((d) => d.id == 'dept-bus-a'), isFalse);
        expect(listB.any((d) => d.id == 'dept-bus-b'), isTrue);

        expect(
          () => hrDao.getDepartmentById('dept-bus-a', ''),
          throwsA(isA<TenantScopingException>()),
        );
        expect(
          () => hrDao.listDepartments(const DepartmentFilter(businessId: '')),
          throwsA(isA<TenantScopingException>()),
        );
      },
    );

    test(
      '3. Scoping & Filtering: department, jobTitle, status, and search filters work accurately',
      () async {
        await hrDao.insertDepartment(
          DepartmentsCompanion.insert(
            id: 'd1',
            businessId: 'BUS_A',
            departmentName: 'Sales Dept',
          ),
        );
        await hrDao.insertDepartment(
          DepartmentsCompanion.insert(
            id: 'd2',
            businessId: 'BUS_A',
            departmentName: 'Support Dept',
          ),
        );
        await hrDao.insertJobTitle(
          JobTitlesCompanion.insert(
            id: 'j1',
            businessId: 'BUS_A',
            titleName: 'Rep',
          ),
        );

        await hrDao.insertEmployee(
          EmployeesCompanion.insert(
            id: 'e1',
            businessId: 'BUS_A',
            employeeCode: 'E-101',
            firstName: 'Alice',
            lastName: 'Smith',
            hireDate: DateTime(2026, 2, 10),
            departmentId: const drift.Value('d1'),
            jobTitleId: const drift.Value('j1'),
            currencyId: 'curr-sar',
          ),
        );
        await hrDao.insertEmployee(
          EmployeesCompanion.insert(
            id: 'e2',
            businessId: 'BUS_A',
            employeeCode: 'E-102',
            firstName: 'Bob',
            lastName: 'Brown',
            hireDate: DateTime(2026, 3, 15),
            departmentId: const drift.Value('d2'),
            status: const drift.Value('OnLeave'),
            currencyId: 'curr-sar',
          ),
        );

        final salesEmps = await hrDao.listEmployees(
          const EmployeeFilter(businessId: 'BUS_A', departmentId: 'd1'),
        );
        expect(salesEmps.length, equals(1));
        expect(salesEmps.first.firstName, equals('Alice'));

        final onLeaveEmps = await hrDao.listEmployees(
          const EmployeeFilter(businessId: 'BUS_A', status: 'OnLeave'),
        );
        expect(onLeaveEmps.length, equals(1));
        expect(onLeaveEmps.first.firstName, equals('Bob'));

        final searchEmps = await hrDao.listEmployees(
          const EmployeeFilter(businessId: 'BUS_A', searchQuery: 'E-102'),
        );
        expect(searchEmps.length, equals(1));
        expect(searchEmps.first.id, equals('e2'));
      },
    );

    test(
      '4. Atomic Transactional Integrity: insertEmployeeWithDocuments rolls back completely on document failure',
      () async {
        await hrDao.insertDepartment(
          DepartmentsCompanion.insert(
            id: 'dept-atomic',
            businessId: 'BUS_A',
            departmentName: 'Atomic Dept',
          ),
        );

        // Insert a preexisting employee and a document with id 'doc-exist'
        await hrDao.insertEmployee(
          EmployeesCompanion.insert(
            id: 'emp-preexisting',
            businessId: 'BUS_A',
            employeeCode: 'EMP-PRE',
            firstName: 'Pre',
            lastName: 'Existing',
            hireDate: DateTime(2026, 4, 12),
            currencyId: 'curr-sar',
          ),
        );
        await hrDao.insertDocument(
          EmployeeDocumentsCompanion.insert(
            id: 'doc-exist',
            businessId: 'BUS_A',
            employeeId: 'emp-preexisting',
            documentType: 'Old Doc',
            filePath: '/old.pdf',
          ),
        );

        expect(
          () => hrDao.insertEmployeeWithDocuments(
            EmployeesCompanion.insert(
              id: 'emp-atomic-new',
              businessId: 'BUS_A',
              employeeCode: 'EMP-999',
              firstName: 'Atomic',
              lastName: 'Rollback',
              hireDate: DateTime(2026, 5, 20),
              currencyId: 'curr-sar',
            ),
            [
              EmployeeDocumentsCompanion.insert(
                id: 'doc-valid',
                businessId: 'BUS_A',
                employeeId: 'emp-atomic-new',
                documentType: 'Resume',
                filePath: '/resume.pdf',
              ),
              EmployeeDocumentsCompanion.insert(
                id: 'doc-exist', // Duplicate ID causes DuplicateRecordException
                businessId: 'BUS_A',
                employeeId: 'emp-atomic-new',
                documentType: 'Passport',
                filePath: '/passport.pdf',
              ),
            ],
          ),
          throwsA(isA<DuplicateRecordException>()),
        );

        // Verify rollback: 'emp-atomic-new' and 'doc-valid' should NOT exist
        final empAfterFail = await hrDao.getEmployeeById(
          'emp-atomic-new',
          'BUS_A',
        );
        expect(empAfterFail, isNull);

        final docAfterFail = await hrDao.getDocumentById('doc-valid', 'BUS_A');
        expect(docAfterFail, isNull);
      },
    );

    test('5. Offline-First Sync Flag Management', () async {
      await hrDao.insertDepartment(
        DepartmentsCompanion.insert(
          id: 'dept-sync-1',
          businessId: 'BUS_A',
          departmentName: 'Sync Dept',
        ),
      );

      final pendingDepts = await hrDao.getPendingSyncDepartments('BUS_A');
      expect(pendingDepts.any((d) => d.id == 'dept-sync-1'), isTrue);

      await hrDao.markDepartmentAsSynced('dept-sync-1', 'BUS_A');
      final afterSyncDepts = await hrDao.getPendingSyncDepartments('BUS_A');
      expect(afterSyncDepts.any((d) => d.id == 'dept-sync-1'), isFalse);
    });

    test(
      '6. Reactive Stream Emittance: watchEmployeeById and watchDepartments emit updates',
      () async {
        await hrDao.insertDepartment(
          DepartmentsCompanion.insert(
            id: 'dept-stream',
            businessId: 'BUS_A',
            departmentName: 'Stream Dept',
          ),
        );

        final stream = hrDao.watchDepartments(
          const DepartmentFilter(businessId: 'BUS_A'),
        );
        final expectation = expectLater(
          stream.map((list) => list.length),
          emitsInOrder([1, 2]),
        );

        await Future<void>.delayed(const Duration(milliseconds: 50));
        await hrDao.insertDepartment(
          DepartmentsCompanion.insert(
            id: 'dept-stream-2',
            businessId: 'BUS_A',
            departmentName: 'Stream Dept 2',
          ),
        );

        await expectation;
      },
    );
  });
}
