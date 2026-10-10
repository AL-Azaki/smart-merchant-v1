# 📦 PHASE 7: المزامنة الأوفلاين وجسر المتجر الإلكتروني الخفيف
## (Offline-First Sync Engine, Outbox Pattern & Online Store Bridge)

---

## 1. أهداف المرحلة والمخرجات الفنية (Phase Objectives)
1. بناء معمارية **المزامنة غير المتزامنة (Outbox Pattern)** في Drift لضمان عمل التطبيق بدون إنترنت بنسبة 100%.
2. معالجة سياسة **فض النزاعات وتصادم الأرقام (Conflict Resolution Policy)**.
3. بناء **جسر المتجر الإلكتروني الخفيف (Lightweight Online Store Bridge)**:
   * مزامنة كتالوج المنتجات والصور والأسعار من تطبيق التاجر إلى متجره الإلكتروني على الويب.
   * استقبال طلبات الزبائن (بدون دفع إلكتروني - دفع عند الاستلام) وتنبيه الكاشير في التطبيق.
   * تحويل الطلب الإلكتروني إلى فاتورة مبيعات حقيقية بضغطة زر واحدة.
4. حزمة اختبارات Unit Testing لطابور المزامنة وجسر الطلبات.

---

## 2. جدول طابور المزامنة في Drift (`sync_tables.dart`)

```dart
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

// جدول صندوق الصادر للمزامنة (The Outbox Sync Queue)
@DataClassName('SyncQueueData')
class SyncQueueTable extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  
  // نوع الكيان: 'Product', 'Party', 'SalesInvoice', 'Payment'
  TextColumn get entityType => text()(); 
  TextColumn get entityId => text()();
  
  // نوع العملية: 'INSERT', 'UPDATE', 'DELETE'
  TextColumn get operation => text()(); 
  
  // البيانات المشفرة كـ JSON للإرسال للسيرفر
  TextColumn get payloadJson => text()(); 
  
  // حالة المزامنة: 'Pending', 'InFlight', 'Synced', 'Failed'
  TextColumn get status => text().withDefault(const Constant('Pending'))();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// جدول طلبات المتجر الإلكتروني الواردة من السحابة
@DataClassName('OnlineOrderData')
class OnlineOrdersTable extends Table {
  TextColumn get id => text()(); // نفس المعرف القادم من السيرفر
  TextColumn get orderNumber => text().withLength(min: 1, max: 50)();
  DateTimeColumn get orderDate => dateTime()();
  
  TextColumn get customerName => text().withLength(min: 1, max: 255)();
  TextColumn get customerPhone => text().withLength(min: 1, max: 50)();
  TextColumn get deliveryAddress => text().nullable()();
  
  RealColumn get totalAmount => real()();
  TextColumn get itemsJson => text()(); // تفاصيل الأصناف والكميات
  
  // حالة الطلب: 'New', 'Accepted', 'ConvertedToInvoice', 'Cancelled'
  TextColumn get status => text().withDefault(const Constant('New'))();
  TextColumn get convertedInvoiceId => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
```

---

## 3. محرك المزامنة بنمط صندوق الصادر (Outbox Sync Service)

أي عملية تجارية تتم في التطبيق تسجل نفسها في `SyncQueueTable` داخل نفس معاملة قاعدة البيانات المحلية، مما يضمن عدم ضياع أي حركة حتى لو أُغلق التطبيق أو فرغت البطارية:

```dart
class SyncService {
  final AppDatabase db;
  final Dio httpClient; // أو عميل الشبكة المعتمد

  SyncService({required this.db, required this.httpClient});

  /// إضافة حركة لطابور المزامنة
  Future<void> queueChange({
    required String entityType,
    required String entityId,
    required String operation,
    required Map<String, dynamic> payload,
  }) async {
    await db.into(db.syncQueueTable).insert(
      SyncQueueTableCompanion.insert(
        entityType: entityType,
        entityId: entityId,
        operation: operation,
        payloadJson: jsonEncode(payload),
      ),
    );
  }

  /// محرك إرسال التغييرات للسيرفر عند توفر الإنترنت
  Future<void> flushPendingSync() async {
    final pendingItems = await (db.select(db.syncQueueTable)
          ..where((s) => s.status.equals('Pending'))
          ..orderBy([(s) => OrderingTerm.asc(s.createdAt)])
          ..limit(50))
        .get();

    for (var item in pendingItems) {
      try {
        // وضع علامة قيد الإرسال
        await (db.update(db.syncQueueTable)..where((s) => s.id.equals(item.id))).write(
          const SyncQueueTableCompanion(status: Value('InFlight')),
        );

        // إرسال للـ Backend API
        // final response = await httpClient.post('/api/sync', data: jsonDecode(item.payloadJson));

        // تأكيد النجاح
        await (db.update(db.syncQueueTable)..where((s) => s.id.equals(item.id))).write(
          SyncQueueTableCompanion(
            status: const Value('Synced'),
            syncedAt: Value(DateTime.now()),
          ),
        );
      } catch (e) {
        // تسجيل الفشل وزيادة عداد المحاولات
        await (db.update(db.syncQueueTable)..where((s) => s.id.equals(item.id))).write(
          SyncQueueTableCompanion(
            status: const Value('Pending'),
            retryCount: Value(item.retryCount + 1),
            lastError: Value(e.toString()),
          ),
        );
      }
    }
  }
}
```

---

## 4. جسر المتجر الإلكتروني الخفيف (Store Bridge Engine)

المتجر الإلكتروني المطلوب بسيط ومباشر:
1. **مزامنة المنتجات للمتجر:**
   * عند إضافة منتج أو تعديل سعره، يتم إرسال: (الاسم، السعر، الصورة، التصنيف) إلى المتجر.
2. **استقبال الطلبات (Order Intake):**
   * العميل على الموقع يختار المنتجات، يضع اسمه ورقم هاتفه وعنوانه ويضغط "إرسال الطلب".
   * يصل الطلب إلى جدول `online_orders` في تطبيق فلاتر.
   * يظهر إشعار في واجهة التاجر: `لديك طلب متجر جديد من (محمد علي - 05000000) بقيمة 15,000 ريال`.
3. **تحويل الطلب لفاتورة بضغطة زر (One-Tap Convert):**
   * يضغط الكاشير على زر "تحويل لفاتورة":
   * يقوم النظام تلقائياً بإنشاء عميل باسم الزبون إذا لم يكن موجوداً.
   * تعبئة السلة في نقطة البيع بنفس الأصناف والكميات.
   * فتح نافذة الدفع وإصدار الفاتورة وخصم المخزن فوراً.
   * تحديث حالة الطلب إلى `ConvertedToInvoice`.

---

## 5. سياسة فض النزاعات الأوفلاين (Offline Conflict Resolution Rules)

1. **الفواتير والسندات (Invoices & Vouchers): غير قابلة للنزاع نهائياً (Append-Only):**
   * لأن كل جهاز له معرف فريد (`DeviceUUID`) وترقيم تسلسلي مركب، فلا يمكن لجهازين أن يصدرا نفس الفاتورة.
2. **المنتجات والأسعار (Catalog Master Data):**
   * سياسة الفوز لآخر تعديل بالاعتماد على التوقيت الزمني (`Last-Write-Wins`).
3. **تعارض نفاذ المخزون (Stock Collision):**
   * إذا باع جهازان نفس الصنف أوفلاين ونفذت الكمية، تسمح سياسة البيع بالسالب بمرور الفاتورة، وعند المزامنة يسجل المخزون بالسالب، ويُعطى التاجر تنبيهاً أصفر بضرورة إجراء تسوية جردية أو إدخال فاتورة مشتريات للبضاعة المستلمة فعلياً.

---

## 6. معايير القبول والرفض للمرحلة 7 (Acceptance & Rejection Criteria)

### معايير القبول (What MUST Pass):
* [ ] تسجيل عمليات البيع والشراء والسندات في وضع "وضع الطيران" دون إنترنت بنسبة 100% ودون توقف أو رسائل خطأ.
* [ ] عند عودة الإنترنت، يقوم النظام بإرسال التغييرات تلقائياً في الخلفية (Background Sync) دون تجميد شاشة الكاشير.
* [ ] ظهور طلبات المتجر الجديد في التبويب المخصص لها في واجهة المبيعات [orders_list_view.dart](file:///d:/laragon/www/smart-merchant-v1/smart_merchant_erp/lib/modules/sales/presentation/views/orders_list_view.dart).
* [ ] تحويل الطلب الإلكتروني إلى فاتورة مبيعات يخصم المخزن وينشئ القيود المحاسبية مثل أي فاتورة كاشير عادية.

### معايير الرفض والممنوعات (Prohibited Behaviors):
* ❌ **ممنوع منعاً باتاً:** حظر المستخدم من حفظ أي حركة أو فاتورة بسبب عدم وجود شبكة إنترنت.
* ❌ **ممنوع منعاً باتاً:** حذف أو تكرار سجل في طابور المزامنة عند انقطاع الاتصال المفاجئ.

---

## 7. حزمة اختبارات الـ Unit Testing للمرحلة 7 (Runnable Dart Test Suite)

يتم وضع هذا الكود في `test/kernel/sync/sync_queue_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:smart_merchant_erp/kernel/storage/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(connection: NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('اختبارات طابور المزامنة الأوفلاين (Outbox Queue)', () {
    test('يجب تسجيل الحركة في طابور المزامنة بحالة Pending بدقة', () async {
      final queueId = await db.into(db.syncQueueTable).insert(
        SyncQueueTableCompanion.insert(
          entityType: 'Product',
          entityId: 'PROD-101',
          operation: 'INSERT',
          payloadJson: '{"name": "بيبسي", "price": 300}',
        ),
      );

      expect(queueId, isNotEmpty);

      final item = await (db.select(db.syncQueueTable)..where((s) => s.id.equals(queueId))).getSingle();
      expect(item.status, 'Pending');
      expect(item.retryCount, 0);
      expect(item.entityId, 'PROD-101');
    });

    test('يجب استلام طلب المتجر الإلكتروني بنجاح في قاعدة البيانات المحلية', () async {
      await db.into(db.onlineOrdersTable).insert(
        OnlineOrdersTableCompanion.insert(
          id: 'ORDER-WEB-001',
          orderNumber: 'WEB-001',
          orderDate: DateTime.now(),
          customerName: 'فهد المطري',
          customerPhone: '777123456',
          totalAmount: 12000.0,
          itemsJson: '[{"name": "عصير راني", "qty": 10, "price": 1200}]',
        ),
      );

      final order = await (db.select(db.onlineOrdersTable)..where((o) => o.id.equals('ORDER-WEB-001'))).getSingle();
      expect(order.orderNumber, 'WEB-001');
      expect(order.status, 'New');
      expect(order.totalAmount, 12000.0);
    });
  });
}
```
