import 'package:flutter/material.dart';
import '../data/home_catalog.dart' show homeSearchKey;
import '../services/support_assistant.dart';
import '../theme/app_theme.dart';
import '../theme/support_palette.dart';
import '../widgets/ui.dart';
import 'support_chat_screen.dart';

typedef _Faq = (String, String);

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key, this.initialTab = 0});
  final int initialTab;
  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  late int _tab = widget.initialTab;
  int? _open;
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Duration _d(BuildContext context) => MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : const Duration(milliseconds: 180);

  List<_Faq> get _items {
    final all = _tab == 0 ? SupportFaq.orders : SupportFaq.payments;
    final q = homeSearchKey(_query);
    if (q.isEmpty) return all;
    return [
      for (final f in all)
        if (homeSearchKey('${f.$1} ${f.$2}').contains(q)) f
    ];
  }

  Widget _header(BuildContext context) => Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
      child: SizedBox(
          height: 48,
          child: Row(children: [
            IconButton(
                tooltip: 'Quay lại',
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.chevron_left_rounded,
                    size: 30, color: SupportPalette.text)),
            Expanded(
                child: Text('Trung tâm hỗ trợ',
                    textAlign: TextAlign.center,
                    style: appText(18,
                        weight: FontWeight.w600, color: SupportPalette.text))),
            const SizedBox(width: 44),
          ])));

  Widget _searchField() => TextField(
      key: const ValueKey('support-search'),
      controller: _search,
      onChanged: (v) => setState(() {
            _query = v;
            _open = null;
          }),
      textInputAction: TextInputAction.search,
      style: appText(14, color: SupportPalette.text),
      decoration: InputDecoration(
          hintText: 'Tìm câu hỏi, ví dụ: mã xác nhận',
          hintStyle: appText(14, color: SupportPalette.textSub),
          filled: true,
          fillColor: Colors.white,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          prefixIcon: const Icon(Icons.search_rounded,
              size: 22, color: SupportPalette.textSub),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Xóa',
                  onPressed: () => setState(() {
                        _search.clear();
                        _query = '';
                        _open = null;
                      }),
                  icon: const Icon(Icons.close_rounded,
                      size: 20, color: SupportPalette.textSub)),
          border: _border(),
          enabledBorder: _border(),
          focusedBorder: _border(AppColors.primary)));

  OutlineInputBorder _border([Color c = SupportPalette.border]) =>
      OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c, width: 1));

  Widget _segmented(BuildContext context) => Container(
      key: const ValueKey('support-tabs'),
      height: 44,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
          color: SupportPalette.inactive,
          borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        for (var i = 0; i < 2; i++)
          Expanded(
              child: Semantics(
                  selected: _tab == i,
                  button: true,
                  child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => setState(() {
                            _tab = i;
                            _open = null;
                          }),
                      child: AnimatedContainer(
                          key: ValueKey('support-tab-$i'),
                          duration: _d(context),
                          curve: Curves.easeOut,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              color: _tab == i
                                  ? AppColors.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10)),
                          child: Text(i == 0 ? 'Đơn hàng' : 'Thanh toán',
                              maxLines: 1,
                              style: appText(14,
                                  weight: FontWeight.w600,
                                  color: _tab == i
                                      ? Colors.white
                                      : SupportPalette.text)))))),
      ]));

  Widget _faqRow(BuildContext context, int index, _Faq f) {
    final open = _open == index;
    return Column(key: ValueKey('support-faq-$index'), children: [
      InkWell(
          onTap: () => setState(() => _open = open ? null : index),
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 56),
                  child: Row(children: [
                    Expanded(
                        child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(f.$1,
                                style: appText(14,
                                    weight: FontWeight.w500,
                                    color: SupportPalette.text,
                                    height: 1.35)))),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                        turns: open ? .25 : 0,
                        duration: _d(context),
                        child: const Icon(Icons.chevron_right_rounded,
                            size: 22, color: SupportPalette.textSub)),
                  ])))),
      AnimatedSize(
          duration: _d(context),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: open
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: SizedBox(
                      width: double.infinity,
                      child: Text(f.$2,
                          style: appText(13,
                              color: SupportPalette.textSub, height: 1.5))))
              : const SizedBox(width: double.infinity)),
    ]);
  }

  Widget _card(List<Widget> rows) => Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: SupportPalette.border)),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0)
            const Divider(
                height: 1, thickness: 1, color: SupportPalette.border),
          rows[i],
        ]
      ]));

  Widget _channel(IconData icon, String title, String sub, VoidCallback tap,
          {Key? key}) =>
      InkWell(
          key: key,
          onTap: tap,
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(children: [
                Icon(icon, size: 24, color: AppColors.primary),
                const SizedBox(width: 14),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(title,
                          style: appText(14,
                              weight: FontWeight.w600,
                              color: SupportPalette.text)),
                      const SizedBox(height: 2),
                      Text(sub,
                          style: appText(12, color: SupportPalette.textSub)),
                    ])),
                const Icon(Icons.chevron_right_rounded,
                    size: 22, color: SupportPalette.textSub),
              ])));

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return Scaffold(
        backgroundColor: SupportPalette.bg,
        body: SafeArea(
            child: Column(children: [
          _header(context),
          Expanded(
              child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                  children: [
                Text('Bạn cần giúp gì?',
                    style: appText(
                        MediaQuery.sizeOf(context).width < 360 ? 25 : 28,
                        weight: FontWeight.w700,
                        color: SupportPalette.text,
                        height: 1.2)),
                const SizedBox(height: 8),
                Text('Tìm câu trả lời nhanh hoặc nhắn cho đội REVO.',
                    style: appText(14,
                        color: SupportPalette.textSub, height: 1.45)),
                const SizedBox(height: 22),
                _searchField(),
                const SizedBox(height: 16),
                _segmented(context),
                const SizedBox(height: 16),
                if (items.isEmpty)
                  Container(
                      key: const ValueKey('support-empty'),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 28),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: SupportPalette.border)),
                      child: Column(children: [
                        Text('Không tìm thấy câu hỏi phù hợp',
                            textAlign: TextAlign.center,
                            style: appText(14,
                                weight: FontWeight.w600,
                                color: SupportPalette.text)),
                        const SizedBox(height: 4),
                        Text('Thử từ khóa khác hoặc đổi sang tab còn lại.',
                            textAlign: TextAlign.center,
                            style: appText(12, color: SupportPalette.textSub)),
                      ]))
                else
                  _card([
                    for (var i = 0; i < items.length; i++)
                      _faqRow(context, i, items[i])
                  ]),
                const SizedBox(height: 28),
                Text('Vẫn chưa giải quyết được?',
                    style: appText(17,
                        weight: FontWeight.w600, color: SupportPalette.text)),
                const SizedBox(height: 12),
                _card([
                  _channel(
                      Icons.chat_bubble_outline_rounded,
                      'Nhắn Trợ lý REVO',
                      'Trả lời ngay, cả ngoài giờ',
                      key: const ValueKey('support-open-chat'),
                      () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SupportChatScreen()))),
                  _channel(
                      Icons.phone_outlined,
                      'Liên hệ Admin',
                      'Cho các trường hợp cần người xử lý',
                      key: const ValueKey('support-contact-admin'),
                      () => showAppSnack(context,
                          'Kênh liên hệ Admin chưa được kết nối trong bản trình diễn.')),
                ]),
              ])),
        ])));
  }
}
