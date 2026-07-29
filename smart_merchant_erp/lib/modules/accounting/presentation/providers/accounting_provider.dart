import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'accounting_provider.g.dart';

@riverpod
class ChartOfAccountsNotifier extends _$ChartOfAccountsNotifier {
  @override
  Stream<List<Map<String, dynamic>>> build() {
    return const Stream.empty();
  }
}
