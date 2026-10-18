import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/admin_models.dart';
import '../providers/admin_providers.dart';
import '../theme/admin_theme.dart';
import 'admin_common.dart';

Future<bool> showAdminAction(
  BuildContext context, {
  required AdminActionKind kind,
  required String id,
  required bool approve,
  required String title,
  required String description,
  bool noteRequired = false,
}) async {
  final success = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => Theme(
      data: AdminTheme.light,
      child: AdminActionDialog(
        kind: kind,
        id: id,
        approve: approve,
        title: title,
        description: description,
        noteRequired: noteRequired,
      ),
    ),
  );
  if (context.mounted && success == true) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã xử lý thành công trong phiên mô phỏng.'),
      ),
    );
  }
  return context.mounted && success == true;
}

class AdminActionDialog extends ConsumerStatefulWidget {
  const AdminActionDialog({
    super.key,
    required this.kind,
    required this.id,
    required this.approve,
    required this.title,
    required this.description,
    required this.noteRequired,
  });
  final AdminActionKind kind;
  final String id;
  final bool approve;
  final String title;
  final String description;
  final bool noteRequired;
  @override
  ConsumerState<AdminActionDialog> createState() => _AdminActionDialogState();
}

class _AdminActionDialogState extends ConsumerState<AdminActionDialog> {
  final _form = GlobalKey<FormState>();
  final _note = TextEditingController();
  bool _review = false;
  bool _submitted = false;
  @override
  void initState() {
    super.initState();
    _review = !widget.noteRequired;
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitted = true);
    final success = await ref
        .read(adminActionProvider.notifier)
        .resolve(
          widget.kind,
          widget.id,
          approve: widget.approve,
          note: _note.text.trim(),
        );
    if (mounted && success) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final action = ref.watch(adminActionProvider);
    final busy = action.isLoading;
    final forbidden =
        ref.watch(adminSessionProvider)?.isAdmin != true ||
        (_submitted &&
            action.error is AdminException &&
            (action.error as AdminException).forbidden);
    return PopScope(
      canPop: !busy,
      child: AlertDialog(
        scrollable: true,
        title: Text(
          _review ? 'Xác nhận ${widget.title.toLowerCase()}' : widget.title,
          textAlign: TextAlign.center,
        ),
        content: SizedBox(
          width: 440,
          child: forbidden
              ? const AdminStateView.forbidden()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(widget.description),
                    const SizedBox(height: 16),
                    if (!_review)
                      Form(
                        key: _form,
                        child: TextFormField(
                          controller: _note,
                          minLines: 3,
                          maxLines: 6,
                          maxLength: 500,
                          decoration: const InputDecoration(
                            labelText: 'Lý do / Ghi chú bắt buộc',
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Vui lòng nhập lý do / ghi chú.'
                              : null,
                        ),
                      ),
                    if (_review && _note.text.trim().isNotEmpty)
                      Text('Ghi chú: ${_note.text.trim()}'),
                    if (busy) ...[
                      const SizedBox(height: 16),
                      const LinearProgressIndicator(),
                      const SizedBox(height: 8),
                      const Text('Đang gửi yêu cầu…'),
                    ],
                    if (_submitted && action.hasError && !busy) ...[
                      const SizedBox(height: 16),
                      Text(
                        action.error is AdminException
                            ? (action.error as AdminException).message
                            : 'Lỗi kết nối. Vui lòng thử lại.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
        ),
        actions: [
          TextButton(
            onPressed: busy ? null : () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          if (!forbidden && _review && widget.noteRequired)
            TextButton(
              onPressed: busy
                  ? null
                  : () => setState(() {
                      _review = false;
                      _submitted = false;
                    }),
              child: const Text('Sửa ghi chú'),
            ),
          if (!forbidden)
            FilledButton(
              onPressed: busy
                  ? null
                  : () {
                      if (!_review) {
                        if (_form.currentState!.validate()) {
                          setState(() => _review = true);
                        }
                      } else {
                        _submit();
                      }
                    },
              child: Text(
                !_review
                    ? 'Tiếp tục'
                    : _submitted && action.hasError
                    ? 'Thử lại / Retry'
                    : 'Xác nhận',
              ),
            ),
        ],
      ),
    );
  }
}
