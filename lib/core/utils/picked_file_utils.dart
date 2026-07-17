import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Copies a picked file out of an ephemeral/OS-reclaimable location (e.g.
/// image_picker's cache-dir "scaled_*.jpg" output, or a file_picker temp
/// path) into the app's persistent documents directory, and returns the new
/// path.
///
/// Multi-step forms (pick a photo on page 2, submit on page 5) can outlive
/// the original file: Android is free to clear app cache-directory contents
/// under storage pressure at any time, which throws a PathNotFoundException
/// at upload time. Documents-directory files aren't subject to that.
class PickedFileUtils {
  static Future<String> persist(String sourcePath) async {
    final sourceFile = File(sourcePath);
    final docsDir = await getApplicationDocumentsDirectory();
    final fileName =
        '${DateTime.now().microsecondsSinceEpoch}_${sourcePath.split('/').last}';
    final destFile = await sourceFile.copy('${docsDir.path}/$fileName');
    return destFile.path;
  }
}
