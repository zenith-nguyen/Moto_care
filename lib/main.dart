import 'app/bootstrap.dart';

Future<void> main() => bootstrapMotoCare(
  // Keep the shared customer entrypoint mapped to MotoCareApp. The Provider
  // flavor has its own main_provider.dart entrypoint and role-gated runtime.
  AppRuntimeRole.customer,
);
