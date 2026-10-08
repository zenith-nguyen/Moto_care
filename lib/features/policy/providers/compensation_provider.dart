import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/compensation_report.dart';
export '../models/compensation_report.dart';

final compensationReportsProvider =
    NotifierProvider<CompensationReportsController, List<CompensationReport>>(
      CompensationReportsController.new,
    );

class CompensationReportsController extends Notifier<List<CompensationReport>> {
  @override
  List<CompensationReport> build() => const [];

  void submit(CompensationReport report) =>
      state = List.unmodifiable([...state, report]);
}
