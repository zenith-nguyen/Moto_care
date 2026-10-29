import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/partner_application.dart';
export '../models/partner_application.dart';

// In-memory prototype. Replace this boundary with an authenticated API service.
final partnerApplicationsProvider =
    NotifierProvider<PartnerApplicationsController, List<PartnerApplication>>(
      PartnerApplicationsController.new,
    );

class PartnerApplicationsController extends Notifier<List<PartnerApplication>> {
  @override
  List<PartnerApplication> build() => const [];

  void submit(PartnerApplication application) =>
      state = List.unmodifiable([...state, application]);
}
