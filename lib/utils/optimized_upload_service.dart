import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

enum UploadStatus {
  pending,
  uploading,
  paused,
  completed,
  failed,
}

class UploadProgress {
  final String filePath;
  final int totalBytes;
  final int uploadedBytes;
  final UploadStatus status;
  final double progress;
  final String? error;

  UploadProgress({
    required this.filePath,
    required this.totalBytes,
    required this.uploadedBytes,
    required this.status,
    required this.progress,
    this.error,
  });
}

class OptimizedUploadService {
  static const int _chunkSize = 256 * 1024; // 256KB chunks
  static const int _maxConcurrentUploads = 3;
  static const int _maxRetries = 3;

  final String uploadUrl;
  final Map<String, String> headers;
  final void Function(UploadProgress)? onProgress;

  OptimizedUploadService({
    required this.uploadUrl,
    this.headers = const {},
    this.onProgress,
  });

  Future<List<String>> uploadFiles(
    List<String> filePaths, {
    String? accessToken,
  }) async {
    final results = <String>[];
    final queue = List<String>.from(filePaths);
    final active = <String, Completer<String>>{};

    while (queue.isNotEmpty || active.isNotEmpty) {
      // Start new uploads until max concurrent
      while (queue.isNotEmpty && active.length < _maxConcurrentUploads) {
        final path = queue.removeAt(0);
        final completer = Completer<String>();
        active[path] = completer;

        _uploadFile(path, accessToken: accessToken).then((url) {
          results.add(url);
          completer.complete(url);
        }).catchError((e) {
          completer.completeError(e);
        }).whenComplete(() {
          active.remove(path);
        });
      }

      // Wait for at least one to complete
      if (active.isNotEmpty) {
        await Future.any(active.values.map((c) => c.future));
      }
    }

    return results;
  }

  Future<String> _uploadFile(
    String filePath, {
    String? accessToken,
  }) async {
    final file = File(filePath);
    final fileSize = await file.length();
    final fileName = file.path.split('/').last;

    onProgress?.call(UploadProgress(
      filePath: filePath,
      totalBytes: fileSize,
      uploadedBytes: 0,
      status: UploadStatus.uploading,
      progress: 0,
    ));

    try {
      // Use multipart upload for large files
      final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));

      if (accessToken != null) {
        request.headers['Authorization'] = 'Bearer $accessToken';
      }
      request.headers.addAll(headers);

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          filePath,
          filename: fileName,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = response.body;
        // Extract URL from response
        final urlMatch = RegExp(r'"url"\s*:\s*"([^"]+)"').firstMatch(body);
        final url = urlMatch?.group(1) ?? body;

        onProgress?.call(UploadProgress(
          filePath: filePath,
          totalBytes: fileSize,
          uploadedBytes: fileSize,
          status: UploadStatus.completed,
          progress: 1.0,
        ));

        return url;
      } else {
        throw Exception('Upload failed: ${response.statusCode}');
      }
    } catch (e) {
      onProgress?.call(UploadProgress(
        filePath: filePath,
        totalBytes: fileSize,
        uploadedBytes: 0,
        status: UploadStatus.failed,
        progress: 0,
        error: e.toString(),
      ));
      rethrow;
    }
  }

  // Chunked upload for very large files
  Future<String> uploadFileChunked(
    String filePath, {
    String? accessToken,
    int? fileId,
  }) async {
    final file = File(filePath);
    final fileSize = await file.length();
    final fileName = file.path.split('/').last;
    final totalChunks = (fileSize / _chunkSize).ceil();

    // Initialize upload session
    final initResponse = await http.post(
      Uri.parse('$uploadUrl/init'),
      headers: {...headers, if (accessToken != null) 'Authorization': 'Bearer $accessToken'},
      body: {
        'fileName': fileName,
        'fileSize': fileSize.toString(),
        'chunkSize': _chunkSize.toString(),
        'totalChunks': totalChunks.toString(),
      },
    );

    if (initResponse.statusCode != 200) {
      throw Exception('Failed to initialize upload');
    }

    final uploadId = initResponse.body;

    // Upload chunks in parallel
    final chunks = <int, Future<bool>>{};
    for (int i = 0; i < totalChunks; i++) {
      final start = i * _chunkSize;
      final end = (start + _chunkSize > fileSize) ? fileSize : start + _chunkSize;
      final chunkData = await file.readAsBytes().then(
        (bytes) => bytes.sublist(start, end),
      );

      chunks[i] = _uploadChunk(
        uploadId: uploadId,
        chunkIndex: i,
        chunkData: chunkData,
        accessToken: accessToken,
      );
    }

    // Wait for all chunks
    final results = await Future.wait(chunks.values);
    if (results.contains(false)) {
      throw Exception('Some chunks failed to upload');
    }

    // Finalize upload
    final finalizeResponse = await http.post(
      Uri.parse('$uploadUrl/finalize'),
      headers: {...headers, if (accessToken != null) 'Authorization': 'Bearer $accessToken'},
      body: {'uploadId': uploadId},
    );

    if (finalizeResponse.statusCode != 200) {
      throw Exception('Failed to finalize upload');
    }

    return finalizeResponse.body;
  }

  Future<bool> _uploadChunk({
    required String uploadId,
    required int chunkIndex,
    required Uint8List chunkData,
    String? accessToken,
    int retries = 0,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$uploadUrl/chunk'),
        headers: {...headers, if (accessToken != null) 'Authorization': 'Bearer $accessToken'},
        body: {
          'uploadId': uploadId,
          'chunkIndex': chunkIndex.toString(),
          'data': chunkData,
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      if (retries < _maxRetries) {
        await Future.delayed(Duration(milliseconds: 500 * (retries + 1)));
        return _uploadChunk(
          uploadId: uploadId,
          chunkIndex: chunkIndex,
          chunkData: chunkData,
          accessToken: accessToken,
          retries: retries + 1,
        );
      }
      return false;
    }
  }

  // Background upload for files
  static Future<String> uploadInBackground(
    String filePath,
    String uploadUrl, {
    String? accessToken,
  }) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();

    final request = http.Request('POST', Uri.parse(uploadUrl));
    request.headers.addAll({
      'Content-Type': 'application/octet-stream',
      'Content-Length': bytes.length.toString(),
      if (accessToken != null) 'Authorization': 'Bearer $accessToken',
    });
    request.bodyBytes = bytes;

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return response.body;
    }
    throw Exception('Background upload failed: ${response.statusCode}');
  }
}

class UploadQueue {
  final List<_QueuedUpload> _queue = [];
  final _maxConcurrent = 3;
  int _activeCount = 0;
  bool _isPaused = false;

  Future<List<String>> addFiles(
    List<String> filePaths, {
    String? accessToken,
    void Function(UploadProgress)? onProgress,
  }) async {
    for (final path in filePaths) {
      _queue.add(_QueuedUpload(
        filePath: path,
        accessToken: accessToken,
        onProgress: onProgress,
      ));
    }

    return _processQueue();
  }

  Future<List<String>> _processQueue() async {
    final results = <String>[];

    while (_queue.isNotEmpty && !_isPaused) {
      while (_activeCount < _maxConcurrent && _queue.isNotEmpty) {
        final upload = _queue.removeAt(0);
        _activeCount++;

        _processUpload(upload)
            .then((url) => results.add(url))
            .catchError((e) => debugPrint('Upload error: $e'))
            .whenComplete(() => _activeCount--);
      }

      await Future.delayed(const Duration(milliseconds: 100));
    }

    // Wait for active uploads to complete
    while (_activeCount > 0) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    return results;
  }

  Future<String> _processUpload(_QueuedUpload upload) async {
    final service = OptimizedUploadService(
      uploadUrl: upload.uploadUrl,
      onProgress: upload.onProgress,
    );
    return service.uploadFiles([upload.filePath], accessToken: upload.accessToken).then(
      (urls) => urls.first,
    );
  }

  void pause() => _isPaused = true;
  void resume() {
    _isPaused = false;
    _processQueue();
  }
}

class _QueuedUpload {
  final String filePath;
  final String? accessToken;
  final String uploadUrl = 'https://api.dittox.in/upload';
  final void Function(UploadProgress)? onProgress;

  _QueuedUpload({
    required this.filePath,
    this.accessToken,
    this.onProgress,
  });
}

void debugPrint(String message) {
  assert(() {
    // ignore: avoid_print
    print(message);
    return true;
  }());
}