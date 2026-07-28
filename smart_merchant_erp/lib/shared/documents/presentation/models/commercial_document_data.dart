import 'package:freezed_annotation/freezed_annotation.dart';
import 'commercial_document_line.dart';

part 'commercial_document_data.freezed.dart';

@freezed
class CommercialDocumentData with _$CommercialDocumentData {
  const factory CommercialDocumentData({
    required String documentType,
    required String documentNumber,
    required DateTime issueDate,
    
    required String businessName,
    String? businessPhone,
    String? businessAddress,
    String? taxNumber,
    
    String? branchName,
    
    required String customerOrSupplierName,
    String? customerOrSupplierPhone,
    String? customerOrSupplierAddress,
    
    required String currencyCode,
    String? currencySymbol,
    
    String? paymentMethod,
    required String paymentStatus,
    
    required List<CommercialDocumentLine> items,
    
    required double subtotal,
    required double discount,
    required double tax,
    required double grandTotal,
    required double paidAmount,
    required double remainingAmount,
    
    String? notes,
    String? terms,
    
    String? createdBy,
    
    String? sellerSignatureLabel,
    String? customerSignatureLabel,
    String? managementApprovalLabel,
    String? companyStampLabel,
  }) = _CommercialDocumentData;
}
