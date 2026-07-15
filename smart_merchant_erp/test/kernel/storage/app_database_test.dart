import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:smart_merchant_erp/kernel/storage/app_database.dart';

void main() {
  late AppDatabase database;

  // إعداد بيئة الاختبار (تعمل قبل كل اختبار)
  setUp(() {
    // نستخدم (NativeDatabase.memory) لإنشاء قاعدة بيانات وهمية في الذاكرة العشوائية (RAM)
    // هذا يضمن أن الاختبار سيكون سريعاً جداً كسرعة الضوء، ولا يمسح البيانات الحقيقية
    database = AppDatabase(connection: NativeDatabase.memory());
  });

  // تنظيف بيئة الاختبار (تعمل بعد كل اختبار)
  tearDown(() async {
    await database.close();
  });

  group('AppDatabase Foundation Tests -', () {
    test('يجب أن يتم إنشاء قاعدة البيانات بنجاح وأن يكون إصدار المخطط هو 1', () {
      // التأكد من أن قاعدة البيانات ليست فارغة
      expect(database, isNotNull);
      
      // التأكد من أن الإصدار الأول (المهم جداً للتهجير مستقبلاً) هو 1
      expect(database.schemaVersion, equals(1));
    });
    
    // سيتم إضافة اختبارات (CRUD) للجداول (الفواتير والعملاء) هنا لاحقاً
  });
}
