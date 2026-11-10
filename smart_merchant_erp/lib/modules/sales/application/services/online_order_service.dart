import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';
import '../../../../app/di/manual_injection.dart';
import '../../../../database/daos/core_dao.dart';
import '../../../../database/daos/sales_dao.dart';
import '../../../../kernel/core/application_context.dart';
import '../../../../kernel/error/failures.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../../settings/infrastructure/api/storefront_remote_api_client.dart';
import '../../domain/repositories/sales_repository.dart';
import 'order_status_feedback_service.dart';

class StorefrontOrderItemInput {
  final String productId;
  final String productUnitId;
  final String productName;
  final String unitName;
  final double quantity;
  final double unitPrice;

  const StorefrontOrderItemInput({
    required this.productId,
    required this.productUnitId,
    required this.productName,
    required this.unitName,
    required this.quantity,
    required this.unitPrice,
  });

  double get lineTotal => quantity * unitPrice;
}

class CreatedStorefrontOrderResult {
  final String orderId;
  final String orderNumber;
  final double grandTotal;
  final DateTime orderDate;
  final String customerName;
  final String customerPhone;

  const CreatedStorefrontOrderResult({
    required this.orderId,
    required this.orderNumber,
    required this.grandTotal,
    required this.orderDate,
    required this.customerName,
    required this.customerPhone,
  });
}

/// Application service for Online Order cashier review workflow.
///
/// CRITICAL INVARIANT:
/// - Accept = "Merchant agrees to process." It does NOT create a SalesInvoice,
///   deduct stock, create a JournalEntry, Payment, or Receivable.
/// - Reject = "Merchant declines." The order is preserved for audit history.
/// - POS Handoff = Transfers order data into POS cart for explicit sale confirmation.
///
/// Status mapping to existing schema:
///   Pending   → New order awaiting review
///   Confirmed → Cashier accepted the order
///   Cancelled → Cashier rejected the order
///   Delivered → Fulfilled (after CompleteSaleUseCase succeeds)
class OnlineOrderService {
  final SalesRepository _salesRepository;
  final ApplicationContext _context;
  final OrderStatusFeedbackService? _feedbackService;

  OnlineOrderService(
    this._salesRepository,
    this._context, [
    this._feedbackService,
  ]);

  /// Accepts an online order by setting status to 'Confirmed'.
  ///
  /// DOES NOT: create SalesInvoice, deduct inventory, create JournalEntry,
  /// create Payment, or create Receivable.
  Future<Either<Failure, bool>> acceptOrder(String orderId) async {
    final businessId = _context.currentBusinessId;

    try {
      // Verify order exists and is in Pending status
      final order = await _salesRepository.getOrderById(orderId, businessId);
      if (order == null) {
        return const Left(ValidationFailure('الطلب غير موجود.'));
      }
      if (order.status != 'Pending') {
        return Left(
          ValidationFailure(
            'لا يمكن قبول طلب بحالة "${order.status}". يجب أن يكون الطلب في حالة "قيد المراجعة".',
          ),
        );
      }

      // Guard: prevent accepting a deleted order
      if (order.deletedAt != null) {
        return const Left(ValidationFailure('الطلب محذوف.'));
      }

      final updated = await _salesRepository.updateOrderStatus(
        orderId,
        businessId,
        'Confirmed',
      );

      if (!updated) {
        return const Left(ValidationFailure('فشل تحديث حالة الطلب.'));
      }

      if (_feedbackService != null) {
        await _feedbackService.sendFeedback(
          orderId: orderId,
          status: 'Confirmed',
        );
      }

      return const Right(true);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  /// Rejects an online order by setting status to 'Cancelled'.
  ///
  /// The order record is preserved for audit/history (not deleted).
  Future<Either<Failure, bool>> rejectOrder(String orderId) async {
    final businessId = _context.currentBusinessId;

    try {
      final order = await _salesRepository.getOrderById(orderId, businessId);
      if (order == null) {
        return const Left(ValidationFailure('الطلب غير موجود.'));
      }
      if (order.status == 'Cancelled') {
        return const Left(ValidationFailure('الطلب مرفوض بالفعل.'));
      }
      if (order.status == 'Delivered') {
        return const Left(ValidationFailure('لا يمكن رفض طلب مكتمل.'));
      }
      if (order.deletedAt != null) {
        return const Left(ValidationFailure('الطلب محذوف.'));
      }

      final updated = await _salesRepository.updateOrderStatus(
        orderId,
        businessId,
        'Cancelled',
      );

      if (!updated) {
        return const Left(ValidationFailure('فشل تحديث حالة الطلب.'));
      }

      if (_feedbackService != null) {
        await _feedbackService.sendFeedback(
          orderId: orderId,
          status: 'Cancelled',
        );
      }

      return const Right(true);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  /// Marks an order as fulfilled (Delivered) ONLY after CompleteSaleUseCase succeeds.
  ///
  /// This MUST be called only after the actual sale transaction has been committed.
  /// Never call this before the sale succeeds.
  Future<Either<Failure, bool>> markOrderFulfilled(
    String orderId, {
    String? invoiceId,
    String? invoiceNumber,
  }) async {
    final businessId = _context.currentBusinessId;

    try {
      final order = await _salesRepository.getOrderById(orderId, businessId);
      if (order == null) {
        return const Left(ValidationFailure('الطلب غير موجود.'));
      }
      if (order.status == 'Delivered') {
        return const Left(ValidationFailure('الطلب مكتمل بالفعل.'));
      }
      if (order.status != 'Confirmed') {
        return Left(
          ValidationFailure(
            'لا يمكن إكمال طلب بحالة "${order.status}". يجب قبول الطلب أولاً.',
          ),
        );
      }

      final updated = await _salesRepository.updateOrderStatus(
        orderId,
        businessId,
        'Delivered',
      );

      if (!updated) {
        return const Left(ValidationFailure('فشل تحديث حالة الطلب.'));
      }

      if (_feedbackService != null) {
        await _feedbackService.sendFeedback(
          orderId: orderId,
          status: 'Delivered',
          invoiceId: invoiceId,
          invoiceNumber: invoiceNumber,
          completedAt: DateTime.now().toIso8601String(),
        );
      }

      return const Right(true);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  /// Retrieves order with items for cashier review.
  Future<Either<Failure, OrderWithItems>> getOrderForReview(
    String orderId,
  ) async {
    final businessId = _context.currentBusinessId;

    try {
      final orderWithItems = await _salesRepository.getOrderWithItemsById(
        orderId,
        businessId,
      );

      if (orderWithItems == null) {
        return const Left(ValidationFailure('الطلب غير موجود.'));
      }

      return Right(orderWithItems);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  /// Checks whether an order has already been fulfilled to prevent duplicate sales.
  Future<bool> isOrderAlreadyFulfilled(String orderId) async {
    final businessId = _context.currentBusinessId;

    try {
      final order = await _salesRepository.getOrderById(orderId, businessId);
      return order?.status == 'Delivered';
    } catch (_) {
      return false;
    }
  }

  /// Creates a customer storefront order (from the in-app Live Customer Simulator)
  /// and saves it to local SQLite immediately, while also attempting to submit to remote Web API if online.
  Future<Either<Failure, CreatedStorefrontOrderResult>>
      createCustomerStorefrontOrder({
    required String customerName,
    required String customerPhone,
    String? customerEmail,
    required String shippingAddress,
    String? shippingCity,
    String? customerNotes,
    required List<StorefrontOrderItemInput> items,
    String? storeSlug,
  }) async {
    final businessId = _context.currentBusinessId;
    if (businessId.isEmpty) {
      return const Left(ValidationFailure('لم يتم العثور على المنشأة النشطة.'));
    }
    if (items.isEmpty) {
      return const Left(ValidationFailure('سلة المشتريات فارغة.'));
    }

    try {
      const uuid = Uuid();
      final coreDao = getIt<CoreDao>();

      // 1. Resolve Branch ID
      var branchId = _context.currentBranchId;
      if (branchId == null || branchId.isEmpty) {
        final branches = await coreDao.listBranches(
          BranchFilter(businessId: businessId, isActive: true),
        );
        branchId = branches.firstOrNull?.id;
      }
      if (branchId == null || branchId.isEmpty) {
        return const Left(
          ValidationFailure('لا يوجد فرع نشط لربط الطلب الإلكتروني به.'),
        );
      }

      // 2. Resolve Currency ID
      final baseCurrency = await coreDao.getBaseCurrency();
      String? currencyId = baseCurrency?.id;
      if (currencyId == null || currencyId.isEmpty) {
        final currencies = await coreDao.listCurrencies(isActive: true);
        currencyId = currencies.firstOrNull?.id;
      }
      if (currencyId == null || currencyId.isEmpty) {
        return const Left(
          ValidationFailure('لا توجد عملة أساسية معرفة في النظام.'),
        );
      }

      // 3. Ensure Online Store Channel exists locally
      final existingChannels = await _salesRepository.listChannels(
        ChannelFilter(businessId: businessId),
      );
      var onlineChannel = existingChannels
          .where(
            (c) =>
                c.channelType == 'Ecommerce' ||
                c.channelCode == 'ONLINE-STORE-01',
          )
          .firstOrNull;

      String channelId;
      if (onlineChannel != null) {
        channelId = onlineChannel.id;
      } else {
        channelId = uuid.v4();
        await _salesRepository.insertChannel(
          ChannelsCompanion.insert(
            id: channelId,
            businessId: businessId,
            channelName: 'المتجر الإلكتروني (Online Store)',
            channelCode: 'ONLINE-STORE-01',
            channelType: 'Ecommerce',
            isActive: const drift.Value(true),
          ),
        );
      }

      // 4. Optional remote submission (if server is reachable & slug exists)
      String? remoteOrderNumber;
      if (storeSlug != null && storeSlug.trim().isNotEmpty) {
        try {
          final remoteApi = getIt<StorefrontRemoteApiClient>();
          final payload = <String, dynamic>{
            'customer_name': customerName.trim(),
            'customer_phone': customerPhone.trim(),
            if (customerEmail != null && customerEmail.trim().isNotEmpty)
              'customer_email': customerEmail.trim(),
            'shipping_address': shippingAddress.trim(),
            if (shippingCity != null && shippingCity.trim().isNotEmpty)
              'shipping_city': shippingCity.trim(),
            if (customerNotes != null && customerNotes.trim().isNotEmpty)
              'customer_notes': customerNotes.trim(),
            'idempotency_key': uuid.v4(),
            'items': items
                .map(
                  (i) => {
                    'product_id': i.productId,
                    'product_unit_id': i.productUnitId,
                    'quantity': i.quantity,
                  },
                )
                .toList(),
          };
          final remoteRes = await remoteApi.createCustomerOrder(
            storeSlug.trim(),
            payload,
          );
          final data = remoteRes['data'];
          if (data is Map && data['order_number'] != null) {
            remoteOrderNumber = data['order_number'].toString();
          }
        } catch (_) {
          // Proceed seamlessly with local persistence when offline
        }
      }

      // 5. Compute totals & build structured notes
      final orderId = uuid.v4();
      final now = DateTime.now();
      final orderNumber = remoteOrderNumber ??
          'ORD-${now.millisecondsSinceEpoch.toString().substring(6)}';

      var subTotal = 0.0;
      final itemCompanions = <OrderItemsCompanion>[];

      for (final item in items) {
        final lineTotal = item.quantity * item.unitPrice;
        subTotal += lineTotal;
        itemCompanions.add(
          OrderItemsCompanion.insert(
            id: uuid.v4(),
            businessId: businessId,
            orderId: orderId,
            productUnitId: item.productUnitId,
            quantity: item.quantity,
            unitPrice: item.unitPrice,
            lineTotal: lineTotal,
            baseLineTotal: drift.Value(lineTotal),
          ),
        );
      }

      final cityPart =
          (shippingCity != null && shippingCity.trim().isNotEmpty)
              ? '${shippingCity.trim()} - '
              : '';
      final noteParts = <String>[
        'العميل: ${customerName.trim()}',
        'الهاتف: ${customerPhone.trim()}',
        'العنوان: $cityPart${shippingAddress.trim()}',
        if (customerNotes != null && customerNotes.trim().isNotEmpty)
          'ملاحظات: ${customerNotes.trim()}',
      ];
      final formattedNotes = noteParts.join(' | ');

      final orderCompanion = OrdersCompanion.insert(
        id: orderId,
        businessId: businessId,
        branchId: branchId,
        channelId: channelId,
        orderNumber: orderNumber,
        orderDate: drift.Value(now),
        currencyId: currencyId,
        subTotal: drift.Value(subTotal),
        grandTotal: drift.Value(subTotal),
        baseSubTotal: drift.Value(subTotal),
        baseGrandTotal: drift.Value(subTotal),
        status: const drift.Value('Pending'),
        paymentStatus: const drift.Value('Unpaid'),
        notes: drift.Value(formattedNotes),
        createdAt: drift.Value(now),
        updatedAt: drift.Value(now),
      );

      await _salesRepository.recordOrderWithItems(
        order: orderCompanion,
        items: itemCompanions,
      );

      return Right(
        CreatedStorefrontOrderResult(
          orderId: orderId,
          orderNumber: orderNumber,
          grandTotal: subTotal,
          orderDate: now,
          customerName: customerName.trim(),
          customerPhone: customerPhone.trim(),
        ),
      );
    } catch (e) {
      return Left(UnexpectedFailure('تعذر إنشاء الطلب: $e'));
    }
  }
}
