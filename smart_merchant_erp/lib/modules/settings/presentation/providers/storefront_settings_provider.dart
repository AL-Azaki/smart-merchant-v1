import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/di/manual_injection.dart';
import '../../domain/entities/storefront_settings.dart';
import '../../domain/repositories/storefront_repository.dart';

enum SlugCheckStatus {
  initial,
  checking,
  available,
  unavailable,
  invalid,
}

class StorefrontSettingsState extends Equatable {
  final bool isLoading;
  final bool isSaving;
  final StorefrontSettings? settings;
  final String? errorMessage;
  final Map<String, List<String>> validationErrors;
  final bool isSuccess;

  // Slug check status & feedback
  final SlugCheckStatus slugStatus;
  final String? slugMessage;
  final String? checkedSlug;

  const StorefrontSettingsState({
    this.isLoading = false,
    this.isSaving = false,
    this.settings,
    this.errorMessage,
    this.validationErrors = const {},
    this.isSuccess = false,
    this.slugStatus = SlugCheckStatus.initial,
    this.slugMessage,
    this.checkedSlug,
  });

  StorefrontSettingsState copyWith({
    bool? isLoading,
    bool? isSaving,
    StorefrontSettings? settings,
    String? errorMessage,
    Map<String, List<String>>? validationErrors,
    bool? isSuccess,
    SlugCheckStatus? slugStatus,
    String? slugMessage,
    String? checkedSlug,
    bool clearErrors = false,
    bool clearSuccess = false,
    bool clearSlugInfo = false,
  }) {
    return StorefrontSettingsState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      settings: settings ?? this.settings,
      errorMessage:
          clearErrors ? null : (errorMessage ?? this.errorMessage),
      validationErrors: clearErrors
          ? const {}
          : (validationErrors ?? this.validationErrors),
      isSuccess: clearSuccess ? false : (isSuccess ?? this.isSuccess),
      slugStatus: slugStatus ?? this.slugStatus,
      slugMessage: clearSlugInfo ? null : (slugMessage ?? this.slugMessage),
      checkedSlug: clearSlugInfo ? null : (checkedSlug ?? this.checkedSlug),
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isSaving,
        settings,
        errorMessage,
        validationErrors,
        isSuccess,
        slugStatus,
        slugMessage,
        checkedSlug,
      ];
}

class StorefrontSettingsNotifier
    extends StateNotifier<StorefrontSettingsState> {
  final StorefrontRepository _repository;
  Timer? _debounceTimer;
  String? _latestRequestedSlug;

  StorefrontSettingsNotifier({StorefrontRepository? repository})
      : _repository = repository ?? getIt<StorefrontRepository>(),
        super(const StorefrontSettingsState()) {
    loadSettings();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  static const Set<String> reservedSlugs = {
    'admin',
    'api',
    'app',
    'assets',
    'auth',
    'bootstrap',
    'cart',
    'checkout',
    'dashboard',
    'device',
    'devices',
    'health',
    'login',
    'logout',
    'media',
    'order',
    'orders',
    'platform',
    'product',
    'products',
    'register',
    'root',
    'session',
    'settings',
    'shop',
    'status',
    'storage',
    'store',
    'storefront',
    'subscription',
    'subscriptions',
    'sync',
    'user',
    'users',
    'vendor',
  };

  /// Normalizes a slug to lowercase, hyphen-separated canonical format.
  static String normalizeSlug(String raw) {
    var s = raw.trim().toLowerCase();
    s = s.replaceAll(RegExp(r'[\s_]+'), '-');
    s = s.replaceAll(RegExp(r'-+'), '-');
    while (s.startsWith('-')) {
      s = s.substring(1);
    }
    while (s.endsWith('-')) {
      s = s.substring(0, s.length - 1);
    }
    return s;
  }

  /// Validates slug syntax (latin alphanumeric and hyphens, 3-60 chars).
  static bool isValidSlugSyntax(String slug) {
    if (slug.length < 3 || slug.length > 60) {
      return false;
    }
    final regex = RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$');
    return regex.hasMatch(slug);
  }

  /// Loads storefront settings from Laravel backend.
  Future<void> loadSettings() async {
    state = state.copyWith(
      isLoading: true,
      clearErrors: true,
      clearSuccess: true,
    );

    final result = await _repository.getSettings();

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        );
      },
      (settings) {
        state = state.copyWith(
          isLoading: false,
          settings: settings,
          slugStatus: (settings.storefrontSlug != null &&
                  settings.storefrontSlug!.isNotEmpty)
              ? SlugCheckStatus.available
              : SlugCheckStatus.initial,
          checkedSlug: settings.storefrontSlug,
        );
      },
    );
  }

  /// Called whenever the merchant changes the slug in the text field.
  void onSlugChanged(String rawValue) {
    _debounceTimer?.cancel();

    if (rawValue.trim().isEmpty) {
      state = state.copyWith(
        slugStatus: SlugCheckStatus.initial,
        clearSlugInfo: true,
      );
      return;
    }

    // 1. Check for Arabic characters
    if (RegExp(r'[\u0600-\u06FF]').hasMatch(rawValue)) {
      state = state.copyWith(
        slugStatus: SlugCheckStatus.invalid,
        slugMessage:
            'رابط المتجر يجب أن يكون باللغة الإنجليزية ولا يقبل الأحرف العربية.',
        checkedSlug: rawValue,
      );
      return;
    }

    // 2. Check for invalid symbols
    if (RegExp(r'[^a-zA-Z0-9\s_-]').hasMatch(rawValue)) {
      state = state.copyWith(
        slugStatus: SlugCheckStatus.invalid,
        slugMessage:
            'رابط المتجر يحتوي على رموز غير مسموحة. يُسمح فقط بالأحرف الإنجليزية والأرقام والشرطات.',
        checkedSlug: rawValue,
      );
      return;
    }

    final normalized = normalizeSlug(rawValue);

    if (normalized.isEmpty) {
      state = state.copyWith(
        slugStatus: SlugCheckStatus.initial,
        clearSlugInfo: true,
      );
      return;
    }

    // 3. Length checks
    if (normalized.length < 3) {
      state = state.copyWith(
        slugStatus: SlugCheckStatus.invalid,
        slugMessage: 'رابط المتجر يجب ألا يقل عن 3 أحرف.',
        checkedSlug: normalized,
      );
      return;
    }

    if (normalized.length > 60) {
      state = state.copyWith(
        slugStatus: SlugCheckStatus.invalid,
        slugMessage: 'رابط المتجر يجب ألا يتجاوز 60 حرفاً.',
        checkedSlug: normalized,
      );
      return;
    }

    // 4. Reserved slugs check
    if (reservedSlugs.contains(normalized)) {
      state = state.copyWith(
        slugStatus: SlugCheckStatus.invalid,
        slugMessage: 'رابط المتجر المختار محجوز للنظام، يرجى اختيار رابط آخر.',
        checkedSlug: normalized,
      );
      return;
    }

    // 5. Check syntax locally
    if (!isValidSlugSyntax(normalized)) {
      state = state.copyWith(
        slugStatus: SlugCheckStatus.invalid,
        slugMessage:
            'رابط المتجر يجب أن يتكون من 3 إلى 60 حرفاً، ويحتوي على أحرف إنجليزية وأرقام وشرطات فقط.',
        checkedSlug: normalized,
      );
      return;
    }

    // 6. Check if it's the exact same slug already owned by this merchant
    if (state.settings?.storefrontSlug != null &&
        normalized == state.settings!.storefrontSlug) {
      state = state.copyWith(
        slugStatus: SlugCheckStatus.available,
        slugMessage: 'رابط المتجر الحالي الخاص بمنشأتك',
        checkedSlug: normalized,
      );
      return;
    }

    // Debounce availability check (500ms)
    state = state.copyWith(
      slugStatus: SlugCheckStatus.checking,
      checkedSlug: normalized,
      clearSlugInfo: true,
    );

    _latestRequestedSlug = normalized;

    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      final targetSlug = normalized;
      final result = await _repository.checkSlugAvailability(targetSlug);

      // Protect against stale responses: only apply if the user hasn't changed the input
      if (_latestRequestedSlug != targetSlug) {
        return;
      }

      result.fold(
        (failure) {
          state = state.copyWith(
            slugStatus: SlugCheckStatus.unavailable,
            slugMessage: failure.message,
          );
        },
        (availability) {
          if (availability.available) {
            state = state.copyWith(
              slugStatus: SlugCheckStatus.available,
              slugMessage: 'الرابط متاح للاستخدام!',
            );
          } else {
            state = state.copyWith(
              slugStatus: SlugCheckStatus.unavailable,
              slugMessage: 'عذراً، هذا الرابط محجوز أو غير متاح.',
            );
          }
        },
      );
    });
  }

  /// Saves settings as draft (storefront_active = false).
  Future<bool> saveDraft(StorefrontSettings updated) async {
    if (state.isSaving) {
      return false;
    }

    state = state.copyWith(
      isSaving: true,
      clearErrors: true,
      clearSuccess: true,
    );

    final payload = updated.copyWith(storefrontActive: false);
    final result = await _repository.updateSettings(payload);

    return result.fold(
      (failure) {
        final fieldErrors = failure is StorefrontValidationFailure
            ? failure.fieldErrors
            : <String, List<String>>{};
        state = state.copyWith(
          isSaving: false,
          errorMessage: failure.message,
          validationErrors: fieldErrors,
        );
        return false;
      },
      (savedSettings) {
        state = state.copyWith(
          isSaving: false,
          settings: savedSettings,
          isSuccess: true,
          slugStatus: SlugCheckStatus.available,
          checkedSlug: savedSettings.storefrontSlug,
        );
        return true;
      },
    );
  }

  /// Validates requirements and activates the storefront (storefront_active = true).
  Future<bool> activateStore(StorefrontSettings updated) async {
    if (state.isSaving) {
      return false;
    }

    // Local pre-validation for optimal user experience
    final errors = <String, List<String>>{};

    final slug = updated.storefrontSlug?.trim();
    if (slug == null || slug.isEmpty) {
      errors['storefront_slug'] = ['يجب تحديد رابط (Slug) صالح لتفعيل المتجر.'];
    } else if (!isValidSlugSyntax(slug)) {
      errors['storefront_slug'] = [
        'صيغة رابط المتجر غير صحيحة. يجب أن يحتوي على أحرف إنجليزية وأرقام فقط.'
      ];
    } else if (state.slugStatus == SlugCheckStatus.unavailable) {
      errors['storefront_slug'] = [
        'الرابط المحدد محجوز بالفعل لمنشأة أخرى.'
      ];
    }

    final hasName = (updated.storefrontDisplayName != null &&
            updated.storefrontDisplayName!.trim().isNotEmpty) ||
        (updated.effectiveDisplayName != null &&
            updated.effectiveDisplayName!.trim().isNotEmpty);

    if (!hasName) {
      errors['storefront_display_name'] = [
        'يجب توفير اسم معتمد للمتجر لتفعيله.'
      ];
    }

    final hasContact = (updated.storefrontWhatsapp != null &&
            updated.storefrontWhatsapp!.trim().isNotEmpty) ||
        (updated.storefrontPhone != null &&
            updated.storefrontPhone!.trim().isNotEmpty) ||
        (updated.effectivePhone != null &&
            updated.effectivePhone!.trim().isNotEmpty);

    if (!hasContact) {
      errors['storefront_whatsapp'] = [
        'يجب توفير وسيلة تواصل واحدة على الأقل (واتساب أو هاتف) لتفعيل المتجر.'
      ];
    }

    if (errors.isNotEmpty) {
      state = state.copyWith(
        validationErrors: errors,
        errorMessage: 'يرجى استكمال الحقول الإلزامية قبل تفعيل المتجر.',
      );
      return false;
    }

    state = state.copyWith(
      isSaving: true,
      clearErrors: true,
      clearSuccess: true,
    );

    final payload = updated.copyWith(storefrontActive: true);
    final result = await _repository.updateSettings(payload);

    return result.fold(
      (failure) {
        final fieldErrors = failure is StorefrontValidationFailure
            ? failure.fieldErrors
            : <String, List<String>>{};
        state = state.copyWith(
          isSaving: false,
          errorMessage: failure.message,
          validationErrors: fieldErrors,
        );
        return false;
      },
      (savedSettings) {
        state = state.copyWith(
          isSaving: false,
          settings: savedSettings,
          isSuccess: true,
          slugStatus: SlugCheckStatus.available,
          checkedSlug: savedSettings.storefrontSlug,
        );
        return true;
      },
    );
  }

  /// Deactivates the storefront without clearing saved configurations.
  Future<bool> deactivateStore(StorefrontSettings current) async {
    return saveDraft(current.copyWith(storefrontActive: false));
  }
}

/// Provider for storefront settings state management.
final storefrontSettingsProvider =
    StateNotifierProvider.autoDispose<StorefrontSettingsNotifier,
        StorefrontSettingsState>((ref) {
  return StorefrontSettingsNotifier();
});
