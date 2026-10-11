import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/code_input_boxes.dart';
import '../widgets/ui.dart';
import 'order_in_progress_screen.dart';
import 'order_received_screen.dart';

/// Bước 2/5: Đã đến nơi — nhập mã bắt đầu sửa xe khách đọc từ app của họ.
class OrderArrivedScreen extends StatefulWidget {
  const OrderArrivedScreen({super.key, required this.order});

  final ActiveOrder order;

  @override
  State<OrderArrivedScreen> createState() => _OrderArrivedScreenState();
}

class _OrderArrivedScreenState extends State<OrderArrivedScreen> {
  static const _codeLength = 4;
  String _code = '';

  void _confirm() {
    // Mock: backend thật sẽ đối chiếu mã với mã hiển thị trong app khách.
    appState.startRepair();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => OrderInProgressScreen(order: widget.order)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final offer = widget.order.offer;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Đã đến nơi'),
            Expanded(
              child: ScrollColumn(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                children: [
                  const Center(child: IconCircle(icon: Icons.where_to_vote_outlined, size: 100)),
                  const SizedBox(height: 22),
                  Text(
                    'Bạn đã đến vị trí khách',
                    textAlign: TextAlign.center,
                    style: appText(24, weight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Yêu cầu khách đọc mã bắt đầu sửa xe hiển thị trong ứng dụng của họ, '
                    'rồi nhập vào ô dưới để xác nhận bạn có mặt.',
                    textAlign: TextAlign.center,
                    style: appText(15, color: AppColors.textSub, height: 1.5),
                  ),
                  const SizedBox(height: 26),
                  SurfaceCard(
                    padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
                    child: Row(
                      children: [
                        const AvatarCircle(dark: false, size: 52),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(offer.customerName, style: appText(17, weight: FontWeight.w800)),
                              const SizedBox(height: 2),
                              Text(
                                '${offer.vehicle} · ${offer.address}',
                                style: appText(14, color: AppColors.textSub, height: 1.3),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        RoundIconButton(
                          icon: Icons.call_outlined,
                          tooltip: 'Gọi khách',
                          filled: true,
                          size: 56,
                          onTap: () =>
                              callCustomer(context, offer.customerName, offer.customerPhone),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'Mã bắt đầu sửa xe',
                    textAlign: TextAlign.center,
                    style: appText(16, weight: FontWeight.w800),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: CodeInputBoxes(
                      length: _codeLength,
                      boxSize: 58,
                      spacing: 14,
                      autofocus: true,
                      onChanged: (v) => setState(() => _code = v),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: GestureDetector(
                      onTap: () => callCustomer(context, offer.customerName, offer.customerPhone),
                      child: Text.rich(
                        TextSpan(
                          text: 'Khách chưa thấy mã? ',
                          children: [
                            TextSpan(
                              text: 'Gọi khách hỗ trợ',
                              style: appText(15, weight: FontWeight.w800),
                            ),
                          ],
                        ),
                        style: appText(15, color: AppColors.textSub),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: PrimaryButton(
                label: 'Xác nhận bắt đầu sửa',
                onPressed: _code.length == _codeLength ? _confirm : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
