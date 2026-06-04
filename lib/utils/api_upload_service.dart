import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'api_endpoints.dart';

class DocumentUploadService {
  static const int _maxConcurrent = 3;
  static const int _maxRetries = 3;

  final String accessToken;
  final void Function(double progress)? onProgress;

  DocumentUploadService({
    required this.accessToken,
    this.onProgress,
  });

  Future<List<DocumentUploadResult>> uploadDocuments(List<String> filePaths) async {
    final results = <DocumentUploadResult>[];
    final queue = List<String>.from(filePaths);

    while (queue.isNotEmpty) {
      final batch = queue.take(_maxConcurrent).toList();
      for (final path in batch) {
        queue.remove(path);
      }

      final futures = batch.map((path) => _uploadSingleFile(path));
      final batchResults = await Future.wait(futures);

      for (final result in batchResults) {
        if (result != null) {
          results.add(result);
        }
      }
    }

    return results;
  }

  Future<DocumentUploadResult?> _uploadSingleFile(
    String filePath, {
    int retryCount = 0,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return DocumentUploadResult.error(
          filePath: filePath,
          error: 'File not found',
        );
      }

      final fileName = p.basename(filePath);
      final fileSize = await file.length();

      onProgress?.call(0.1);

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiEndPoiunts.uploadDocument),
      );

      request.headers['Authorization'] = 'Bearer $accessToken';
      request.files.add(
        await http.MultipartFile.fromPath(
          'document',
          filePath,
          filename: fileName,
        ),
      );
      request.fields['fileName'] = fileName;
      request.fields['fileSize'] = fileSize.toString();
      request.fields['userAccessToken'] = accessToken;
      request.fields['uploadedAt'] = DateTime.now().toIso8601String();

      onProgress?.call(0.3);

      final streamedResponse = await request.send().timeout(
        const Duration(minutes: 5),
      );

      onProgress?.call(0.7);

      final response = await http.Response.fromStream(streamedResponse);

      onProgress?.call(1.0);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return DocumentUploadResult.success(
          filePath: filePath,
          documentId: '',
          url: '',
          fileName: fileName,
          fileSize: fileSize,
        );
      } else {
        return DocumentUploadResult.error(
          filePath: filePath,
          error: 'Upload failed: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (retryCount < _maxRetries) {
        await Future.delayed(Duration(milliseconds: 1000 * (retryCount + 1)));
        return _uploadSingleFile(filePath, retryCount: retryCount + 1);
      }

      return DocumentUploadResult.error(
        filePath: filePath,
        error: e.toString(),
      );
    }
  }

  Future<DocumentUploadResult?> uploadToCloudStorage(
    String filePath, {
    int retryCount = 0,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      final fileName = p.basename(filePath);
      final bytes = await file.readAsBytes();

      final signResponse = await http.post(
        Uri.parse(ApiEndPoiunts.getSignedUploadUrl),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: '{"fileName":"$fileName","contentType":"application/pdf"}',
      ).timeout(const Duration(seconds: 30));

      if (signResponse.statusCode != 200) {
        return DocumentUploadResult.error(
          filePath: filePath,
          error: 'Failed to get upload URL',
        );
      }

      final uploadUrl = signResponse.body;

      final uploadResponse = await http.put(
        Uri.parse(uploadUrl),
        headers: {'Content-Type': 'application/pdf'},
        body: bytes,
      ).timeout(const Duration(minutes: 5));

      if (uploadResponse.statusCode == 200) {
        return DocumentUploadResult.success(
          filePath: filePath,
          documentId: '',
          url: uploadUrl,
          fileName: fileName,
        );
      }

      return DocumentUploadResult.error(
        filePath: filePath,
        error: 'Cloud upload failed: ${uploadResponse.statusCode}',
      );
    } catch (e) {
      if (retryCount < _maxRetries) {
        await Future.delayed(Duration(milliseconds: 1000 * (retryCount + 1)));
        return uploadToCloudStorage(filePath, retryCount: retryCount + 1);
      }

      return DocumentUploadResult.error(
        filePath: filePath,
        error: e.toString(),
      );
    }
  }
}

class DocumentUploadResult {
  final bool isSuccess;
  final String filePath;
  final String? documentId;
  final String? url;
  final String? fileName;
  final int? fileSize;
  final String? error;

  DocumentUploadResult._({
    required this.isSuccess,
    required this.filePath,
    this.documentId,
    this.url,
    this.fileName,
    this.fileSize,
    this.error,
  });

  factory DocumentUploadResult.success({
    required String filePath,
    required String documentId,
    required String url,
    String? fileName,
    int? fileSize,
  }) => DocumentUploadResult._(
    isSuccess: true,
    filePath: filePath,
    documentId: documentId,
    url: url,
    fileName: fileName,
    fileSize: fileSize,
  );

  factory DocumentUploadResult.error({
    required String filePath,
    required String error,
  }) => DocumentUploadResult._(
    isSuccess: false,
    filePath: filePath,
    error: error,
  );
}

class DocumentStore {
  final String accessToken;

  DocumentStore({required this.accessToken});

  Future<String?> saveDocumentMetadata({
    required String documentId,
    required String fileName,
    required int fileSize,
    required String fileType,
    required String url,
    int totalPages = 1,
    int copies = 1,
    String quality = '80gsm',
    String size = 'A4',
    String side = 'single',
    String colorMode = 'black',
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndPoiunts.saveDocument),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: '''{
          "documentId":"$documentId",
          "fileName":"$fileName",
          "fileSize":$fileSize,
          "fileType":"$fileType",
          "url":"$url",
          "totalPages":$totalPages,
          "copies":$copies,
          "quality":"$quality",
          "size":"$size",
          "side":"$side",
          "colorMode":"$colorMode",
          "userAccessToken":"$accessToken",
          "createdAt":"${DateTime.now().toIso8601String()}"
        }''',
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return documentId;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getUserDocuments() async {
    try {
      final response = await http.get(
        Uri.parse(ApiEndPoiunts.getUserDocuments),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return [];
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> deleteDocument(String documentId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiEndPoiunts.deleteDocument}/$documentId'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(const Duration(seconds: 30));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}