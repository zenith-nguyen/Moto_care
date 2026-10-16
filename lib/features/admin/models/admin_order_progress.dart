import 'admin_models.dart';

class AdminOrderProgressStep {
  const AdminOrderProgressStep(this.milestone, this.at);

  final AdminOrderMilestone milestone;
  final DateTime? at;
  bool get reached => at != null;
}
