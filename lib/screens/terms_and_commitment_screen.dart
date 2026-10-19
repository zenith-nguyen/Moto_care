import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/ui.dart';

const _black = Color(0xFF000000);
const _grey = Color(0xFF6B7280);
const _divider = Color(0xFFE5E7EB);
const _boxBorder = Color(0xFF9CA3AF);
const _disabledBg = Color(0xFFDDE3EA);

/// First screen of the app: consent, then Home. There is no welcome step.
/// Used as the app's home and as the destination after signing out.
class TermsEntryScreen extends StatelessWidget {
  const TermsEntryScreen({super.key});
  @override
  Widget build(BuildContext context) => TermsAndCommitmentScreen(
        onAgreed: () {
          if (!appState.demoEnabled) {
            showAppSnack(context,
                'Dịch vụ đăng nhập chưa được cấu hình. Bản trình diễn cần bật REVO_DEMO.');
            return;
          }
          appState.startDemoSession();
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MechanicShell()));
        },
      );
}

class TermsAndCommitmentScreen extends StatefulWidget {
  const TermsAndCommitmentScreen(
      {super.key, this.readOnly = false, this.onAgreed});
  final bool readOnly;

  /// When set, this screen is the root of the flow: there is nothing to go back
  /// to, so no back button is shown and consent calls this instead of popping.
  final VoidCallback? onAgreed;
  @override
  State<TermsAndCommitmentScreen> createState() =>
      _TermsAndCommitmentScreenState();
}

class _Term {
  const _Term(this.title, this.body);
  final String title, body;
}

class _TermsAndCommitmentScreenState extends State<TermsAndCommitmentScreen> {
  /// Never pre-ticked: consent is given by the user on every visit, and only
  /// the Đồng ý button (not the checkbox) records it.
  bool _agreed = false;
  static const _terms = [
    _Term('Tư cách và trách nhiệm',
        'Cung cấp thông tin chính xác, giấy tờ hợp lệ và chịu trách nhiệm về chất lượng dịch vụ.'),
    _Term('An toàn và chuyên nghiệp',
        'Tuân thủ quy trình cứu hộ, bảo đảm an toàn cho khách hàng và phương tiện.'),
    _Term('Thanh toán và chi phí',
        'Báo rõ chi phí trước khi sửa. Chỉ làm hạng mục phát sinh khi khách đã đồng ý.'),
    _Term('Bảo mật thông tin',
        'Không chia sẻ thông tin cá nhân, vị trí hoặc dữ liệu của khách hàng cho bên thứ ba.'),
  ];

  Duration _d(BuildContext context) => MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : const Duration(milliseconds: 180);

  Widget _item(int i, _Term term) => Padding(
      key: ValueKey('term-$i'),
      padding: EdgeInsets.only(bottom: i == _terms.length - 1 ? 0 : 24),
      child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            SizedBox(width: 30, child: Text('${i + 1}', style: _numberStyle)),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(term.title, style: _titleStyle),
                  const SizedBox(height: 6),
                  Text(term.body,
                      style: appText(14, color: _grey, height: 1.5)),
                ])),
          ]));

  static final _numberStyle = appText(19,
      weight: FontWeight.w700, color: AppColors.primary, height: 1.3);

  static final _titleStyle =
      appText(16, weight: FontWeight.w700, color: _black, height: 1.3);

  Widget _consent(BuildContext context) => InkWell(
      key: const ValueKey('terms-consent'),
      borderRadius: BorderRadius.circular(8),
      onTap: () => setState(() => _agreed = !_agreed),
      child: Semantics(
          checked: _agreed,
          child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: AnimatedContainer(
                        key: const ValueKey('terms-box'),
                        duration: _d(context),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                            color: _agreed ? AppColors.primary : Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: _agreed ? AppColors.primary : _boxBorder,
                                width: 1.6)),
                        child: _agreed
                            ? const Icon(Icons.check_rounded,
                                size: 18, color: Colors.white)
                            : null)),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(
                        'Tôi đã đọc và đồng ý với các điều khoản, cam kết ở trên.',
                        style: appText(13.5,
                            weight: FontWeight.w500,
                            color: _black,
                            height: 1.45))),
              ]))));

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 360;
    final enabled = _agreed;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                children: [
                  if (widget.onAgreed == null)
                    Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                            tooltip: 'Quay lại',
                            padding: EdgeInsets.zero,
                            alignment: Alignment.centerLeft,
                            constraints: const BoxConstraints(
                                minWidth: 48, minHeight: 48),
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: const Icon(Icons.arrow_back_rounded,
                                size: 22, color: Colors.black)))
                  else
                    const SizedBox(height: 28),
                  const SizedBox(height: 18),
                  Text('Điều khoản & cam kết',
                      style: appText(narrow ? 26 : 28,
                          weight: FontWeight.w700, color: _black, height: 1.2)),
                  const SizedBox(height: 14),
                  Text(
                      'Để cùng xây dựng cộng đồng thợ uy tín và chuyên nghiệp, anh vui lòng đọc kỹ các cam kết dưới đây trước khi nhận đơn.',
                      style: appText(15,
                          weight: FontWeight.w500, color: _grey, height: 1.45)),
                  const SizedBox(height: 26),
                  for (var i = 0; i < _terms.length; i++) _item(i, _terms[i]),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: _divider),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                _consent(context),
                const SizedBox(height: 10),
                SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                        key: const ValueKey('terms-agree'),
                        style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: _disabledBg,
                            disabledForegroundColor: const Color(0xFF8A94A3),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15))),
                        onPressed: enabled
                            ? () => widget.onAgreed != null
                                ? widget.onAgreed!()
                                : Navigator.of(context).pop(true)
                            : null,
                        child: Text('Đồng ý',
                            style: appText(16.5,
                                weight: FontWeight.w700,
                                color: enabled
                                    ? Colors.white
                                    : const Color(0xFF8A94A3))))),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
