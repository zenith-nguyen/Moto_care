import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../activity/models/rescue_order.dart';
import '../../activity/providers/activity_provider.dart';
import '../data/demo_commitments.dart';
import '../services/compensation_service.dart';
import 'compensation_provider.dart';

final commitmentsProvider = Provider<List<(String, String)>>(
  (ref) => demoCommitments,
);
final recentCompensationOrdersProvider = Provider<List<RescueOrder>>((ref) {
  final orders =
      ref
          .watch(activityProvider)
          .orders
          .where((order) => order.status != RescueOrderStatus.cancelled)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return List.unmodifiable(orders.take(5));
});
typedef CompensationDraft = ({
  String? orderId,
  Uint8List? evidence,
  bool submitted,
});
final compensationDraftProvider = NotifierProvider.autoDispose
    .family<CompensationDraftController, CompensationDraft, Object>(
      CompensationDraftController.new,
    );

class CompensationDraftController extends Notifier<CompensationDraft> {
  CompensationDraftController(this.key);
  final Object key;
  @override
  CompensationDraft build() =>
      (orderId: null, evidence: null, submitted: false);
  void selectOrder(String? id) => state = (
    orderId: id,
    evidence: state.evidence,
    submitted: state.submitted,
  );
  void attachEvidence(Uint8List? value) => state = (
    orderId: state.orderId,
    evidence: value == null
        ? null
        : Uint8List.fromList(value).asUnmodifiableView(),
    submitted: state.submitted,
  );
  bool submit(String description) {
    if (state.submitted) return false;
    final order = ref.read(activityProvider).orderById(state.orderId);
    if (order == null || order.status == RescueOrderStatus.cancelled) {
      return false;
    }
    final report = ref
        .read(compensationServiceProvider)
        .create(order.id, description, state.evidence);
    ref.read(compensationReportsProvider.notifier).submit(report);
    state = (orderId: state.orderId, evidence: state.evidence, submitted: true);
    return true;
  }
}
