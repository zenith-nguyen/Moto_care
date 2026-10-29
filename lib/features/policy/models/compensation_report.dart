import 'dart:typed_data';

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
