import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../providers/pos_provider.dart';
import 'customer_select_modal.dart';

import 'pos_compact_checkout_dock.dart';

/// Backward compatibility wrapper for QuickCheckoutBar.
/// Delegates directly to [PosCompactCheckoutDock] for ultra-compact layout.
class QuickCheckoutBar extends StatelessWidget {
  final VoidCallback? onSaleCompleted;

  const QuickCheckoutBar({
    super.key,
    this.onSaleCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return const PosCompactCheckoutDock();
  }
}

