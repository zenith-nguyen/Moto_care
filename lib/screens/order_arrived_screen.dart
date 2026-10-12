import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/code_input_boxes.dart';
import '../widgets/order_widgets.dart';
import '../widgets/step_progress_bar.dart';
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
            ScreenHeader(title: 'Đơn ${offer.code}'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                children: [
                  const StepProgressBar(current: 2, steps: orderStepLabels),
                  const SizedBox(height: 28),
                  const Center(
                    child: IconCircle(
                      icon: Icons.location_on_outlined,
                      size: 96,
                      background: AppColors.successSoft,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Bạn đã đến vị trí khách',
                    textAlign: TextAlign.center,
                    style: appText(22, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nhập mã khách cung cấp để bắt đầu sửa',
                    textAlign: TextAlign.center,
                    style: appText(14.5, color: AppColors.textSub),
                  ),
                  const SizedBox(height: 24),
                  CustomerCard(
                    name: offer.customerName,
                    subtitle: '${offer.vehicle} · ${offer.plate}',
                  ),
                  const SizedBox(height: 26),
                  Center(
                    child: CodeInputBoxes(
                      length: _codeLength,
                      boxSize: 58,
                      spacing: 14,
                      autofocus: true,
                      onChanged: (v) => setState(() => _code = v),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: GestureDetector(
                      onTap: () => callCustomer(context, offer.customerName, offer.customerPhone),
                      child: Text.rich(
                        TextSpan(
                          text: 'Khách chưa thấy mã? ',
                          children: [
                            TextSpan(
                              text: 'Gọi khách hỗ trợ',
                              style:
                                  appText(14.5, weight: FontWeight.w600, color: AppColors.danger),
                            ),
                          ],
                        ),
                        style: appText(14.5),
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
