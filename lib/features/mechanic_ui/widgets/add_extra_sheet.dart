import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

/// Mở bottom sheet báo giá phụ tùng phát sinh. Trả về [ExtraItem] hoặc null nếu hủy.
Future<ExtraItem?> showAddExtraSheet(BuildContext context) {
  return showModalBottomSheet<ExtraItem>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const AddExtraSheet(),
  );
}

class AddExtraSheet extends StatefulWidget {
  const AddExtraSheet({super.key});

  @override
  State<AddExtraSheet> createState() => _AddExtraSheetState();
}

class _AddExtraSheetState extends State<AddExtraSheet> {
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String? _error;

  static const _quickAmounts = [20000, 50000, 100000, 200000];

  int get _amount => int.tryParse(_amountCtrl.text) ?? 0;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final desc = _descCtrl.text.trim();
    if (_amount <= 0) {
      setState(() => _error = 'Vui lòng nhập số tiền lớn hơn 0.');
      return;
    }
    if (desc.isEmpty) {
      setState(() => _error = 'Vui lòng nhập mô tả phụ tùng / chi phí.');
      return;
    }
    Navigator.of(context).pop(ExtraItem(description: desc, amount: _amount));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Báo giá phụ tùng phát sinh',
              style: appText(18, weight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Khách sẽ nhận thông báo và xác nhận chi phí này trên app. Chỉ khoản đã được xác nhận mới cộng vào thu nhập.',
              style: appText(13, color: AppColors.textSub),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() => _error = null),
              style: appText(18, weight: FontWeight.w700),
              decoration: InputDecoration(
                labelText: 'Số tiền (đồng)',
                suffixText: 'đ',
                helperText: _amount > 0 ? formatVnd(_amount) : null,
                helperStyle: appText(
                  12.5,
                  weight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final v in _quickAmounts)
                  ActionChip(
                    label: Text(
                      formatVnd(v),
                      style: appText(12.5, weight: FontWeight.w600),
                    ),
                    backgroundColor: AppColors.surface,
                    side: const BorderSide(color: AppColors.border),
                    onPressed: () => setState(() {
                      _amountCtrl.text = '$v';
                      _error = null;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _descCtrl,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() => _error = null),
              style: appText(15),
              decoration: const InputDecoration(
                labelText: 'Mô tả (vd: Thay ruột xe / săm mới)',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 16,
                    color: AppColors.primaryDark,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _error!,
                      style: appText(
                        12.5,
                        weight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSub,
                        side: const BorderSide(color: AppColors.disabled),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      child: Text(
                        'Hủy',
                        style: appText(
                          15,
                          weight: FontWeight.w700,
                          color: AppColors.textSub,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      child: Text(
                        'Gửi khách xác nhận',
                        style: appText(
                          15,
                          weight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
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
