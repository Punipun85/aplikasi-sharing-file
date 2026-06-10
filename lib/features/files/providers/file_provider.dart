import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../models/secure_file.dart';
import '../services/file_service.dart';

class FileProvider extends ChangeNotifier {
  final FileService _service = FileService();

  bool isLoading = false;
  String? error;
  List<SecureFile> files = demoFiles;

  int get totalDownloads =>
      files.fold(0, (sum, file) => sum + file.downloadCount);
  int get storageUsed => files.fold(0, (sum, file) => sum + file.fileSize);
  int get activeLinks => files.where((file) => file.status == 'shared').length;

  Future<void> load(String userId) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      files = await _service.listFiles(userId);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> pickAndUpload(String userId) async {
    try {
      final result = await FilePicker.pickFiles(withData: true);
      final file = result?.files.single;
      if (file == null) {
        return false;
      }
      await _service.upload(userId, file);
      await load(userId);
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  SecureFile? byId(String id) =>
      files.where((file) => file.id == id).firstOrNull;
}
