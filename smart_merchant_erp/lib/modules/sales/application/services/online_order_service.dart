import 'package:dartz/dartz.dart';
import '../../../../kernel/core/application_context.dart';
import '../../../../kernel/error/failures.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../../../database/daos/sales_dao.dart';
import '../../domain/repositories/sales_repository.dart';

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

  OnlineOrderService(this._salesRepository, this._context);

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

      return const Right(true);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  /// Marks an order as fulfilled (Delivered) ONLY after CompleteSaleUseCase succeeds.
  ///
  /// This MUST be called only after the actual sale transaction has been committed.
  /// Never call this before the sale succeeds.
  Future<Either<Failure, bool>> markOrderFulfilled(String orderId) async {
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
}
