import 'package:freezed_annotation/freezed_annotation.dart';

part 'commercial_document_line.freezed.dart';

@freezed
class CommercialDocumentLine with _$CommercialDocumentLine {
  const factory CommercialDocumentLine({
    required String description,
    String? sku,
    String? barcode,
    String? unitName,
    required double quantity,
    required double unitPrice,
    required double discount,
    required double tax,
    required double lineTotal,
  }) = _CommercialDocumentLine;
}
