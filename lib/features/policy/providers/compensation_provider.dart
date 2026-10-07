import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class CompensationReport {
  CompensationReport({
    required this.orderId,
    required this.description,
    Uint8List? evidence,
  }) : evidence = evidence == null
           ? null
           : Uint8List.fromList(evidence).asUnmodifiableView();

  final String orderId;
  final String description;
  final Uint8List? evidence;
}

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
