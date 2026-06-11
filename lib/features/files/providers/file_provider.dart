import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

import '../models/secure_file.dart';
import '../services/file_service.dart';

class FileProvider extends ChangeNotifier {
  final FileService _service = FileService();

  bool isLoading = false;
  String? error;
  List<SecureFile> files = demoFiles;
  StreamSubscription<List<SecureFile>>? _filesSubscription;

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

  void watch(String userId) {
    _filesSubscription?.cancel();
    _filesSubscription = _service
        .watchFiles(userId)
        .listen(
          (value) {
            files = value;
            error = null;
            notifyListeners();
          },
          onError: (Object e) {
            error = e.toString();
            notifyListeners();
          },
        );
  }

  Future<bool> pickAndUpload(String userId) async {
    try {
      final result = await FilePicker.pickFiles(withData: true);
      final file = result?.files.single;
      if (file == null) {
        return false;
      }
      final uploaded = await _service.upload(userId, file);
      if (uploaded != null) {
        files = [uploaded, ...files.where((item) => item.id != uploaded.id)];
        notifyListeners();
      }
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

  Future<FilePreviewData> preview(SecureFile file) {
    return _service.preview(file);
  }

  @override
  void dispose() {
    _filesSubscription?.cancel();
    super.dispose();
  }
}
