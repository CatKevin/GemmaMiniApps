import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import '../../models/gemma/models.dart';
import 'download_service.dart';
import 'gemma_service.dart';

/// Simplified model manager service for managing AI models
class ModelManagerService extends ChangeNotifier {
  static final ModelManagerService _instance = ModelManagerService._internal();
  factory ModelManagerService() => _instance;
  ModelManagerService._internal();

  final DownloadService _downloadService = DownloadService();
  final GemmaService _gemmaService = GemmaService();
  
  // Model status tracking
  final Map<String, ModelStatusInfo> _modelStatus = {};
  
  // Currently selected model for chat
  String? _selectedModelId;
  
  Map<String, ModelStatusInfo> get modelStatus => _modelStatus;
  String? get selectedModelId => _selectedModelId;
  
  ModelStatusInfo? getModelStatus(String modelId) => _modelStatus[modelId];
  
  bool isModelDownloaded(String modelId) {
    final model = ModelRegistry.getModelById(modelId);
    if (model != null && model.isImported) {
      return true;
    }
    final status = _modelStatus[modelId];
    return status?.downloadStatus == ModelDownloadStatus.downloaded;
  }
  
  bool isModelDownloading(String modelId) {
    final status = _modelStatus[modelId];
    return status?.downloadStatus == ModelDownloadStatus.downloading;
  }

  /// Initialize the service and load saved state
  Future<void> initialize() async {
    await _loadModelStatus();
    await _loadImportedModels();
    await _verifyDownloadedModels();
    await _saveModelStatus();
    notifyListeners();
  }

  /// Load saved model status from local storage
  Future<void> _loadModelStatus() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/model_status.json');
      
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final Map<String, dynamic> json = jsonDecode(jsonString);
        
        json.forEach((key, value) {
          _modelStatus[key] = ModelStatusInfo(
            modelId: key,
            downloadStatus: ModelDownloadStatus.values[value['downloadStatus'] ?? 0],
            downloadProgress: value['downloadProgress'] ?? 0.0,
            errorMessage: value['errorMessage'],
            downloadedAt: value['downloadedAt'] != null 
                ? DateTime.parse(value['downloadedAt']) 
                : null,
            localPath: value['localPath'],
          );
        });
      } else {
        // Initialize with default status for all models
        for (final model in ModelRegistry.officialModels) {
          _modelStatus[model.id] = ModelStatusInfo(
            modelId: model.id,
            downloadStatus: ModelDownloadStatus.notDownloaded,
          );
        }
      }
    } catch (e) {
      print('Error loading model status: $e');
      // Initialize with default status
      for (final model in ModelRegistry.officialModels) {
        _modelStatus[model.id] = ModelStatusInfo(
          modelId: model.id,
          downloadStatus: ModelDownloadStatus.notDownloaded,
        );
      }
    }
  }

  /// Load imported models from local storage
  Future<void> _loadImportedModels() async {
    print('🔄 Loading imported models from storage');
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/imported_models.json');
      
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(jsonString);
        
        print('📦 Found ${jsonList.length} imported models in storage');
        
        // Clear existing imported models
        ModelRegistry.clearImportedModels();
        
        for (final json in jsonList) {
          print('📥 Loading imported model: ${json['name']} (${json['id']})');
          final model = GemmaModel(
            id: json['id'],
            name: json['name'],
            modelId: json['modelId'] ?? 'local',
            modelFile: json['modelFile'],
            description: json['description'] ?? 'Imported model',
            sizeInBytes: json['sizeInBytes'] ?? 0,
            estimatedPeakMemoryInBytes: json['estimatedPeakMemoryInBytes'] ?? 0,
            commitHash: json['commitHash'] ?? '',
            supportsImage: json['supportsImage'] ?? false,
            supportsAudio: json['supportsAudio'] ?? false,
            taskTypes: List<String>.from(json['taskTypes'] ?? ['llm_chat']),
            defaultConfig: ModelConfig(
              maxTokens: json['maxTokens'] ?? 512,
              topK: json['topK'] ?? 40,
              topP: (json['topP'] ?? 0.95).toDouble(),
              temperature: (json['temperature'] ?? 1.0).toDouble(),
              accelerators: json['accelerators'] ?? 'cpu',
            ),
            isImported: true,
            localFilePath: json['localFilePath'],
          );
          
          ModelRegistry.addImportedModel(model);
          print('✅ Added ${model.name} to ModelRegistry');
          
          // Initialize status for imported model if not exists
          if (!_modelStatus.containsKey(model.id)) {
            print('📊 Creating status for imported model: ${model.id}');
            _modelStatus[model.id] = ModelStatusInfo(
              modelId: model.id,
              downloadStatus: ModelDownloadStatus.downloaded,
              downloadProgress: 1.0,
              localPath: model.localFilePath,
              downloadedAt: DateTime.now(),
            );
          }
        }
        
        print('✅ Successfully loaded ${jsonList.length} imported models');
      } else {
        print('📄 No imported_models.json file found');
      }
    } catch (e) {
      print('❌ Error loading imported models: $e');
    }
  }
  
  /// Save imported models to local storage
  Future<void> _saveImportedModels() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/imported_models.json');
      
      final importedModels = ModelRegistry.getImportedModels();
      final jsonList = importedModels.map((model) {
        return {
          'id': model.id,
          'name': model.name,
          'modelId': model.modelId,
          'modelFile': model.modelFile,
          'description': model.description,
          'sizeInBytes': model.sizeInBytes,
          'estimatedPeakMemoryInBytes': model.estimatedPeakMemoryInBytes,
          'commitHash': model.commitHash,
          'supportsImage': model.supportsImage,
          'supportsAudio': model.supportsAudio,
          'taskTypes': model.taskTypes,
          'maxTokens': model.defaultConfig.maxTokens,
          'topK': model.defaultConfig.topK,
          'topP': model.defaultConfig.topP,
          'temperature': model.defaultConfig.temperature,
          'accelerators': model.defaultConfig.accelerators,
          'localFilePath': model.localFilePath,
        };
      }).toList();
      
      await file.writeAsString(jsonEncode(jsonList));
    } catch (e) {
      print('Error saving imported models: $e');
    }
  }
  
  /// Save model status to local storage
  Future<void> _saveModelStatus() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/model_status.json');
      
      final Map<String, dynamic> json = {};
      _modelStatus.forEach((key, value) {
        json[key] = {
          'downloadStatus': value.downloadStatus.index,
          'downloadProgress': value.downloadProgress,
          'errorMessage': value.errorMessage,
          'downloadedAt': value.downloadedAt?.toIso8601String(),
          'localPath': value.localPath,
        };
      });
      
      await file.writeAsString(jsonEncode(json));
    } catch (e) {
      print('Error saving model status: $e');
    }
  }

  /// Verify that downloaded models still exist
  Future<void> _verifyDownloadedModels() async {
    for (final entry in _modelStatus.entries) {
      if (entry.value.downloadStatus == ModelDownloadStatus.downloaded) {
        final model = ModelRegistry.getModelById(entry.key);
        if (model != null) {
          final exists = await _downloadService.modelExists(model.modelFile);
          if (!exists) {
            // Model file was deleted, update status
            _modelStatus[entry.key] = entry.value.copyWith(
              downloadStatus: ModelDownloadStatus.notDownloaded,
              localPath: null,
              downloadedAt: null,
            );
          }
        }
      }
    }
    await _saveModelStatus();
  }

  /// Download a model
  Future<void> downloadModel(String modelId) async {
    final model = ModelRegistry.getModelById(modelId);
    if (model == null) return;
    
    // Check if already downloading
    if (isModelDownloading(modelId)) {
      print('Model $modelId is already downloading');
      return;
    }
    
    // Update status to downloading
    _modelStatus[modelId] = ModelStatusInfo(
      modelId: modelId,
      downloadStatus: ModelDownloadStatus.downloading,
      downloadProgress: 0.0,
    );
    notifyListeners();
    
    try {
      final localPath = await _downloadService.downloadModel(
        url: model.downloadUrl,
        modelName: model.modelFile,
        onProgress: (progress) {
          _modelStatus[modelId] = _modelStatus[modelId]!.copyWith(
            downloadProgress: progress,
          );
          notifyListeners();
        },
        onStatusUpdate: (status) {
          print('Download status for $modelId: $status');
        },
      );
      
      // Update status to downloaded
      _modelStatus[modelId] = ModelStatusInfo(
        modelId: modelId,
        downloadStatus: ModelDownloadStatus.downloaded,
        downloadProgress: 1.0,
        localPath: localPath,
        downloadedAt: DateTime.now(),
      );
      await _saveModelStatus();
      notifyListeners();
      
      print('Model $modelId downloaded successfully to: $localPath');
    } catch (e) {
      // Update status to failed
      _modelStatus[modelId] = ModelStatusInfo(
        modelId: modelId,
        downloadStatus: ModelDownloadStatus.failed,
        downloadProgress: 0.0,
        errorMessage: e.toString(),
      );
      await _saveModelStatus();
      notifyListeners();
      
      print('Failed to download model $modelId: $e');
    }
  }

  /// Cancel a model download
  void cancelDownload(String modelId) {
    _downloadService.cancelDownload();
    
    // Update status
    _modelStatus[modelId] = ModelStatusInfo(
      modelId: modelId,
      downloadStatus: ModelDownloadStatus.notDownloaded,
      downloadProgress: 0.0,
    );
    _saveModelStatus();
    notifyListeners();
  }

  /// Delete a downloaded model
  Future<bool> deleteModel(String modelId) async {
    final model = ModelRegistry.getModelById(modelId);
    if (model == null) return false;
    
    try {
      // If this is the selected model, clean it up first
      if (_selectedModelId == modelId) {
        await _gemmaService.cleanup();
        _selectedModelId = null;
      }
      
      // Delete the file
      final deleted = await _downloadService.deleteModel(model.modelFile);
      
      if (deleted) {
        // Update status
        _modelStatus[modelId] = ModelStatusInfo(
          modelId: modelId,
          downloadStatus: ModelDownloadStatus.notDownloaded,
          downloadProgress: 0.0,
          localPath: null,
          downloadedAt: null,
        );
        await _saveModelStatus();
        notifyListeners();
        
        print('Model $modelId deleted successfully');
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error deleting model $modelId: $e');
      return false;
    }
  }

  /// Select a model for use
  Future<bool> selectModel(String modelId) async {
    print('🎯 Selecting model: $modelId');
    
    final model = ModelRegistry.getModelById(modelId);
    if (model == null) {
      print('❌ Model not found in registry: $modelId');
      return false;
    }
    
    print('📦 Model found: ${model.name}, isImported: ${model.isImported}');
    
    // Determine the model path
    String? modelPath;
    
    if (model.isImported) {
      // For imported models, always use the localFilePath
      modelPath = model.localFilePath;
      if (modelPath == null) {
        print('❌ Imported model has no localFilePath');
        return false;
      }
      
      // Verify the file exists
      final file = File(modelPath);
      if (!await file.exists()) {
        print('❌ Imported model file not found at: $modelPath');
        return false;
      }
      print('✅ Imported model file verified at: $modelPath');
    } else {
      // For regular models, check download status
      if (!isModelDownloaded(modelId)) {
        print('❌ Model $modelId is not downloaded');
        return false;
      }
      
      final status = _modelStatus[modelId];
      modelPath = status?.localPath;
      if (modelPath == null) {
        print('❌ Downloaded model has no local path');
        return false;
      }
    }
    
    print('📂 Using model path: $modelPath');
    
    try {
      // Clean up previous model if different
      if (_selectedModelId != null && _selectedModelId != modelId) {
        print('🧹 Cleaning up previous model: $_selectedModelId');
        await _gemmaService.cleanup();
      }
      
      // Initialize the new model
      final config = model.defaultConfig;
      print('⚙️ Initializing with config - MaxTokens: ${config.maxTokens}, GPU: ${config.accelerators?.contains('gpu')}, SupportsImage: ${model.supportsImage}');
      
      final success = await _gemmaService.initializeModel(
        modelPath: modelPath,
        maxTokens: config.maxTokens ?? 1024,
        temperature: config.temperature ?? 1.0,
        topK: config.topK ?? 40,
        topP: config.topP ?? 0.95,
        useGpu: config.accelerators?.contains('gpu') ?? true,
        supportsImage: model.supportsImage,
      );
      
      if (success) {
        _selectedModelId = modelId;
        notifyListeners();
        print('✅ Model $modelId selected and initialized successfully');
        return true;
      } else {
        print('❌ Failed to initialize model $modelId');
        return false;
      }
    } catch (e) {
      print('💥 Error selecting model $modelId: $e');
      return false;
    }
  }

  /// Get the currently selected model
  GemmaModel? getSelectedModel() {
    if (_selectedModelId == null) return null;
    return ModelRegistry.getModelById(_selectedModelId!);
  }

  /// Import a model from a file
  Future<bool> importModel(File modelFile, GemmaModel modelConfig) async {
    print('🔄 Starting importModel method');
    print('📁 Source file: ${modelFile.path}');
    print('📦 Model config: ${modelConfig.name}');
    
    try {
      // Validate source file exists and is readable
      if (!await modelFile.exists()) {
        print('❌ Source file does not exist: ${modelFile.path}');
        return false;
      }
      
      final fileStats = await modelFile.stat();
      print('📊 Source file size: ${fileStats.size} bytes');
      
      // Copy file to app's documents directory in an 'imports' folder
      final directory = await getApplicationDocumentsDirectory();
      print('📂 App documents directory: ${directory.path}');
      
      final importsDir = Directory('${directory.path}/imports');
      if (!await importsDir.exists()) {
        print('📁 Creating imports directory: ${importsDir.path}');
        await importsDir.create(recursive: true);
      }
      
      // Generate unique filename to avoid conflicts
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final originalFileName = modelFile.path.split('/').last;
      final fileName = '${timestamp}_$originalFileName';
      final destinationPath = '${importsDir.path}/$fileName';
      
      print('📥 Copying file to: $destinationPath');
      
      // Copy the file with proper error handling
      try {
        await modelFile.copy(destinationPath);
        print('✅ File copy completed');
        
        // Verify the copied file
        final copiedFile = File(destinationPath);
        if (!await copiedFile.exists()) {
          print('❌ Copied file verification failed');
          return false;
        }
        
        final copiedStats = await copiedFile.stat();
        print('📊 Copied file size: ${copiedStats.size} bytes');
        
        if (copiedStats.size != fileStats.size) {
          print('❌ File size mismatch after copy');
          await copiedFile.delete(); // Clean up incomplete copy
          return false;
        }
        
      } catch (copyError) {
        print('❌ File copy failed: $copyError');
        return false;
      }
      
      print('🏗️ Creating model object');
      
      // Create new model with updated path
      final importedModel = GemmaModel(
        id: modelConfig.id,
        name: modelConfig.name,
        modelId: modelConfig.modelId,
        modelFile: fileName,
        description: modelConfig.description,
        sizeInBytes: fileStats.size, // Use actual file size
        estimatedPeakMemoryInBytes: modelConfig.estimatedPeakMemoryInBytes,
        commitHash: modelConfig.commitHash,
        supportsImage: modelConfig.supportsImage,
        supportsAudio: modelConfig.supportsAudio,
        taskTypes: modelConfig.taskTypes,
        defaultConfig: modelConfig.defaultConfig,
        isImported: true,
        localFilePath: destinationPath,
      );
      
      print('📝 Adding to registry: ${importedModel.id}');
      
      // Add to registry
      ModelRegistry.addImportedModel(importedModel);
      print('✅ Added to ModelRegistry');
      
      // Update status
      _modelStatus[importedModel.id] = ModelStatusInfo(
        modelId: importedModel.id,
        downloadStatus: ModelDownloadStatus.downloaded,
        downloadProgress: 1.0,
        localPath: destinationPath,
        downloadedAt: DateTime.now(),
      );
      
      print('💾 Saving model state');
      
      // Save state
      await _saveImportedModels();
      await _saveModelStatus();
      
      print('🔔 Notifying listeners');
      notifyListeners();
      
      print('🎉 Model ${importedModel.name} imported successfully to: $destinationPath');
      return true;
      
    } catch (e, stackTrace) {
      print('❌ Error importing model: $e');
      print('📚 Stack trace: $stackTrace');
      return false;
    }
  }

  /// Clean up all models
  Future<void> cleanupAll() async {
    await _gemmaService.cleanup();
    _selectedModelId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    cleanupAll();
    super.dispose();
  }
}