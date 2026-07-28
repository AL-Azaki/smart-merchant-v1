import '../../../../../app/di/getit_providers.dart';
import '../../../../../database/daos/core_dao.dart';
import '../../../../../database/daos/sales_dao.dart';
import '../../../../../kernel/core/application_context.dart';
import '../../../../shared/documents/presentation/models/commercial_document_data.dart';
import '../../../../shared/documents/presentation/models/commercial_document_line.dart';
import '../../../../../database/daos/catalog_dao.dart';
import '../../../../../app/di/injection.dart';
import 'package:intl/intl.dart';

import 'package:injectable/injectable.dart';

@injectable
class SalesInvoiceDocumentMapper {
  final SalesDao _salesDao;
  final CoreDao _coreDao;
  final CatalogDao _catalogDao;
  final ApplicationContext _context;

  SalesInvoiceDocumentMapper(this._salesDao, this._coreDao, this._catalogDao, this._context);

  Future<CommercialDocumentData> mapToDocumentData(String invoiceId) async {
    final businessId = _context.currentBusinessId;
    
    // 1. Fetch SalesInvoice with Items
    final invoiceWithItems = await _salesDao.getInvoiceWithItemsById(invoiceId, businessId);
    if (invoiceWithItems == null) {
      throw Exception('Sales Invoice not found for mapping.');
    }
    final invoice = invoiceWithItems.invoice;
    final items = invoiceWithItems.items;

    // 2. Fetch Business & Branch info
    final business = await _coreDao.getBusinessById(invoice.businessId);
    String businessName = business?.businessName ?? 'اسم المنشأة غير متوفر';
    String? businessPhone = business?.primaryPhone;
    String? businessAddress = null; // Can be retrieved from settings if needed
    String? taxNumber = null;

    String? branchName;
    if (invoice.branchId.isNotEmpty) {
      final branch = await _coreDao.getBranchById(invoice.branchId, businessId);
      branchName = branch?.branchName;
    }

    // 3. Fetch Customer info
    String customerName = 'عميل نقدي';
    String? customerPhone;
    String? customerAddress;
    
    if (invoice.customerId != null && invoice.customerId!.isNotEmpty) {
      final customer = await _salesDao.getCustomerById(invoice.customerId!, businessId);
      if (customer != null) {
        customerName = customer.customerName;
        customerPhone = customer.phone;
        customerAddress = customer.address;
      }
    }

    // 4. Map items
    final documentLines = <CommercialDocumentLine>[];
    for (final item in items) {
      // Need product details (name, etc.)
      final productUnit = await _catalogDao.getProductUnitById(item.productUnitId, businessId);
      String description = 'منتج غير معروف';
      String? barcode = productUnit?.barcode;
      
      if (productUnit != null) {
         final product = await _catalogDao.getProductById(productUnit.productId, businessId);
         description = product?.productName ?? description;
      }

      documentLines.add(
        CommercialDocumentLine(
          description: description,
          sku: productUnit?.sku,
          barcode: barcode,
          unitName: null, // Optional: look up from units table
          quantity: item.quantity,
          unitPrice: item.unitPrice,
          discount: item.discount,
          tax: item.tax,
          lineTotal: item.lineTotal,
        ),
      );
    }

    // 5. Payment details mapping
    String paymentMethod = 'نقداً';
    if (invoice.paymentStatus == 'Unpaid') {
      paymentMethod = 'آجل';
    } else if (invoice.paymentStatus == 'Partial') {
       paymentMethod = 'نقداً / آجل';
    }

    double paidAmount = 0.0;
    double remainingAmount = 0.0;
    
    // We should lookup customer receivables to get real paid/remaining amounts
    if (invoice.customerId != null && invoice.customerId!.isNotEmpty) {
       final receivablesList = await _salesDao.listReceivables(
          CustomerReceivableFilter(
            businessId: businessId, 
            salesInvoiceId: invoice.id,
          ),
       );
       if (receivablesList.isNotEmpty) {
          final receivable = receivablesList.first;
          paidAmount = receivable.paidAmount;
          remainingAmount = receivable.remainingAmount;
       } else {
          // If no receivable, it implies fully paid cash sale
          paidAmount = invoice.grandTotal;
          remainingAmount = 0.0;
       }
    } else {
       // Walk-in customer is always full cash
       paidAmount = invoice.grandTotal;
       remainingAmount = 0.0;
    }

    return CommercialDocumentData(
      documentType: 'فاتورة مبيعات',
      documentNumber: invoice.invoiceNumber,
      issueDate: invoice.invoiceDate,
      
      businessName: businessName,
      businessPhone: businessPhone,
      businessAddress: businessAddress,
      taxNumber: taxNumber,
      
      branchName: branchName,
      
      customerOrSupplierName: customerName,
      customerOrSupplierPhone: customerPhone,
      customerOrSupplierAddress: customerAddress,
      
      currencyCode: invoice.currencyId,
      currencySymbol: 'YER', // Optional: could lookup from Currencies table
      
      paymentMethod: paymentMethod,
      paymentStatus: invoice.paymentStatus,
      
      items: documentLines,
      
      subtotal: invoice.subTotal,
      discount: invoice.discountTotal,
      tax: invoice.taxTotal,
      grandTotal: invoice.grandTotal,
      
      paidAmount: paidAmount,
      remainingAmount: remainingAmount,
      
      notes: invoice.notes,
      terms: 'البضاعة المباعة لا ترد ولا تستبدل بعد 3 أيام',
    );
  }
}
