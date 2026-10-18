import 'package:flutter/material.dart';
import '../../../../../../kernel/storage/app_database.dart';
import '../../../widgets/inventory_record_dialog.dart';

class StockAdjustmentDetailsDialog {
  static Future<void> show(
    BuildContext context,
    InventoryTransaction transaction,
  ) => showDialog<void>(
    context: context,
    builder: (_) => InventoryRecordDialog(
      title: 'تفاصيل التسوية',
      load: (workflow) => workflow.loadAdjustment(transaction.id),
    ),
  );
}
