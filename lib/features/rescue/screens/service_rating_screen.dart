import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/attachment_provider.dart';
import '../../activity/models/rescue_order.dart';
import '../../activity/providers/activity_provider.dart';
import '../../home/theme/home_theme.dart';
import '../data/service_rating_tags.dart';
import '../providers/service_rating_provider.dart';
import '../theme/service_rating_theme.dart';
import '../widgets/image_picker_box.dart';
import '../widgets/quick_tags.dart';
import '../widgets/rating_stars.dart';
import '../widgets/service_rating_summary_card.dart';

class ServiceRatingScreen extends ConsumerStatefulWidget {
  const ServiceRatingScreen({super.key, this.orderId});
  final String? orderId;
  @override
  ConsumerState<ServiceRatingScreen> createState() =>
      _ServiceRatingScreenState();
}

class _ServiceRatingScreenState extends ConsumerState<ServiceRatingScreen> {
  final _comment = TextEditingController();
  Object _pickerKey = Object();
  int _selectedStars = 0;
  Set<String> _selectedTags = {};
  Uint8List? _photo;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  void _restore() {
    final review = ref.read(serviceRatingsProvider)[widget.orderId];
    final order = ref.read(activityProvider).orderById(widget.orderId);
    _selectedStars = order?.rating?.round().clamp(0, 5) ?? review?.stars ?? 0;
    _selectedTags = {...?review?.tagIds};
    _photo = review?.photo;
    _comment.text = review?.comment ?? '';
  }

  @override
  void didUpdateWidget(ServiceRatingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.orderId != widget.orderId) {
      _pickerKey = Object();
      _submitting = false;
      _restore();
    }
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  void _home() {
    FocusManager.instance.primaryFocus?.unfocus();
    context.go('/trang-chu');
  }

  void _feedback(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  Future<void> _pickPhoto() async {
    final key = _pickerKey;
    final photo = await ref
        .read(attachmentProvider(key).notifier)
        .pick(useCamera: false);
    if (!mounted || key != _pickerKey || photo == null) return;
    setState(() => _photo = photo);
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (_selectedStars == 0) {
      _feedback('Vui lòng chọn từ 1 đến 5 sao.');
      return;
    }
    setState(() => _submitting = true);
    final orderId = widget.orderId;
    try {
      await ref
          .read(serviceRatingsProvider.notifier)
          .submit(
            orderId!,
            stars: _selectedStars,
            tagIds: _selectedTags,
            comment: _comment.text,
            photo: _photo,
          );
      if (!mounted || widget.orderId != orderId) return;
      _feedback('Cảm ơn bạn đã đánh giá!');
      _home();
    } catch (error) {
      if (mounted && widget.orderId == orderId) {
        _feedback(
          error is StateError
              ? error.message.toString()
              : 'Không thể gửi đánh giá. Vui lòng thử lại.',
        );
      }
    } finally {
      if (mounted && widget.orderId == orderId) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = ref.watch(activityProvider).orderById(widget.orderId);
    final summary = ref.watch(serviceRatingSummaryProvider(widget.orderId));
    final picker = ref.watch(attachmentProvider(_pickerKey));
    final canRate = order?.status == RescueOrderStatus.completed;
    final theme = HomeTheme.light;
    return PopScope(
      canPop: !_submitting,
      child: Theme(
        data: theme.copyWith(
          colorScheme: theme.colorScheme.copyWith(
            primary: ServiceRatingColors.red,
            primaryContainer: ServiceRatingColors.selected,
            onPrimary: Colors.white,
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
            leading: IconButton(
              tooltip: 'Quay lại',
              onPressed: _submitting
                  ? null
                  : () => context.canPop() ? context.pop() : _home(),
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: ServiceRatingColors.muted,
              ),
            ),
            title: const Text(
              'Đánh giá dịch vụ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: ServiceRatingColors.text,
              ),
            ),
          ),
          body: summary == null || !canRate
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.rate_review_outlined,
                          color: ServiceRatingColors.muted,
                          size: 42,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          summary == null ? 'Không tìm thấy đơn cứu hộ.' : 'Bạn có thể đánh giá sau khi đơn cứu hộ hoàn thành.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _home,
                          child: const Text('Về Trang chủ'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: SingleChildScrollView(
                            key: const ValueKey('service-rating-scroll'),
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ServiceRatingSummaryCard(summary: summary),
                                const SizedBox(height: 24),
                                const Center(
                                  child: SizedBox(
                                    width: 260,
                                    child: Text(
                                      'Trải nghiệm cứu hộ của bạn thế nào?',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w700,
                                        height: 1.3,
                                        color: ServiceRatingColors.text,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                RatingStars(
                                  selectedStars: _selectedStars,
                                  onChanged: _submitting
                                      ? null
                                      : (value) => setState(
                                          () => _selectedStars = value,
                                        ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  const [
                                    'Chạm vào sao để đánh giá',
                                    'Rất không hài lòng',
                                    'Chưa hài lòng',
                                    'Bình thường',
                                    'Hài lòng',
                                    'Rất hài lòng',
                                  ][_selectedStars],
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: ServiceRatingColors.muted,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                QuickTags(
                                  tags: serviceRatingTags,
                                  selectedIds: _selectedTags,
                                  onChanged: _submitting
                                      ? null
                                      : (id, selected) => setState(() {
                                          if (selected) {
                                            _selectedTags.add(id);
                                          } else {
                                            _selectedTags.remove(id);
                                          }
                                        }),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Nhận xét',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: ServiceRatingColors.text,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  key: const ValueKey('service-rating-comment'),
                                  controller: _comment,
                                  enabled: !_submitting,
                                  minLines: 3,
                                  maxLines: 5,
                                  maxLength: 1000,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    height: 1.5,
                                    color: ServiceRatingColors.text,
                                  ),
                                  decoration: InputDecoration(
                                    counterText: '',
                                    filled: false,
                                    contentPadding: const EdgeInsets.all(14),
                                    hintText: 'Chia sẻ thêm chi tiết trải nghiệm của bạn (không bắt buộc)...',
                                    hintStyle: const TextStyle(
                                      fontSize: 13,
                                      color: ServiceRatingColors.muted,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: ServiceRatingColors.border,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: ServiceRatingColors.red,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                ImagePickerBox(
                                  photo: _photo,
                                  picking: picker.picking,
                                  error: picker.error,
                                  onPick: _submitting || picker.picking
                                      ? null
                                      : _pickPhoto,
                                  onRemove: _submitting || picker.picking
                                      ? null
                                      : () => setState(() => _photo = null),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    _RatingActions(
                      submitting: _submitting,
                      onSubmit: _submitting || picker.picking ? null : _submit,
                      onSkip: _submitting ? null : _home,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _RatingActions extends StatelessWidget {
  const _RatingActions({
    required this.submitting,
    required this.onSubmit,
    required this.onSkip,
  });
  final bool submitting;
  final VoidCallback? onSubmit, onSkip;
  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: ServiceRatingColors.border)),
    ),
    child: SafeArea(
      top: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton(
                  key: const ValueKey('service-rating-submit'),
                  onPressed: onSubmit,
                  style: FilledButton.styleFrom(
                    backgroundColor: ServiceRatingColors.red,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'GỬI ĐÁNH GIÁ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
                TextButton(
                  key: const ValueKey('service-rating-skip'),
                  onPressed: onSkip,
                  style: TextButton.styleFrom(
                    foregroundColor: ServiceRatingColors.muted,
                  ),
                  child: const Text('Bỏ qua', style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
