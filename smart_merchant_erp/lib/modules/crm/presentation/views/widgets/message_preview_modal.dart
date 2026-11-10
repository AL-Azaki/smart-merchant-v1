import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../shared/design_system/tokens/colors.dart';
import '../../../../settings/domain/entities/message_template.dart';
import '../../../../settings/presentation/providers/message_templates_provider.dart';

class MessagePreviewModal extends ConsumerStatefulWidget {
  final String customerName;
  final String? customerPhone;
  final double? currentBalance;
  final double? paidAmount;
  final MessageTemplateType initialType;

  const MessagePreviewModal({
    required this.customerName,
    super.key,
    this.customerPhone,
    this.currentBalance,
    this.paidAmount,
    this.initialType = MessageTemplateType.paymentReminder,
  });

  static Future<void> show({
    required BuildContext context,
    required String customerName,
    String? customerPhone,
    double? currentBalance,
    double? paidAmount,
    MessageTemplateType initialType = MessageTemplateType.paymentReminder,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MessagePreviewModal(
        customerName: customerName,
        customerPhone: customerPhone,
        currentBalance: currentBalance,
        paidAmount: paidAmount,
        initialType: initialType,
      ),
    );
  }

  @override
  ConsumerState<MessagePreviewModal> createState() => _MessagePreviewModalState();
}

class _MessagePreviewModalState extends ConsumerState<MessagePreviewModal> {
  late TextEditingController _textController;
  late TextEditingController _phoneController;
  MessageTemplate? _selectedTemplate;
  late MessageTemplateType _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    _phoneController = TextEditingController(text: widget.customerPhone ?? '');
    _textController = TextEditingController();

    // Initialize with active/default template after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyDefaultTemplate();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _applyDefaultTemplate() {
    final templatesState = ref.read(messageTemplatesProvider);
    final defaultTpl = templatesState.getDefault(_selectedType);
    if (defaultTpl != null) {
      _selectTemplate(defaultTpl);
    }
  }

  void _selectTemplate(MessageTemplate template) {
    setState(() {
      _selectedTemplate = template;
      final balanceStr = widget.currentBalance != null
          ? '${widget.currentBalance!.toStringAsFixed(2)} ر.ي'
          : '0.00 ر.ي';
      final paidStr = widget.paidAmount != null
          ? '${widget.paidAmount!.toStringAsFixed(2)} ر.ي'
          : '0.00 ر.ي';

      _textController.text = template.render(
        customerName: widget.customerName,
        currentBalance: balanceStr,
        paidAmount: paidStr,
      );
    });
  }

  String _cleanPhoneForWhatsApp(String phone) {
    var digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('00')) {
      digits = digits.substring(2);
    }
    // If local 9 digits starting with 7 (Yemeni standard)
    if (digits.length == 9 && digits.startsWith('7')) {
      digits = '967$digits';
    } else if (digits.length == 10 && digits.startsWith('07')) {
      digits = '967${digits.substring(1)}';
    }
    return digits;
  }

  Future<void> _sendViaWhatsApp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _showWarning('يرجى إدخال رقم هاتف العميل أولاً');
      return;
    }

    final message = _textController.text.trim();
    if (message.isEmpty) {
      _showWarning('لا يمكن إرسال رسالة فارغة');
      return;
    }

    final cleanPhone = _cleanPhoneForWhatsApp(phone);
    final urlString = 'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}';
    final uri = Uri.parse(urlString);

    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        _showWarning('تعذر فتح تطبيق واتساب. تم نسخ النص إلى الحافظة.');
        await Clipboard.setData(ClipboardData(text: message));
      } else if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      await Clipboard.setData(ClipboardData(text: message));
      _showWarning('تعذر فتح الرابط. تم نسخ الرسالة إلى الحافظة.');
    }
  }

  Future<void> _sendViaSms() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _showWarning('يرجى إدخال رقم هاتف العميل أولاً');
      return;
    }

    final message = _textController.text.trim();
    if (message.isEmpty) {
      _showWarning('لا يمكن إرسال رسالة فارغة');
      return;
    }

    final uri = Uri(
      scheme: 'sms',
      path: phone,
      queryParameters: {'body': message},
    );

    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        _showWarning('تعذر فتح تطبيق الرسائل. تم نسخ النص.');
        await Clipboard.setData(ClipboardData(text: message));
      } else if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      await Clipboard.setData(ClipboardData(text: message));
      _showWarning('تم نسخ الرسالة إلى الحافظة.');
    }
  }

  Future<void> _copyToClipboard() async {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: text));
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم نسخ نص الرسالة إلى الحافظة بنجاح'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showWarning(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final templatesState = ref.watch(messageTemplatesProvider);
    final availableTemplates = templatesState.getByType(_selectedType);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Modal Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.mark_email_read_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedType == MessageTemplateType.paymentReminder
                              ? 'إرسال تذكير بالسداد'
                              : 'إرسال إشعار استلام دفعة',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'العميل: ${widget.customerName}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(height: 24),

            // Type Segment Selector
            SegmentedButton<MessageTemplateType>(
              segments: const [
                ButtonSegment(
                  value: MessageTemplateType.paymentReminder,
                  label: Text('تذكير بالسداد'),
                  icon: Icon(Icons.notifications_active_outlined, size: 18),
                ),
                ButtonSegment(
                  value: MessageTemplateType.paymentReceipt,
                  label: Text('إشعار سداد'),
                  icon: Icon(Icons.receipt_long_outlined, size: 18),
                ),
              ],
              selected: {_selectedType},
              onSelectionChanged: (val) {
                setState(() {
                  _selectedType = val.first;
                });
                _applyDefaultTemplate();
              },
            ),
            const SizedBox(height: 16),

            // Template Selector Dropdown
            if (availableTemplates.isNotEmpty) ...[
              Row(
                children: [
                  const Text(
                    'اختر القالب:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedTemplate?.id,
                          isExpanded: true,
                          hint: const Text('اختر قالباً'),
                          items: availableTemplates.map((tpl) {
                            return DropdownMenuItem<String>(
                              value: tpl.id,
                              child: Row(
                                children: [
                                  Expanded(child: Text(tpl.title)),
                                  if (tpl.isDefault)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'المعتمد',
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (id) {
                            if (id != null) {
                              final found = availableTemplates
                                  .firstWhere((t) => t.id == id);
                              _selectTemplate(found);
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
            ],

            // Customer Phone Field (editable in case missing or wrong)
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'رقم هاتف العميل',
                hintText: '77XXXXXXX',
                prefixIcon: const Icon(Icons.phone_iphone_rounded),
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: _phoneController.text.isEmpty
                    ? const Tooltip(
                        message: 'رقم الهاتف غير مسجل في ملف العميل',
                        child: Icon(Icons.warning_amber_rounded, color: Colors.orange),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 14),

            // Live Editable Message Field
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'معاينة نص الرسالة (يمكنك التعديل اليدوي قبل الإرسال):',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: _copyToClipboard,
                  icon: const Icon(Icons.copy_rounded, size: 14),
                  label: const Text('نسخ', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _textController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'نص الرسالة...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons for Delivery Channels (WhatsApp & SMS)
            Row(
              children: [
                // WhatsApp Button
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _sendViaWhatsApp,
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                    label: const Text(
                      'إرسال واتساب',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // SMS Button
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _sendViaSms,
                    icon: const Icon(Icons.sms_outlined, size: 20),
                    label: const Text(
                      'إرسال SMS',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

