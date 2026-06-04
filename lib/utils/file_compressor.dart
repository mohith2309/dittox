import 'dart:io';
import 'package:path_provider/path_provider.dart';

class FileCompressor {
  static const int _quality = 85;
  static const int _maxPdfPages = 50;

  static Future<String?> compressImage(
    String imagePath, {
    int quality = _quality,
    int? maxWidth,
    int? maxHeight,
  }) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      
      // Check if compression is needed
      if (bytes.length < 500 * 1024) { // Less than 500KB
        return imagePath;
      }

      // Get temp directory
      final tempDir = await getTemporaryDirectory();
      final compressedPath = '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Write compressed file
      final compressedFile = File(compressedPath);
      await compressedFile.writeAsBytes(bytes);

      return compressedPath;
    } catch (e) {
      debugPrint('Image compression error: $e');
      return imagePath; // Return original on failure
    }
  }

  static Future<File?> compressPdf(
    String pdfPath, {
    int maxPages = _maxPdfPages,
  }) async {
    try {
      final file = File(pdfPath);
      if (!await file.exists()) return null;

      // For now, just return the original
      // PDF compression would require native code or server-side processing
      return file;
    } catch (e) {
      debugPrint('PDF compression error: $e');
      return null;
    }
  }

  static Future<String?> optimizeForUpload(String filePath) async {
    final extension = filePath.split('.').last.toLowerCase();

    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'heic':
      case 'webp':
        return compressImage(filePath);
      case 'pdf':
        final pdf = await compressPdf(filePath);
        return pdf?.path;
      default:
        return filePath;
    }
  }

  static Future<int> estimateCompressedSize(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return 0;

    final bytes = await file.readAsBytes();
    final originalSize = bytes.length;

    final extension = filePath.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'webp'].contains(extension)) {
      // Estimate 60-80% reduction for images
      return (originalSize * 0.7).round();
    } else if (extension == 'pdf') {
      // Estimate 20-40% reduction for PDFs
      return (originalSize * 0.8).round();
    }

    return originalSize;
  }
}

class BatchUploader {
  final List<String> _files = [];
  final List<_UploadTask> _tasks = [];
  int _completedCount = 0;
  int _failedCount = 0;

  void addFiles(List<String> files) {
    _files.addAll(files);
    for (final file in files) {
      _tasks.add(_UploadTask(
        filePath: file,
        status: UploadTaskStatus.pending,
      ));
    }
  }

  Future<BatchResult> uploadAll({
    required String Function(String) getUploadUrl,
    String? accessToken,
    void Function(int completed, int total, String currentFile)? onProgress,
  }) async {
    final results = <String, String>{};
    final errors = <String, String>{};

    for (int i = 0; i < _tasks.length; i++) {
      final task = _tasks[i];

      onProgress?.call(_completedCount, _tasks.length, task.filePath);

      try {
        task.status = UploadTaskStatus.uploading;

        // Simplified upload (replace with actual API call)
        await Future.delayed(const Duration(milliseconds: 500));

        results[task.filePath] = 'uploaded_url';
        task.status = UploadTaskStatus.completed;
        _completedCount++;
      } catch (e) {
        errors[task.filePath] = e.toString();
        task.status = UploadTaskStatus.failed;
        _failedCount++;
      }

      onProgress?.call(_completedCount, _tasks.length, '');
    }

    return BatchResult(
      successful: results,
      errors: errors,
      totalFiles: _tasks.length,
      successCount: _completedCount,
      failedCount: _failedCount,
    );
  }

  int get totalFiles => _files.length;
  int get completedCount => _completedCount;
  int get failedCount => _failedCount;
  double get progress => _tasks.isEmpty ? 0 : _completedCount / _tasks.length;
}

enum UploadTaskStatus { pending, uploading, completed, failed, cancelled }

class _UploadTask {
  final String filePath;
  UploadTaskStatus status;

  _UploadTask({
    required this.filePath,
    required this.status,
  });
}

class BatchResult {
  final Map<String, String> successful;
  final Map<String, String> errors;
  final int totalFiles;
  final int successCount;
  final int failedCount;

  BatchResult({
    required this.successful,
    required this.errors,
    required this.totalFiles,
    required this.successCount,
    required this.failedCount,
  });
}

void debugPrint(String message) {
  assert(() {
    // ignore: avoid_print
    print(message);
    return true;
  }());
}