import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class MediaPickerService {
  Future<String?> pickImagePath();
}

class FilePickerMediaPickerService implements MediaPickerService {
  @override
  Future<String?> pickImagePath() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      lockParentWindow: true,
    );
    if (result == null || result.files.isEmpty) {
      return null;
    }
    return result.files.single.path;
  }
}

final mediaPickerProvider = Provider<MediaPickerService>((ref) {
  return FilePickerMediaPickerService();
});
