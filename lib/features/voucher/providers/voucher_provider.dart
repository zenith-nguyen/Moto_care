import 'package:flutter_riverpod/flutter_riverpod.dart';

class VoucherOffer {
  const VoucherOffer({
    required this.code,
    required this.title,
    required this.expiresAt,
    this.minimumOrder = 'Đơn từ 50k',
    this.usedAt,
  });
  final String code;
  final String title;
  final DateTime expiresAt;
  final String minimumOrder;
  final DateTime? usedAt;
}

final voucherClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);
final voucherProvider = NotifierProvider<VoucherController, List<VoucherOffer>>(
  VoucherController.new,
);

class VoucherController extends Notifier<List<VoucherOffer>> {
  @override
  List<VoucherOffer> build() {
    final now = ref.read(voucherClockProvider)();
    return List.unmodifiable([
      VoucherOffer(
        code: 'SOS20',
        title: 'Giảm 20k phí cứu hộ',
        expiresAt: now.add(const Duration(days: 30)),
      ),
      VoucherOffer(
        code: 'DEM15',
        title: 'Giảm 15% cứu hộ ban đêm',
        expiresAt: now.add(const Duration(days: 15)),
      ),
      VoucherOffer(
        code: 'WELCOME',
        title: 'Giảm 10k đơn cứu hộ đầu tiên',
        expiresAt: now.subtract(const Duration(days: 1)),
        usedAt: now.subtract(const Duration(days: 5)),
      ),
    ]);
  }

  String? applyCode(String input) {
    final code = input.trim().toUpperCase();
    if (code.isEmpty) return 'Vui lòng nhập mã ưu đãi.';
    if (state.any((voucher) => voucher.code == code)) {
      return 'Mã này đã có trong kho voucher của bạn.';
    }
    if (code != 'MOTO20') return 'Mã ưu đãi không hợp lệ.';
    state = List.unmodifiable([
      VoucherOffer(
        code: code,
        title: 'Giảm 20k cho chuyến đi an tâm',
        expiresAt: ref
            .read(voucherClockProvider)()
            .add(const Duration(days: 30)),
      ),
      ...state,
    ]);
    return null;
  }
}
