import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/service_scaffold.dart';
import '../config/support_contact.dart';

final serviceUrlLauncherProvider = Provider<Future<bool> Function(Uri)>(
  (ref) =>
      (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
);

// Existing contact number used by the registration screen.
final supportHotlineProvider = Provider<String>(
  (ref) => SupportContact.hotline,
);

Future<void> launchServiceUri(
  BuildContext context,
  WidgetRef ref,
  Uri uri,
  String fallback,
) async {
  var opened = false;
  try {
    opened = await ref.read(serviceUrlLauncherProvider)(uri);
  } on Exception {
    opened = false;
  }
  if (context.mounted && !opened) showServiceMessage(context, fallback);
}
