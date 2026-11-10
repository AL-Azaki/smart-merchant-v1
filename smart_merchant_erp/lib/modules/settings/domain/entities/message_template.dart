import 'dart:convert';
import 'package:equatable/equatable.dart';

enum MessageTemplateType {
  paymentReminder, // قوالب المطالبة والتذكير
  paymentReceipt,  // قوالب إشعارات السداد
}

extension MessageTemplateTypeX on MessageTemplateType {
  String get titleAr {
    switch (this) {
      case MessageTemplateType.paymentReminder:
        return 'تذكير بالسداد';
      case MessageTemplateType.paymentReceipt:
        return 'إشعار استلام دفعة';
    }
  }

  String get descriptionAr {
    switch (this) {
      case MessageTemplateType.paymentReminder:
        return 'تنبيه العميل بضرورة سداد الرصيد المستحق';
      case MessageTemplateType.paymentReceipt:
        return 'إشعار العميل فور استلام دفعة مالية';
    }
  }
}

class MessageTemplate extends Equatable {
  final String id;
  final String title;
  final MessageTemplateType type;
  final String content;
  final bool isDefault;
  final bool isSystem;
  final DateTime createdAt;

  const MessageTemplate({
    required this.id,
    required this.title,
    required this.type,
    required this.content,
    required this.createdAt,
    this.isDefault = false,
    this.isSystem = false,
  });

  MessageTemplate copyWith({
    String? id,
    String? title,
    MessageTemplateType? type,
    String? content,
    bool? isDefault,
    bool? isSystem,
    DateTime? createdAt,
  }) {
    return MessageTemplate(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      content: content ?? this.content,
      isDefault: isDefault ?? this.isDefault,
      isSystem: isSystem ?? this.isSystem,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Replace variables with actual values
  String render({
    required String customerName,
    String? currentBalance,
    String? paidAmount,
  }) {
    var text = content;
    text = text.replaceAll('{اسم_العميل}', customerName);
    if (currentBalance != null) {
      text = text.replaceAll('{الرصيد_الحالي}', currentBalance);
    }
    if (paidAmount != null) {
      text = text.replaceAll('{المبلغ_المسدد}', paidAmount);
    }
    return text;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'type': type.name,
      'content': content,
      'isDefault': isDefault,
      'isSystem': isSystem,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory MessageTemplate.fromMap(Map<String, dynamic> map) {
    return MessageTemplate(
      id: map['id'] as String,
      title: map['title'] as String,
      type: MessageTemplateType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => MessageTemplateType.paymentReminder,
      ),
      content: map['content'] as String,
      isDefault: (map['isDefault'] as bool?) ?? false,
      isSystem: (map['isSystem'] as bool?) ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory MessageTemplate.fromJson(String source) =>
      MessageTemplate.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  List<Object?> get props => [id, title, type, content, isDefault, isSystem, createdAt];
}

