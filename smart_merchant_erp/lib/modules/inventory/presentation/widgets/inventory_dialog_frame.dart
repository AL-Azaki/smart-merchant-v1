import 'dart:math' as math;
import 'package:flutter/material.dart';

Future<bool> confirmDiscardInventoryEdits(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تجاهل المدخلات غير المحفوظة؟'),
        content: const Text(
          'لديك تعديلات لم تُحفظ بعد. يمكنك متابعة العمل أو إغلاق النافذة وتجاهلها.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('متابعة العمل'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تجاهل المدخلات'),
          ),
        ],
      ),
    ) ??
    false;

class InventoryDialogFrame extends StatelessWidget {
  final String title, actionLabel;
  final IconData icon;
  final Widget child;
  final VoidCallback onClose, onAction;
  final bool busy;
  final String? error;
  final bool showCancel;
  const InventoryDialogFrame({
    required this.title, required this.actionLabel, required this.icon, required this.child, required this.onClose, required this.onAction, super.key,
    this.busy = false,
    this.error,
    this.showCancel = true,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !busy) {
          onClose();
        }
      },
      child: Dialog(
        insetPadding: const EdgeInsets.all(16),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: LayoutBuilder(
            builder: (context, constraints) => SizedBox(
              height: math.min(850, constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: .09,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, color: theme.colorScheme.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'إغلاق',
                          onPressed: busy ? null : onClose,
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: theme.colorScheme.outline.withValues(alpha: .15),
                  ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        error!,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  Expanded(
                    child: IgnorePointer(ignoring: busy, child: child),
                  ),
                  Divider(
                    height: 1,
                    color: theme.colorScheme.outline.withValues(alpha: .15),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        if (showCancel)
                          TextButton(
                            onPressed: busy ? null : onClose,
                            child: const Text('إلغاء'),
                          ),
                        FilledButton.icon(
                          onPressed: busy ? null : onAction,
                          icon: busy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.check_rounded),
                          label: Text(busy ? 'جارٍ الحفظ…' : actionLabel),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(160, 48),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
