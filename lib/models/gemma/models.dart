/// Gemma model definitions and registry

class GemmaModel {
  final String id;
  final String name;
  final String modelId;
  final String modelFile;
  final String description;
  final int sizeInBytes;
  final int estimatedPeakMemoryInBytes;
  final String commitHash;
  final bool supportsImage;
  final bool supportsAudio;
  final List<String> taskTypes;
  final ModelConfig defaultConfig;
  final bool isImported;
  final String? localFilePath;

  GemmaModel({
    required this.id,
    required this.name,
    required this.modelId,
    required this.modelFile,
    required this.description,
    required this.sizeInBytes,
    required this.estimatedPeakMemoryInBytes,
    required this.commitHash,
    required this.supportsImage,
    required this.supportsAudio,
    required this.taskTypes,
    required this.defaultConfig,
    this.isImported = false,
    this.localFilePath,
  });

  String get downloadUrl {
    // Return HuggingFace URL for official models
    if (modelId.contains('gemma-2b-it')) {
      return 'https://huggingface.co/google/gemma-2b-it/resolve/main/model.safetensors';
    }
    return 'https://huggingface.co/google/gemma-2b/resolve/main/model.safetensors';
  }

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

  String get formattedMemory {
    final mb = estimatedPeakMemoryInBytes / 1024 / 1024;
    if (mb < 1024) {
      return '${mb.toStringAsFixed(0)} MB RAM';
    } else {
      return '${(mb / 1024).toStringAsFixed(1)} GB RAM';
    }
  }
}

class ModelConfig {
  final int? maxTokens;
  final int? topK;
  final double? topP;
  final double? temperature;
  final String? accelerators;

  ModelConfig({
    this.maxTokens,
    this.topK,
    this.topP,
    this.temperature,
    this.accelerators,
  });
}

enum ModelDownloadStatus {
  notDownloaded,
  downloading,
  downloaded,
  failed
}

class ModelStatusInfo {
  final String modelId;
  final ModelDownloadStatus downloadStatus;
  final double downloadProgress;
  final String? errorMessage;
  final DateTime? downloadedAt;
  final String? localPath;

  ModelStatusInfo({
    required this.modelId,
    required this.downloadStatus,
    this.downloadProgress = 0.0,
    this.errorMessage,
    this.downloadedAt,
    this.localPath,
  });

  ModelStatusInfo copyWith({
    String? modelId,
    ModelDownloadStatus? downloadStatus,
    double? downloadProgress,
    String? errorMessage,
    DateTime? downloadedAt,
    String? localPath,
  }) {
    return ModelStatusInfo(
      modelId: modelId ?? this.modelId,
      downloadStatus: downloadStatus ?? this.downloadStatus,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      errorMessage: errorMessage ?? this.errorMessage,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      localPath: localPath ?? this.localPath,
    );
  }
}

/// Model registry for managing available models
class ModelRegistry {
  static final List<GemmaModel> _officialModels = [
    GemmaModel(
      id: 'gemma-2b-it',
      name: 'Gemma 2B Instruct',
      modelId: 'google/gemma-2b-it',
      modelFile: 'gemma-2b-it-gpu-int4.bin',
      description: 'Instruction-tuned 2B model optimized for chat',
      sizeInBytes: 1476395072,
      estimatedPeakMemoryInBytes: 2684354560,
      commitHash: 'c5db5788',
      supportsImage: false,
      supportsAudio: false,
      taskTypes: ['llm_chat'],
      defaultConfig: ModelConfig(
        maxTokens: 1024,
        topK: 40,
        topP: 0.95,
        temperature: 1.0,
        accelerators: 'gpu',
      ),
    ),
    GemmaModel(
      id: 'gemma-2b',
      name: 'Gemma 2B Base',
      modelId: 'google/gemma-2b',
      modelFile: 'gemma-2b-gpu-int4.bin',
      description: 'Base 2B model for general text generation',
      sizeInBytes: 1476395072,
      estimatedPeakMemoryInBytes: 2684354560,
      commitHash: 'c5db5788',
      supportsImage: false,
      supportsAudio: false,
      taskTypes: ['llm_generation'],
      defaultConfig: ModelConfig(
        maxTokens: 512,
        topK: 40,
        topP: 0.95,
        temperature: 1.0,
        accelerators: 'gpu',
      ),
    ),
  ];

  static final List<GemmaModel> _importedModels = [];

  static List<GemmaModel> get officialModels => List.unmodifiable(_officialModels);
  static List<GemmaModel> get importedModels => List.unmodifiable(_importedModels);
  static List<GemmaModel> get allModels => [..._officialModels, ..._importedModels];

  static GemmaModel? getModelById(String id) {
    try {
      return allModels.firstWhere((model) => model.id == id);
    } catch (e) {
      return null;
    }
  }

  static void addImportedModel(GemmaModel model) {
    if (!model.isImported) {
      throw ArgumentError('Model must be marked as imported');
    }
    _importedModels.removeWhere((m) => m.id == model.id);
    _importedModels.add(model);
  }

  static void removeImportedModel(String modelId) {
    _importedModels.removeWhere((m) => m.id == modelId);
  }

  static void clearImportedModels() {
    _importedModels.clear();
  }

  static List<GemmaModel> getImportedModels() {
    return List.unmodifiable(_importedModels);
  }
}