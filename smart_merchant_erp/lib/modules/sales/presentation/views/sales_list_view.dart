import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sales_provider.dart';
import '../../../../shared/documents/presentation/widgets/commercial_document_preview_screen.dart';
import '../mappers/sales_invoice_document_mapper.dart';
import '../../../../app/di/injection.dart';

class SalesListView extends ConsumerWidget {
  const SalesListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(salesInvoicesNotifierProvider);

    return invoicesAsync.when(
      data: (invoices) {
        if (invoices.isEmpty) {
          return const Center(
            child: Text(
              'لا توجد فواتير مبيعات',
              style: TextStyle(fontSize: 18),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: invoices.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final invoice = invoices[index];
            return ListTile(
              leading: const Icon(Icons.receipt_rounded, color: Colors.blue),
              title: Text(
                invoice.invoiceNumber,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(invoice.invoiceDate.toString().split(' ')[0]),
              trailing: Text(
                '${invoice.grandTotal.toStringAsFixed(2)} YER',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              onTap: () async {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (ctx) => const Center(child: CircularProgressIndicator()),
                );
                try {
                  final mapper = getIt<SalesInvoiceDocumentMapper>();
                  final docData = await mapper.mapToDocumentData(invoice.id);
                  if (!context.mounted) return;
                  Navigator.of(context, rootNavigator: true).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CommercialDocumentPreviewScreen(document: docData),
                    ),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  Navigator.of(context, rootNavigator: true).pop();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}
