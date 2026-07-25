/// DTOs matching exactly the Laravel Sync API contract.
/// Push: POST /api/sync/push { entity, items: [{ id, revision, ...fields }] }
/// Pull: POST /api/sync/pull { entity, cursor, limit }
/// ACK:  POST /api/sync/ack  { entity, idempotency_key, items: [{ id, revision }] }

// ── Push ────────────────────────────────────────────────────

class PushSyncRequestDto {
  final String entity;
  final List<Map<String, dynamic>> items;

  const PushSyncRequestDto({required this.entity, required this.items});

  Map<String, dynamic> toJson() => {'entity': entity, 'items': items};
}

class PushItemResultDto {
  final String id;
  final String
  status; // 'applied' | 'stale' | 'idempotent' | 'rejected' | 'error'
  final int? serverRevision;
  final String? reason;

  const PushItemResultDto({
    required this.id,
    required this.status,
    this.serverRevision,
    this.reason,
  });

  factory PushItemResultDto.fromJson(Map<String, dynamic> json) {
    return PushItemResultDto(
      id: json['id']?.toString() ?? '',
      status: json['status'] as String? ?? 'error',
      serverRevision: json['server_revision'] as int?,
      reason: json['reason'] as String?,
    );
  }

  bool get isApplied => status == 'applied';
  bool get isStale => status == 'stale';
  bool get isIdempotent => status == 'idempotent';
}

class PushSyncResponseDto {
  final String status;
  final List<PushItemResultDto> results;

  const PushSyncResponseDto({required this.status, required this.results});

  factory PushSyncResponseDto.fromJson(Map<String, dynamic> json) {
    return PushSyncResponseDto(
      status: json['status'] as String? ?? 'error',
      results: (json['results'] as List<dynamic>? ?? [])
          .map((e) => PushItemResultDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ── Pull ────────────────────────────────────────────────────

class PullSyncRequestDto {
  final String entity;
  final int cursor;
  final int limit;

  const PullSyncRequestDto({
    required this.entity,
    this.cursor = 0,
    this.limit = 50,
  });

  Map<String, dynamic> toJson() => {
    'entity': entity,
    'cursor': cursor,
    'limit': limit,
  };
}

class PullSyncResponseDto {
  final String status;
  final List<Map<String, dynamic>> items;
  final int nextCursor;

  const PullSyncResponseDto({
    required this.status,
    required this.items,
    required this.nextCursor,
  });

  factory PullSyncResponseDto.fromJson(Map<String, dynamic> json) {
    return PullSyncResponseDto(
      status: json['status'] as String? ?? 'error',
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{})
          .toList(),
      nextCursor: json['next_cursor'] as int? ?? 0,
    );
  }

  bool get hasItems => items.isNotEmpty;
}

// ── ACK ─────────────────────────────────────────────────────

class AckSyncRequestDto {
  final String entity;
  final String idempotencyKey;
  final List<AckItemDto> items;

  const AckSyncRequestDto({
    required this.entity,
    required this.idempotencyKey,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
    'entity': entity,
    'idempotency_key': idempotencyKey,
    'items': items.map((e) => e.toJson()).toList(),
  };
}

class AckItemDto {
  final String id;
  final int revision;

  const AckItemDto({required this.id, required this.revision});

  Map<String, dynamic> toJson() => {'id': id, 'revision': revision};
}

class AckSyncResponseDto {
  final String status;
  final String? message;
  final List<AckItemResultDto> results;

  const AckSyncResponseDto({
    required this.status,
    this.message,
    this.results = const [],
  });

  factory AckSyncResponseDto.fromJson(Map<String, dynamic> json) {
    return AckSyncResponseDto(
      status: json['status'] as String? ?? 'error',
      message: json['message'] as String?,
      results: (json['results'] as List<dynamic>? ?? [])
          .map((e) => AckItemResultDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AckItemResultDto {
  final String id;
  final String status;

  const AckItemResultDto({required this.id, required this.status});

  factory AckItemResultDto.fromJson(Map<String, dynamic> json) {
    return AckItemResultDto(
      id: json['id']?.toString() ?? '',
      status: json['status'] as String? ?? '',
    );
  }
}
