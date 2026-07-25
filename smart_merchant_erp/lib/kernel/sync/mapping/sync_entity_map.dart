/// Authoritative mapping between Flutter entity names and Laravel sync entity identifiers.
/// Matches the REAL [SyncEntityRegistry] on the Laravel side.
///
/// Push-allowed (Flutter → Laravel):
///   categories, brands, units, products, product_units, product_images, inventory_projections
///
/// Pull-allowed (Laravel → Flutter):
///   orders
class SyncEntityMap {
  // Push entities — Flutter is source of truth
  static const pushEntities = <String>[
    'categories',
    'brands',
    'units',
    'products',
    'product_units',
    'product_images',
    'inventory_projections',
  ];

  // Pull entities — Laravel is source of truth
  static const pullEntities = <String>['orders'];

  /// Push dependency ordering. Parents must be pushed before children to satisfy Laravel FK constraints.
  static const pushOrder = <String>[
    'categories',
    'brands',
    'units',
    'products',
    'product_units',
    'product_images',
    'inventory_projections',
  ];

  static bool canPush(String entity) => pushEntities.contains(entity);
  static bool canPull(String entity) => pullEntities.contains(entity);
}
