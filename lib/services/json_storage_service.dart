import 'json_storage_service_stub.dart'
    if (dart.library.io) 'json_storage_service_io.dart'
    if (dart.library.html) 'json_storage_service_web.dart';

abstract class JsonStorageService {
  factory JsonStorageService({String? storageDirectory}) =>
      createJsonStorageService(storageDirectory: storageDirectory);

  Future<String?> readRaw();
  Future<void> writeRaw(String contents);
  Future<String> writeBackup(String contents);
  Future<bool> exists();
  Future<String> storageLocation();
}
