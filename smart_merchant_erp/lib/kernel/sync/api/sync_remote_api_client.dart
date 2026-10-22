import 'dart:io';
import 'package:dio/dio.dart';
import '../../../app/config/api_client.dart';
import '../dto/sync_dtos.dart';

/// Remote API client for the Laravel Sync Gateway.
///
/// Routes:
/// - POST /sync/push
/// - POST /sync/pull
/// - POST /sync/ack
/// - POST /media/product-image
///
/// All requests require Bearer auth and X-Device-ID header (injected by [ApiClient]).
class SyncRemoteApiClient {
  final ApiClient _apiClient;

  const SyncRemoteApiClient(this._apiClient);

  /// POST /media/product-image — upload compressed product image and obtain public URL.
  Future<Map<String, dynamic>> uploadProductImage(File imageFile) async {
    final fileName = imageFile.path.split(Platform.pathSeparator).last;
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(
        imageFile.path,
        filename: fileName,
      ),
    });
    final response = await _apiClient.post(
      '/media/product-image',
      data: formData,
    );
    return response.json;
  }

  /// POST /sync/push — push Flutter-owned entity projections to Laravel.
  Future<PushSyncResponseDto> push(
    PushSyncRequestDto request, {
    bool isStorefrontSync = false,
  }) async {
    final response = await _apiClient.post(
      '/sync/push',
      data: {
        ...request.toJson(),
        if (isStorefrontSync) 'storefront_sync': true,
      },
    );
    return PushSyncResponseDto.fromJson(response.json);
  }

  /// POST /sync/pull — pull server-authoritative entities (Online Orders).
  Future<PullSyncResponseDto> pull(PullSyncRequestDto request) async {
    final response = await _apiClient.post(
      '/sync/pull',
      data: request.toJson(),
    );
    return PullSyncResponseDto.fromJson(response.json);
  }

  /// POST /sync/ack — acknowledge successful local persistence of pulled entities.
  Future<AckSyncResponseDto> ack(AckSyncRequestDto request) async {
    final response = await _apiClient.post('/sync/ack', data: request.toJson());
    return AckSyncResponseDto.fromJson(response.json);
  }

  /// POST /sync/orders/{order}/status — send secure, limited order status feedback to Laravel.
  Future<Map<String, dynamic>> updateOrderStatus({
    required String orderId,
    required String status,
    required String idempotencyKey,
    String? invoiceId,
    String? invoiceNumber,
    String? completedAt,
    int? revision,
  }) async {
    final response = await _apiClient.post(
      '/sync/orders/$orderId/status',
      data: {
        'status': status,
        'idempotency_key': idempotencyKey,
        'invoice_id': ?invoiceId,
        'invoice_number': ?invoiceNumber,
        'completed_at': ?completedAt,
        'revision': ?revision,
      },
    );
    return response.json;
  }
}
