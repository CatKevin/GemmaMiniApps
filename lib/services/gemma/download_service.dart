import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class DownloadService {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  final Dio _dio = Dio();
  CancelToken? _cancelToken;

  /// Get the models directory path
  Future<String> getModelsDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final modelsDir = Directory('${directory.path}/models');
    
    // Create the directory if it doesn't exist
    if (!await modelsDir.exists()) {
      await modelsDir.create(recursive: true);
    }
    
    return modelsDir.path;
  }

  /// Get the full path for a model file
  Future<String> getModelFilePath(String modelName) async {
    final modelsDir = await getModelsDirectory();
    return '$modelsDir/$modelName';
  }

  /// Check if a model file exists
  Future<bool> modelExists(String modelName) async {
    final filePath = await getModelFilePath(modelName);
    return File(filePath).exists();
  }

  /// Get model file size in bytes
  Future<int> getModelFileSize(String modelName) async {
    final filePath = await getModelFilePath(modelName);
    final file = File(filePath);
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }

  /// Download a model from URL
  Future<String> downloadModel({
    required String url,
    required String modelName,
    Function(double)? onProgress,
    Function(String)? onStatusUpdate,
  }) async {
    try {
      // Get the destination path
      final destinationPath = await getModelFilePath(modelName);
      
      // Check if file already exists
      if (await File(destinationPath).exists()) {
        onStatusUpdate?.call('Model already exists, verifying...');
        final fileSize = await File(destinationPath).length();
        if (fileSize > 1000000) { // Check if file is at least 1MB
          onStatusUpdate?.call('Model verified successfully');
          return destinationPath;
        } else {
          onStatusUpdate?.call('Existing model file is too small, re-downloading...');
          await File(destinationPath).delete();
        }
      }

      onStatusUpdate?.call('Starting download...');
      
      // Create cancel token for this download
      _cancelToken = CancelToken();
      
      // Download the file
      await _dio.download(
        url,
        destinationPath,
        cancelToken: _cancelToken,
        deleteOnError: true,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final progress = received / total;
            onProgress?.call(progress);
            
            // Update status at key milestones
            if (progress < 0.25) {
              onStatusUpdate?.call('Downloading... ${(progress * 100).toStringAsFixed(1)}%');
            } else if (progress < 0.50) {
              onStatusUpdate?.call('Downloading... ${(progress * 100).toStringAsFixed(1)}%');
            } else if (progress < 0.75) {
              onStatusUpdate?.call('Almost there... ${(progress * 100).toStringAsFixed(1)}%');
            } else if (progress < 1.0) {
              onStatusUpdate?.call('Finalizing... ${(progress * 100).toStringAsFixed(1)}%');
            }
          }
        },
        options: Options(
          receiveTimeout: const Duration(minutes: 30),
          headers: {
            'User-Agent': 'Flutter Gemma App',
          },
        ),
      );
      
      // Verify the downloaded file
      final file = File(destinationPath);
      if (await file.exists()) {
        final fileSize = await file.length();
        onStatusUpdate?.call('Download complete! File size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');
        return destinationPath;
      } else {
        throw Exception('Downloaded file not found');
      }
      
    } catch (e) {
      if (e is DioException) {
        if (e.type == DioExceptionType.cancel) {
          onStatusUpdate?.call('Download cancelled');
          throw Exception('Download cancelled by user');
        } else if (e.type == DioExceptionType.connectionTimeout) {
          onStatusUpdate?.call('Download timed out');
          throw Exception('Download timed out. Please check your internet connection.');
        } else if (e.type == DioExceptionType.receiveTimeout) {
          onStatusUpdate?.call('Download timed out');
          throw Exception('Download took too long. Please try again.');
        } else {
          onStatusUpdate?.call('Download failed: ${e.message}');
          throw Exception('Download failed: ${e.message}');
        }
      } else {
        onStatusUpdate?.call('Download error: $e');
        throw Exception('Download error: $e');
      }
    }
  }

  /// Cancel the current download
  void cancelDownload() {
    _cancelToken?.cancel('User cancelled download');
    _cancelToken = null;
  }

  /// Delete a model file
  Future<bool> deleteModel(String modelName) async {
    try {
      final filePath = await getModelFilePath(modelName);
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting model: $e');
      return false;
    }
  }

  /// List all downloaded models
  Future<List<ModelInfo>> listDownloadedModels() async {
    try {
      final modelsDir = await getModelsDirectory();
      final directory = Directory(modelsDir);
      
      if (!await directory.exists()) {
        return [];
      }
      
      final List<ModelInfo> models = [];
      await for (final entity in directory.list()) {
        if (entity is File) {
          final fileName = entity.path.split('/').last;
          final fileSize = await entity.length();
          final lastModified = await entity.lastModified();
          
          models.add(ModelInfo(
            name: fileName,
            path: entity.path,
            sizeInBytes: fileSize,
            lastModified: lastModified,
          ));
        }
      }
      
      return models;
    } catch (e) {
      print('Error listing models: $e');
      return [];
    }
  }

  /// Clean up old or unused models
  Future<void> cleanupOldModels({int maxAgeDays = 30}) async {
    try {
      final models = await listDownloadedModels();
      final now = DateTime.now();
      
      for (final model in models) {
        final age = now.difference(model.lastModified).inDays;
        if (age > maxAgeDays) {
          await deleteModel(model.name);
          print('Deleted old model: ${model.name} (${age} days old)');
        }
      }
    } catch (e) {
      print('Error cleaning up models: $e');
    }
  }
}

class ModelInfo {
  final String name;
  final String path;
  final int sizeInBytes;
  final DateTime lastModified;

  ModelInfo({
    required this.name,
    required this.path,
    required this.sizeInBytes,
    required this.lastModified,
  });

  double get sizeInMB => sizeInBytes / 1024 / 1024;

  String get formattedSize {
    if (sizeInBytes < 1024) {
      return '$sizeInBytes B';
    } else if (sizeInBytes < 1024 * 1024) {
      return '${(sizeInBytes / 1024).toStringAsFixed(2)} KB';
    } else if (sizeInBytes < 1024 * 1024 * 1024) {
      return '${(sizeInBytes / 1024 / 1024).toStringAsFixed(2)} MB';
    } else {
      return '${(sizeInBytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
    }
  }
}