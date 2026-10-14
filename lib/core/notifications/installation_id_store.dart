abstract interface class InstallationIdStore {
  Future<String> readOrCreate();
  Future<String?> read();
}
