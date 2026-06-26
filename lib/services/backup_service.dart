import 'json_storage_service.dart';

class BackupService {
  BackupService(this._storageService);

  final JsonStorageService _storageService;

  Future<String?> createBackup() async {
    final raw = await _storageService.readRaw();
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    return _storageService.writeBackup(raw);
  }
}
