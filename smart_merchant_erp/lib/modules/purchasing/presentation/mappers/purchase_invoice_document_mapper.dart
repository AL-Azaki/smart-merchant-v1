import '../../../../app/di/getit_providers.dart';
import '../../../../database/daos/core_dao.dart';
import '../../../../database/daos/purchasing_dao.dart';
import '../../../../kernel/core/application_context.dart';
import '../../../../shared/documents/presentation/models/commercial_document_data.dart';
import '../../../../shared/documents/presentation/models/commercial_document_line.dart';
import '../../../../database/daos/catalog_dao.dart';
import '../../../../app/di/getit_instance.dart';
import 'package:intl/intl.dart';

class PurchaseInvoiceDocumentMapper {
  final PurchasingDao _purchasingDao;
  final CoreDao _coreDao;
  final CatalogDao _catalogDao;
  final ApplicationContext _context;

  PurchaseInvoiceDocumentMapper(
    this._purchasingDao,
    this._coreDao,
    this._catalogDao,
    this._context,
  );

  Future<CommercialDocumentData> mapToDocumentData(String invoiceId) async {
    final businessId = _context.currentBusinessId;

    // 1. Fetch PurchaseInvoice with Items
    final invoiceWithItems = await _purchasingDao.getInvoiceWithItemsById(
      invoiceId,
      businessId,
    );
    if (invoiceWithItems == null) {
      throw Exception('Purchase Invoice not found for mapping.');
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

    // 3. Fetch Supplier info
    String supplierName = 'مورد غير معروف';
    String? supplierPhone;
    String? supplierAddress;

    if (invoice.supplierId.isNotEmpty) {
      final supplier = await _purchasingDao.getSupplierById(
        invoice.supplierId,
        businessId,
      );
      if (supplier != null) {
        supplierName = supplier.supplierName;
        supplierPhone = supplier.phone;
        supplierAddress = supplier.supplierAddress;
      }
    }

    // 4. Map items
    final documentLines = <CommercialDocumentLine>[];
    for (final item in items) {
      // Need product details (name, etc.)
      final productUnit = await _catalogDao.getProductUnitById(
        item.productUnitId,
        businessId,
      );
      String description = 'منتج غير معروف';
      String? barcode = productUnit?.barcode;

      if (productUnit != null) {
        final product = await _catalogDao.getProductById(
          productUnit.productId,
          businessId,
        );
        description = product?.productName ?? description;
      }

      documentLines.add(
        CommercialDocumentLine(
          description: description,
          sku: productUnit?.sku,
          barcode: barcode,
          unitName: null, // Optional: look up from units table
          quantity: item.quantity,
          unitPrice: item.unitPrice, // Purchase uses unitPrice in drift table
          discount:
              0.0, // Assuming discount isn't tracked per item for purchase yet
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

    // We should lookup supplier payables to get real paid/remaining amounts
    if (invoice.supplierId.isNotEmpty) {
      final payablesList = await _purchasingDao.listPayables(
        SupplierPayableFilter(
          businessId: businessId,
          purchaseInvoiceId: invoice.id,
        ),
      );
      if (payablesList.isNotEmpty) {
        final payable = payablesList.first;
        paidAmount = payable.paidAmount;
        remainingAmount = payable.remainingAmount;
      } else {
        // If no payable, it implies fully paid cash purchase
        paidAmount = invoice.grandTotal;
        remainingAmount = 0.0;
      }
    } else {
      // Just in case
      paidAmount = invoice.grandTotal;
      remainingAmount = 0.0;
    }

    return CommercialDocumentData(
      documentType: 'فاتورة مشتريات',
      documentNumber: invoice.invoiceNumber,
      issueDate: invoice.purchaseDate,

      businessName: businessName,
      businessPhone: businessPhone,
      businessAddress: businessAddress,
      taxNumber: taxNumber,

      branchName: branchName,

      customerOrSupplierName: supplierName,
      customerOrSupplierPhone: supplierPhone,
      customerOrSupplierAddress: supplierAddress,

      currencyCode: invoice.currencyId, // Should ideally be code
      currencySymbol: 'YER',

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
      terms: 'ملاحظات الفاتورة',

      sellerSignatureLabel: 'توقيع المورد',
      customerSignatureLabel: 'توقيع المستلم',
      managementApprovalLabel: 'اعتماد الإدارة',
      companyStampLabel: 'ختم الشركة',
    );
  }
}
