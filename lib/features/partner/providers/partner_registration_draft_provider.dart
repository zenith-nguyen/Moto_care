import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/partner_registration_draft.dart';
import '../services/partner_registration_service.dart';
import 'partner_registration_provider.dart';

final partnerRegistrationDraftProvider = NotifierProvider.autoDispose
    .family<
      PartnerRegistrationDraftController,
      PartnerRegistrationDraft,
      Object
    >(PartnerRegistrationDraftController.new);

class PartnerRegistrationDraftController
    extends Notifier<PartnerRegistrationDraft> {
  PartnerRegistrationDraftController(this.key);
  final Object key;
  @override
  PartnerRegistrationDraft build() => PartnerRegistrationDraft();
  void _update({
    int? step,
    String? experience,
    String? district,
    bool replaceExperience = false,
    bool replaceDistrict = false,
    Set<String>? tools,
    Uint8List? front,
    Uint8List? back,
    bool replaceFront = false,
    bool replaceBack = false,
    bool? showToolError,
    bool? submitted,
  }) => state = PartnerRegistrationDraft(
    step: step ?? state.step,
    experience: replaceExperience ? experience : state.experience,
    district: replaceDistrict ? district : state.district,
    tools: tools ?? state.tools,
    front: replaceFront ? front : state.front,
    back: replaceBack ? back : state.back,
    showToolError: showToolError ?? state.showToolError,
    submitted: submitted ?? state.submitted,
  );
  bool validateTools(int step) {
    if (step != 1) return true;
    _update(showToolError: state.tools.isEmpty);
    return state.tools.isNotEmpty;
  }

  void changeStep(int value) {
    if (value >= 0 && value < 3) _update(step: value);
  }

  void selectExperience(String? value) =>
      _update(experience: value, replaceExperience: true);
  void selectDistrict(String? value) =>
      _update(district: value, replaceDistrict: true);
  void selectTool(String tool, bool selected) => _update(
    tools: selected ? {...state.tools, tool} : ({...state.tools}..remove(tool)),
    showToolError: false,
  );
  Uint8List? _freeze(Uint8List? photo) =>
      photo == null ? null : Uint8List.fromList(photo).asUnmodifiableView();
  void attachFront(Uint8List? photo) =>
      _update(front: _freeze(photo), replaceFront: true);
  void attachBack(Uint8List? photo) =>
      _update(back: _freeze(photo), replaceBack: true);
  bool submit(String fullName, String citizenId) {
    if (state.submitted) return false;
    final application = ref
        .read(partnerRegistrationServiceProvider)
        .create(
          fullName: fullName,
          citizenId: citizenId,
          front: state.front,
          back: state.back,
          experience: state.experience,
          tools: state.tools,
          district: state.district,
        );
    ref.read(partnerApplicationsProvider.notifier).submit(application);
    _update(submitted: true);
    return true;
  }
}
