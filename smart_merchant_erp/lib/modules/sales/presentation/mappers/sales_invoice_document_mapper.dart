import '../../../../database/daos/core_dao.dart';
import '../../../../database/daos/sales_dao.dart';
import '../../../../kernel/core/application_context.dart';
import '../../../../shared/documents/presentation/models/commercial_document_data.dart';
import '../../../../shared/documents/presentation/models/commercial_document_line.dart';
import '../../../../database/daos/catalog_dao.dart';

class SalesInvoiceDocumentMapper {
  final SalesDao _salesDao;
  final CoreDao _coreDao;
  final CatalogDao _catalogDao;
  final ApplicationContext _context;

  SalesInvoiceDocumentMapper(
    this._salesDao,
    this._coreDao,
    this._catalogDao,
    this._context,
  );

  /// تحويل فاتورة مبيعات إلى نموذج المستند التجاري الموحد للطباعة والمشاركة
  Future<CommercialDocumentData> mapToDocumentData(String invoiceId) async {
    final businessId = _context.currentBusinessId;

    // 1. Fetch SalesInvoice with Items
    final invoiceWithItems = await _salesDao.getInvoiceWithItemsById(
      invoiceId,
      businessId,
    );
    if (invoiceWithItems == null) {
      throw Exception('Sales Invoice not found for mapping.');
    }
    final invoice = invoiceWithItems.invoice;
    final items = invoiceWithItems.items;

    // 2. Fetch Business & Branch info
    final business = await _coreDao.getBusinessById(invoice.businessId);
    String businessName = business?.businessName ?? 'اسم المنشأة غير متوفر';
    String? businessPhone = business?.primaryPhone;
    String? businessAddress;

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
      final customer = await _salesDao.getCustomerById(
        invoice.customerId!,
        businessId,
      );
      if (customer != null) {
        customerName = customer.customerName;
        customerPhone = customer.phone;
        customerAddress = customer.address;
      }
    }

    // 4. Map items
    final documentLines = <CommercialDocumentLine>[];
    for (final item in items) {
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
          unitName: null,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
          discount: item.discount,
          tax: 0.0, // إلغاء الضريبة بالكامل
          lineTotal: item.lineTotal,
        ),
      );
    }

    // 5. Payment details mapping
    String paymentMethod = 'نقداً';
    if (invoice.paymentStatus == 'Unpaid' || invoice.paymentStatus == 'آجلة') {
      paymentMethod = 'آجل';
    } else if (invoice.paymentStatus == 'Partial' || invoice.paymentStatus == 'مدفوعة جزئياً') {
      paymentMethod = 'نقداً / آجل';
    }

    double paidAmount = 0.0;
    double remainingAmount = 0.0;

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
        paidAmount = invoice.grandTotal;
        remainingAmount = 0.0;
      }
    } else {
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
      taxNumber: null, // حذف الرقم الضريبي

      branchName: branchName,

      customerOrSupplierName: customerName,
      customerOrSupplierPhone: customerPhone,
      customerOrSupplierAddress: customerAddress,

      currencyCode: invoice.currencyId,
      currencySymbol: 'ريال يمني',

      paymentMethod: paymentMethod,
      paymentStatus: invoice.paymentStatus,

      items: documentLines,

      subtotal: invoice.subTotal,
      discount: invoice.discountTotal,
      tax: 0.0, // إلغاء الضريبة بالكامل
      grandTotal: invoice.grandTotal,

      paidAmount: paidAmount,
      remainingAmount: remainingAmount,

      notes: invoice.notes,
      terms: 'البضاعة المباعة لا تُرد ولا تُستبدل إلا بموجب أصل الفاتورة',
    );
  }

  /// تحويل فاتورة مرتجع مبيعات إلى نموذج المستند التجاري الموحد للطباعة والمعاينة
  Future<CommercialDocumentData> mapReturnToDocumentData(String returnId) async {
    final businessId = _context.currentBusinessId;

    // 1. Fetch SalesReturn with Items
    final returnWithItems = await _salesDao.getReturnWithItemsById(
      returnId,
      businessId,
    );
    if (returnWithItems == null) {
      throw Exception('Sales Return not found for mapping.');
    }
    final salesReturn = returnWithItems.salesReturn;
    final items = returnWithItems.items;

    // 2. Fetch original invoice to get customer & items details
    final originalInvoiceWithItems = await _salesDao.getInvoiceWithItemsById(
      salesReturn.salesInvoiceId,
      businessId,
    );
    final originalInvoice = originalInvoiceWithItems?.invoice;
    final originalItems = originalInvoiceWithItems?.items ?? [];
    final originalItemMap = {for (var item in originalItems) item.id: item};

    // 3. Fetch Business & Branch info
    final business = await _coreDao.getBusinessById(salesReturn.businessId);
    String businessName = business?.businessName ?? 'اسم المنشأة غير متوفر';
    String? businessPhone = business?.primaryPhone;
    String? businessAddress;

    String? branchName;
    if (salesReturn.branchId.isNotEmpty) {
      final branch = await _coreDao.getBranchById(salesReturn.branchId, businessId);
      branchName = branch?.branchName;
    }

    // 4. Customer info
    String customerName = 'عميل نقدي';
    String? customerPhone;
    String? customerAddress;

    if (originalInvoice?.customerId != null && originalInvoice!.customerId!.isNotEmpty) {
      final customer = await _salesDao.getCustomerById(
        originalInvoice.customerId!,
        businessId,
      );
      if (customer != null) {
        customerName = customer.customerName;
        customerPhone = customer.phone;
        customerAddress = customer.address;
      }
    }

    // 5. Map return items
    final documentLines = <CommercialDocumentLine>[];
    for (final item in items) {
      final origItem = originalItemMap[item.salesInvoiceItemId];
      String description = 'صنف مرتجع';

      if (origItem != null) {
        final productUnit = await _catalogDao.getProductUnitById(
          origItem.productUnitId,
          businessId,
        );
        if (productUnit != null) {
          final product = await _catalogDao.getProductById(
            productUnit.productId,
            businessId,
          );
          description = product?.productName ?? description;
        }
      }

      documentLines.add(
        CommercialDocumentLine(
          description: description,
          unitName: null,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
          discount: 0.0,
          tax: 0.0,
          lineTotal: item.totalPrice,
        ),
      );
    }

    final originalInvoiceNum = originalInvoice?.invoiceNumber ?? '';
    final noteParts = <String>[];
    if (originalInvoiceNum.isNotEmpty) {
      noteParts.add('مرتجع من فاتورة رقم: $originalInvoiceNum');
    }
    if (salesReturn.notes != null && salesReturn.notes!.trim().isNotEmpty) {
      noteParts.add(salesReturn.notes!.trim());
    }

    return CommercialDocumentData(
      documentType: 'فاتورة مرتجع مبيعات',
      documentNumber: salesReturn.returnNumber,
      issueDate: salesReturn.returnDate,

      businessName: businessName,
      businessPhone: businessPhone,
      businessAddress: businessAddress,
      taxNumber: null,

      branchName: branchName,

      customerOrSupplierName: customerName,
      customerOrSupplierPhone: customerPhone,
      customerOrSupplierAddress: customerAddress,

      currencyCode: salesReturn.currencyId,
      currencySymbol: 'ريال يمني',

      paymentMethod: 'استرداد نقدي / آجل',
      paymentStatus: salesReturn.status,

      items: documentLines,

      subtotal: salesReturn.totalAmount,
      discount: 0.0,
      tax: 0.0,
      grandTotal: salesReturn.totalAmount,

      paidAmount: salesReturn.totalAmount,
      remainingAmount: 0.0,

      notes: noteParts.isNotEmpty ? noteParts.join(' - ') : null,
      terms: 'سند إرجاع بضاعة معتمد - تم استلام البضاعة وتحديث الحساب المالي',
    );
  }
}
