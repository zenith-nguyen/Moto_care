import '../../profile/models/profile_validation.dart';
import '../models/admin_models.dart';
import '../models/admin_order_progress.dart';

class AdminOrderDetailsService {
  const AdminOrderDetailsService();

  static const _legacyMilestones = {
    'Đã tạo yêu cầu': AdminOrderMilestone.created,
    'Thợ nhận đơn': AdminOrderMilestone.accepted,
    'Bắt đầu cứu hộ': AdminOrderMilestone.started,
    'Hoàn thành': AdminOrderMilestone.completed,
  };

  List<AdminOrderProgressStep> progress(AdminOrder order) {
    final times = {AdminOrderMilestone.created: order.createdAt};
    for (final event in order.timeline) {
      final milestone = event.milestone ?? _legacyMilestones[event.label];
      if (milestone == null ||
          milestone == AdminOrderMilestone.created ||
          event.at.isBefore(order.createdAt)) {
        continue;
      }
      final previous = times[milestone];
      if (previous == null || event.at.isBefore(previous)) {
        times[milestone] = event.at;
      }
    }
    return List.unmodifiable([
      for (final milestone in AdminOrderMilestone.values)
        AdminOrderProgressStep(milestone, times[milestone]),
    ]);
  }

  List<AdminTimelineEvent> history(AdminOrder order) => List.unmodifiable(
    [...order.timeline]..sort((a, b) => a.at.compareTo(b.at)),
  );

  Uri? mechanicTelephone(AdminOrder order) {
    final phone = order.providerPhone?.trim() ?? '';
    if (order.provider == null ||
        phone.isEmpty ||
        ProfileValidation.phone(phone) != null) {
      return null;
    }
    return Uri(scheme: 'tel', path: ProfileValidation.normalizePhone(phone));
  }
}
