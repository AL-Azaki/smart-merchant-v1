import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../app/di/injection.dart';
import '../../../../kernel/core/application_context.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../../../database/daos/fixed_assets_dao.dart';
import '../../application/services/fixed_asset_application_service.dart';

part 'fixed_assets_provider.g.dart';

@riverpod
class FixedAssetsSearchQuery extends _$FixedAssetsSearchQuery {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }
}

@riverpod
Stream<List<FixedAsset>> fixedAssetsList(Ref ref) {
  final dao = getIt<FixedAssetsDao>();
  final appContext = getIt<ApplicationContext>();
  final query = ref.watch(fixedAssetsSearchQueryProvider);
  
  final businessId = appContext.currentBusinessId;
  if (businessId.isEmpty) return Stream.value([]);
  
  return dao.watchFixedAssets(FixedAssetFilter(
    businessId: businessId,
    searchQuery: query,
  ));
}

@riverpod
class FixedAssetsNotifier extends _$FixedAssetsNotifier {
  @override
  void build() {
    return;
  }

  Future<bool> saveAsset(Map<String, dynamic> data) async {
    try {
      final service = getIt<FixedAssetApplicationService>();
      final command = FixedAssetCommand(
        id: data['id']?.toString(),
        assetCode: data['code']?.toString() ?? 'FA-${DateTime.now().millisecondsSinceEpoch}',
        assetName: data['name']?.toString() ?? 'New Asset',
        assetCategoryId: data['category']?.toString(),
        locationId: data['location']?.toString(),
        purchaseDate: data['purchase_date'] != null ? DateTime.parse(data['purchase_date'].toString()) : DateTime.now(),
        purchasePrice: data['cost'] != null ? double.tryParse(data['cost'].toString()) ?? 0.0 : 0.0,
        currentBookValue: data['cost'] != null ? double.tryParse(data['cost'].toString()) ?? 0.0 : 0.0,
        usefulLifeMonths: 12,
        status: data['status'] == 'broken' ? 'Disposed' : data['status'] == 'needs_maintenance' ? 'Draft' : 'Active',
        isActive: data['status'] != 'broken',
      );
      final result = await service.saveFixedAsset(command);
      return result.isRight();
    } catch (e) {
      return false;
    }
  }
}
