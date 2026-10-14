import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Lightweight notifier to synchronize search queries between the top action bar
/// and the POS product catalog grid without unnecessary re-renders.
final posSearchQueryProvider =
    NotifierProvider<PosSearchQueryNotifier, String>(PosSearchQueryNotifier.new);

class PosSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void update(String query) {
    state = query.trim().toLowerCase();
  }

  void clear() {
    state = '';
  }
}
