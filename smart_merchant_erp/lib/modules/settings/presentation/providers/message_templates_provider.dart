import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/message_template.dart';

class MessageTemplatesState extends Equatable {
  final bool isEnabled;
  final bool isLoading;
  final List<MessageTemplate> templates;

  const MessageTemplatesState({
    this.isEnabled = true,
    this.isLoading = true,
    this.templates = const [],
  });

  MessageTemplatesState copyWith({
    bool? isEnabled,
    bool? isLoading,
    List<MessageTemplate>? templates,
  }) {
    return MessageTemplatesState(
      isEnabled: isEnabled ?? this.isEnabled,
      isLoading: isLoading ?? this.isLoading,
      templates: templates ?? this.templates,
    );
  }

  MessageTemplate? getDefault(MessageTemplateType type) {
    try {
      return templates.firstWhere(
        (t) => t.type == type && t.isDefault,
        orElse: () => templates.firstWhere(
          (t) => t.type == type,
          orElse: () => _defaultTemplates.firstWhere((t) => t.type == type),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  List<MessageTemplate> getByType(MessageTemplateType type) {
    return templates.where((t) => t.type == type).toList();
  }

  @override
  List<Object?> get props => [isEnabled, isLoading, templates];
}

final List<MessageTemplate> _defaultTemplates = [
  MessageTemplate(
    id: 'system_default_reminder',
    title: 'تذكير بالسداد (الافتراضي)',
    type: MessageTemplateType.paymentReminder,
    content:
        'عزيزنا العميل {اسم_العميل}، نود تذكيركم بوجود رصيد مستحق بقيمة {الرصيد_الحالي}. يرجى التكرم بالسداد في أقرب وقت.',
    isDefault: true,
    isSystem: true,
    createdAt: DateTime(2026),
  ),
  MessageTemplate(
    id: 'system_default_receipt',
    title: 'إشعار سداد دفعة (الافتراضي)',
    type: MessageTemplateType.paymentReceipt,
    content:
        'عزيزنا العميل {اسم_العميل}، تم استلام مبلغ {المبلغ_المسدد} بنجاح. رصيدكم الحالي هو {الرصيد_الحالي}. شكراً لتعاملكم معنا.',
    isDefault: true,
    isSystem: true,
    createdAt: DateTime(2026),
  ),
];

class MessageTemplatesNotifier extends StateNotifier<MessageTemplatesState> {
  static const String _storageKeyEnabled = 'msg_templates_enabled_v1';
  static const String _storageKeyTemplates = 'msg_templates_list_v1';

  MessageTemplatesNotifier() : super(const MessageTemplatesState()) {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isEnabled = prefs.getBool(_storageKeyEnabled) ?? true;
      final rawList = prefs.getStringList(_storageKeyTemplates);

      final List<MessageTemplate> loadedList = [];
      if (rawList != null && rawList.isNotEmpty) {
        for (final item in rawList) {
          try {
            loadedList.add(MessageTemplate.fromJson(item));
          } catch (_) {}
        }
      }

      // Ensure system defaults exist
      for (final def in _defaultTemplates) {
        final exists = loadedList.any((t) => t.id == def.id);
        if (!exists) {
          // If no template of this type exists, add default as active
          final hasType = loadedList.any((t) => t.type == def.type);
          loadedList.add(def.copyWith(isDefault: !hasType));
        }
      }

      // Ensure each type has at least one default
      for (final type in MessageTemplateType.values) {
        final typeTemplates = loadedList.where((t) => t.type == type).toList();
        if (typeTemplates.isNotEmpty && !typeTemplates.any((t) => t.isDefault)) {
          final firstIdx = loadedList.indexOf(typeTemplates.first);
          loadedList[firstIdx] = loadedList[firstIdx].copyWith(isDefault: true);
        }
      }

      state = state.copyWith(
        isEnabled: isEnabled,
        templates: loadedList,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(
        isEnabled: true,
        templates: _defaultTemplates,
        isLoading: false,
      );
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_storageKeyEnabled, state.isEnabled);
      final rawList = state.templates.map((t) => t.toJson()).toList();
      await prefs.setStringList(_storageKeyTemplates, rawList);
    } catch (_) {}
  }

  Future<void> toggleEnabled(bool enabled) async {
    state = state.copyWith(isEnabled: enabled);
    await _persist();
  }

  Future<void> addTemplate({
    required String title,
    required MessageTemplateType type,
    required String content,
    bool isDefault = false,
  }) async {
    final newId = 'tpl_${DateTime.now().millisecondsSinceEpoch}';
    final newTemplate = MessageTemplate(
      id: newId,
      title: title.trim(),
      type: type,
      content: content.trim(),
      createdAt: DateTime.now(),
      isDefault: isDefault,
    );

    List<MessageTemplate> updated = List.from(state.templates);
    if (isDefault) {
      updated = updated.map((t) {
        if (t.type == type) {
          return t.copyWith(isDefault: false);
        }
        return t;
      }).toList();
    }
    updated.add(newTemplate);

    state = state.copyWith(templates: updated);
    await _persist();
  }

  Future<void> updateTemplate({
    required String id,
    required String title,
    required String content,
    bool? isDefault,
  }) async {
    final index = state.templates.indexWhere((t) => t.id == id);
    if (index == -1) {
      return;
    }

    final current = state.templates[index];
    final shouldBeDefault = isDefault ?? current.isDefault;

    List<MessageTemplate> updated = List.from(state.templates);
    if (shouldBeDefault) {
      updated = updated.map((t) {
        if (t.type == current.type && t.id != id) {
          return t.copyWith(isDefault: false);
        }
        return t;
      }).toList();
    }

    updated[index] = current.copyWith(
      title: title.trim(),
      content: content.trim(),
      isDefault: shouldBeDefault,
    );

    state = state.copyWith(templates: updated);
    await _persist();
  }

  Future<bool> deleteTemplate(String id) async {
    final tpl = state.templates.firstWhere((t) => t.id == id, orElse: () => _defaultTemplates.first);
    if (tpl.isSystem) {
      return false; // System templates cannot be deleted
    }

    final List<MessageTemplate> updated =
        state.templates.where((t) => t.id != id).toList();

    // If deleted one was default, set another of the same type as default
    if (tpl.isDefault) {
      final remainingOfType = updated.where((t) => t.type == tpl.type).toList();
      if (remainingOfType.isNotEmpty) {
        final firstIdx = updated.indexOf(remainingOfType.first);
        updated[firstIdx] = updated[firstIdx].copyWith(isDefault: true);
      }
    }

    state = state.copyWith(templates: updated);
    await _persist();
    return true;
  }

  Future<void> setDefault(String id, MessageTemplateType type) async {
    final updated = state.templates.map((t) {
      if (t.type == type) {
        return t.copyWith(isDefault: t.id == id);
      }
      return t;
    }).toList();

    state = state.copyWith(templates: updated);
    await _persist();
  }
}

final messageTemplatesProvider =
    StateNotifierProvider<MessageTemplatesNotifier, MessageTemplatesState>((ref) {
  return MessageTemplatesNotifier();
});

