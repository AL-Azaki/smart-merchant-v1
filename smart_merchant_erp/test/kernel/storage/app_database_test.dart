import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:smart_merchant_erp/kernel/storage/app_database.dart';
import 'package:smart_merchant_erp/database/enums/print_paper_size.dart';
import 'package:smart_merchant_erp/database/enums/sequence_reset_frequency.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(connection: NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  group('Drift ORM Foundation Test Suite (72 Domain Tables) -', () {
    test('Test A: Database Initialization & Schema Creation', () async {
      expect(database, isNotNull);
      expect(database.schemaVersion, equals(5));

      // Verify tables across all 10 domains can be queried cleanly without 'no such table' errors
      final businesses = await database.select(database.businesses).get();
      expect(businesses, isEmpty);

      final customers = await database.select(database.customers).get();
      expect(customers, isEmpty);

      final products = await database.select(database.products).get();
      expect(products, isEmpty);

      final currencies = await database.select(database.currencies).get();
      expect(currencies.isNotEmpty, isTrue);

      final invoices = await database.select(database.salesInvoices).get();
      expect(invoices, isEmpty);
    });

    test('Test B: Basic CRUD & Data Type Verification', () async {
      // 1. Insert a Currency (Core Domain)
      final currencyId = 'SAR';
      

      // 2. Read back
      var fetchedCurr = await (database.select(
        database.currencies,
      )..where((tbl) => tbl.id.equals(currencyId))).getSingle();
      expect(fetchedCurr.currencyCode, equals('SAR'));
      expect(fetchedCurr.currencyNameAr, equals('ريال سعودي'));
      expect(fetchedCurr.exchangeRate, equals(1.0));

      // 3. Update
      await (database.update(
        database.currencies,
      )..where((tbl) => tbl.id.equals(currencyId))).write(
        CurrenciesCompanion(
          currencyNameAr: const drift.Value('ريال سعودي محدث'),
          exchangeRate: const drift.Value(3.75),
        ),
      );

      fetchedCurr = await (database.select(
        database.currencies,
      )..where((tbl) => tbl.id.equals(currencyId))).getSingle();
      expect(fetchedCurr.currencyNameAr, equals('ريال سعودي محدث'));
      expect(fetchedCurr.exchangeRate, equals(3.75));

      // 4. Soft Delete verification on a Business entity
      await database
          .into(database.usersTable)
          .insert(
            UsersTableCompanion.insert(
              id: const drift.Value('user-owner-1'),
              email: 'owner@merchant.com',
              passwordHash: 'hash123',
              firstName: 'Bashir',
              lastName: 'Alazaki',
            ),
          );
      await database
          .into(database.accountsTable)
          .insert(
            AccountsTableCompanion.insert(
              id: const drift.Value('acc-1'),
              ownerId: 'user-owner-1',
              businessName: 'Main Enterprise',
              businessType: 'Retail',
              defaultCurrency: 'SAR',
            ),
          );
      await database
          .into(database.businesses)
          .insert(
            BusinessesCompanion.insert(
              id: 'biz-test-1',
              accountId: 'acc-1',
              businessName: 'Main Branch Business',
            ),
          );

      // Perform soft delete by setting deletedAt
      final now = DateTime.now();
      await (database.update(database.businesses)
            ..where((tbl) => tbl.id.equals('biz-test-1')))
          .write(BusinessesCompanion(deletedAt: drift.Value(now)));

      final deletedBiz = await (database.select(
        database.businesses,
      )..where((tbl) => tbl.id.equals('biz-test-1'))).getSingle();
      expect(deletedBiz.deletedAt, isNotNull);
    });

    test(
      'Test C: Multi-Tenant Scoping Verification (business_id isolation)',
      () async {
        // Create Base Users and Accounts
        await database
            .into(database.usersTable)
            .insert(
              UsersTableCompanion.insert(
                id: const drift.Value('u-owner-a'),
                email: 'a@biz.com',
                passwordHash: 'pass',
                firstName: 'A',
                lastName: 'Owner',
              ),
            );
        await database
            .into(database.accountsTable)
            .insert(
              AccountsTableCompanion.insert(
                id: const drift.Value('acc-a'),
                ownerId: 'u-owner-a',
                businessName: 'Account A',
                businessType: 'Retail',
                defaultCurrency: 'SAR',
              ),
            );
        await database
            .into(database.accountsTable)
            .insert(
              AccountsTableCompanion.insert(
                id: const drift.Value('acc-b'),
                ownerId: 'u-owner-a',
                businessName: 'Account B',
                businessType: 'Wholesale',
                defaultCurrency: 'SAR',
              ),
            );

        // Create two independent businesses (tenants)
        final bizA = 'biz-tenant-a';
        final bizB = 'biz-tenant-b';
        await database
            .into(database.businesses)
            .insert(
              BusinessesCompanion.insert(
                id: bizA,
                accountId: 'acc-a',
                businessName: 'Store Alpha',
              ),
            );
        await database
            .into(database.businesses)
            .insert(
              BusinessesCompanion.insert(
                id: bizB,
                accountId: 'acc-b',
                businessName: 'Store Beta',
              ),
            );

        // Insert customers scoped to Biz A
        await database
            .into(database.customers)
            .insert(
              CustomersCompanion.insert(
                id: 'cust-a1',
                businessId: bizA,
                customerName: 'Customer Alpha 1',
              ),
            );
        await database
            .into(database.customers)
            .insert(
              CustomersCompanion.insert(
                id: 'cust-a2',
                businessId: bizA,
                customerName: 'Customer Alpha 2',
              ),
            );

        // Insert customer scoped to Biz B
        await database
            .into(database.customers)
            .insert(
              CustomersCompanion.insert(
                id: 'cust-b1',
                businessId: bizB,
                customerName: 'Customer Beta 1',
              ),
            );

        // Verify scoping: querying businessId == bizA returns only Alpha customers
        final alphaCustomers = await (database.select(
          database.customers,
        )..where((tbl) => tbl.businessId.equals(bizA))).get();
        expect(alphaCustomers.length, equals(2));
        expect(
          alphaCustomers.map((e) => e.customerName),
          containsAll(['Customer Alpha 1', 'Customer Alpha 2']),
        );
        expect(
          alphaCustomers.map((e) => e.customerName),
          isNot(contains('Customer Beta 1')),
        );

        // Verify scoping: querying businessId == bizB returns only Beta customer
        final betaCustomers = await (database.select(
          database.customers,
        )..where((tbl) => tbl.businessId.equals(bizB))).get();
        expect(betaCustomers.length, equals(1));
        expect(betaCustomers.first.customerName, equals('Customer Beta 1'));
      },
    );

    test('Test D: Foreign Key Enforcement Verification', () async {
      // Attempt to insert a customer referencing a non-existent business_id
      expect(
        () async => await database
            .into(database.customers)
            .insert(
              CustomersCompanion.insert(
                id: 'orphan-cust',
                businessId: 'non-existent-biz-id-999',
                customerName: 'Orphan Customer',
              ),
            ),
        throwsA(
          isA<sqlite.SqliteException>().having(
            (e) => e.message.toLowerCase(),
            'message',
            contains('foreign key constraint failed'),
          ),
        ),
      );
    });

    test(
      'Test E: Offline-First Metadata & Composite Unique Key Verification',
      () async {
        // Setup parent user, account, business, and two branches
        await database
            .into(database.usersTable)
            .insert(
              UsersTableCompanion.insert(
                id: const drift.Value('u-sync'),
                email: 'sync@store.com',
                passwordHash: 'hash',
                firstName: 'Sync',
                lastName: 'Tester',
              ),
            );
        await database
            .into(database.accountsTable)
            .insert(
              AccountsTableCompanion.insert(
                id: const drift.Value('acc-sync'),
                ownerId: 'u-sync',
                businessName: 'Sync Account',
                businessType: 'POS',
                defaultCurrency: 'SAR',
              ),
            );
        final bizId = 'biz-sync-01';
        await database
            .into(database.businesses)
            .insert(
              BusinessesCompanion.insert(
                id: bizId,
                accountId: 'acc-sync',
                businessName: 'Sync Store',
              ),
            );
        

        final branchA = 'branch-a';
        final branchB = 'branch-b';
        await database
            .into(database.branches)
            .insert(
              BranchesCompanion.insert(
                id: branchA,
                businessId: bizId,
                branchName: 'Main POS Branch',
                branchCode: 'BR-A',
              ),
            );
        await database
            .into(database.branches)
            .insert(
              BranchesCompanion.insert(
                id: branchB,
                businessId: bizId,
                branchName: 'Mobile POS Branch',
                branchCode: 'BR-B',
              ),
            );

        // Verify offline sync metadata defaults
        await database
            .into(database.customers)
            .insert(
              CustomersCompanion.insert(
                id: 'cust-sync-verify',
                businessId: bizId,
                customerName: 'Offline Customer',
                deviceId: const drift.Value('POS-DEVICE-01'),
              ),
            );
        final cust = await (database.select(
          database.customers,
        )..where((tbl) => tbl.id.equals('cust-sync-verify'))).getSingle();
        expect(cust.syncStatus, equals('pending'));
        expect(cust.version, equals(1));
        expect(cust.deviceId, equals('POS-DEVICE-01'));

        // Verify composite unique key on SalesInvoices: (businessId, branchId, invoiceNumber)
        await database
            .into(database.salesInvoices)
            .insert(
              SalesInvoicesCompanion.insert(
                id: 'inv-a-1001',
                businessId: bizId,
                branchId: branchA,
                invoiceNumber: 'INV-0001',
                currencyId: 'SAR',
                createdBy: 'u-sync',
              ),
            );

        // Inserting the exact same invoiceNumber in the same business and branch MUST fail unique check
        expect(
          () async => await database
              .into(database.salesInvoices)
              .insert(
                SalesInvoicesCompanion.insert(
                  id: 'inv-a-duplicate',
                  businessId: bizId,
                  branchId: branchA,
                  invoiceNumber: 'INV-0001',
                  currencyId: 'SAR',
                  createdBy: 'u-sync',
                ),
              ),
          throwsA(
            isA<sqlite.SqliteException>().having(
              (e) => e.message.toLowerCase(),
              'message',
              contains('unique constraint failed'),
            ),
          ),
        );

        // BUT inserting the SAME invoice number 'INV-0001' under Branch B MUST succeed!
        // This proves our critical offline-first branch isolation constraint fix works!
        await database
            .into(database.salesInvoices)
            .insert(
              SalesInvoicesCompanion.insert(
                id: 'inv-b-1001',
                businessId: bizId,
                branchId: branchB,
                invoiceNumber: 'INV-0001',
                currencyId: 'SAR',
                createdBy: 'u-sync',
              ),
            );
        final invoices = await (database.select(
          database.salesInvoices,
        )..where((tbl) => tbl.invoiceNumber.equals('INV-0001'))).get();
        expect(invoices.length, equals(2));
        expect(
          invoices.map((e) => e.branchId),
          containsAll([branchA, branchB]),
        );
      },
    );
  });
}
