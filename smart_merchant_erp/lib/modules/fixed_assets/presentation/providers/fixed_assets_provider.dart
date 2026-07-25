import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../app/di/getit_providers.dart';
import '../../../../app/di/injection.dart';
import '../../application/services/fixed_asset_application_service.dart';

part 'fixed_assets_provider.g.dart';

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
        id: data['id'],
        assetCode: data['asset_code'] ?? 'FA-${DateTime.now().millisecondsSinceEpoch}',
        assetName: data['asset_name'] ?? 'New Asset',
        assetCategoryId: data['asset_type'],
        purchaseDate: data['purchase_date'] != null ? DateTime.parse(data['purchase_date']) : DateTime.now(),
        purchasePrice: data['purchase_value'] != null ? double.tryParse(data['purchase_value'].toString()) ?? 0.0 : 0.0,
        currentBookValue: data['purchase_value'] != null ? double.tryParse(data['purchase_value'].toString()) ?? 0.0 : 0.0,
        usefulLifeMonths: 12,
      );
      final result = await service.saveFixedAsset(command);
      return result.isRight();
    } catch (e) {
      return false;
    }
  }
}
