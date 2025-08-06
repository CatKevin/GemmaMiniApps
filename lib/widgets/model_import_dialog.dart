import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/gemma/models.dart';
import '../services/gemma/model_manager_service.dart';

class ModelImportDialog extends StatefulWidget {
  final File modelFile;
  final Function(GemmaModel) onImport;
  
  const ModelImportDialog({
    super.key,
    required this.modelFile,
    required this.onImport,
  });

  @override
  State<ModelImportDialog> createState() => _ModelImportDialogState();
}

class _ModelImportDialogState extends State<ModelImportDialog> {
  late TextEditingController _nameController;
  late int _fileSize;
  
  // Model configuration values
  double _maxTokens = 512;
  double _topK = 40;
  double _topP = 0.95;
  double _temperature = 1.0;
  bool _supportsImage = false;
  bool _supportsAudio = false;
  List<String> _selectedAccelerators = ['cpu'];
  
  // Import state
  bool _isImporting = false;
  double _importProgress = 0.0;
  String? _importError;
  
  @override
  void initState() {
    super.initState();
    final fileName = widget.modelFile.path.split('/').last;
    _nameController = TextEditingController(
      text: fileName.replaceAll('.task', '').replaceAll('_', ' '),
    );
    _fileSize = widget.modelFile.lengthSync();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
  
  Future<void> _performImport() async {
    if (_isImporting) return;
    
    setState(() {
      _isImporting = true;
      _importProgress = 0.0;
      _importError = null;
    });
    
    try {
      print('Starting model import process');
      print('Model name: ${_nameController.text}');
      print('Selected accelerators: $_selectedAccelerators');
      print('Supports image: $_supportsImage');
      print('File path: ${widget.modelFile.path}');
      
      // Create the imported model
      final model = GemmaModel(
        id: 'imported_${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        modelId: 'local',
        modelFile: widget.modelFile.path.split('/').last,
        description: 'Imported model from local file',
        sizeInBytes: _fileSize,
        estimatedPeakMemoryInBytes: _fileSize * 2,
        commitHash: '',
        supportsImage: _supportsImage,
        supportsAudio: _supportsAudio,
        taskTypes: ['llm_chat', 'llm_prompt_lab'],
        defaultConfig: ModelConfig(
          maxTokens: _maxTokens.toInt(),
          topK: _topK.toInt(),
          topP: _topP,
          temperature: _temperature,
          accelerators: _selectedAccelerators.contains('gpu') ? 'gpu' : 'cpu',
        ),
        isImported: true,
        localFilePath: widget.modelFile.path,
      );
      
      print('Model object created successfully');
      
      setState(() {
        _importProgress = 0.3;
      });
      
      // Perform the actual import using ModelManagerService
      final modelManager = ModelManagerService();
      
      setState(() {
        _importProgress = 0.5;
      });
      
      print('Calling ModelManagerService.importModel');
      final success = await modelManager.importModel(widget.modelFile, model);
      
      if (success) {
        print('Import completed successfully');
        
        setState(() {
          _importProgress = 1.0;
        });
        
        // Wait a moment to show completion
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Try to clean up the temp file (from file_picker cache)
        try {
          print('Attempting to clean up temp file: ${widget.modelFile.path}');
          if (await widget.modelFile.exists() && widget.modelFile.path.contains('cache/file_picker')) {
            await widget.modelFile.delete();
            print('Temp file cleaned up');
          }
        } catch (e) {
          print('Could not clean up temp file: $e');
        }
        
        // Call the original callback and close dialog
        widget.onImport(model);
        
        if (mounted) {
          Navigator.of(context).pop();
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${model.name} imported successfully'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        print('Import failed');
        setState(() {
          _isImporting = false;
          _importError = 'Failed to import model. Check app logs for details.';
        });
      }
      
    } catch (e, stackTrace) {
      print('Exception during import: $e');
      print('Stack trace: $stackTrace');
      
      setState(() {
        _isImporting = false;
        _importError = 'Import failed: $e';
      });
    }
  }
  
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / 1024 / 1024).toStringAsFixed(2)} MB';
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                'Import Model',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Configure your model settings',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 24),
              
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Model name
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Model Name',
                          hintText: 'Enter a name for your model',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // File info
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.insert_drive_file,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.modelFile.path.split('/').last,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    'Size: ${_formatFileSize(_fileSize)}',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Configuration section
                      Text(
                        'Model Configuration',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      
                      // Max Tokens
                      _buildSlider(
                        label: 'Max Tokens',
                        value: _maxTokens,
                        min: 100,
                        max: 2048,
                        divisions: 20,
                        onChanged: (value) => setState(() => _maxTokens = value),
                      ),
                      
                      // Top K
                      _buildSlider(
                        label: 'Top K',
                        value: _topK,
                        min: 5,
                        max: 100,
                        divisions: 20,
                        onChanged: (value) => setState(() => _topK = value),
                      ),
                      
                      // Top P
                      _buildSlider(
                        label: 'Top P',
                        value: _topP,
                        min: 0.0,
                        max: 1.0,
                        divisions: 20,
                        onChanged: (value) => setState(() => _topP = value),
                      ),
                      
                      // Temperature
                      _buildSlider(
                        label: 'Temperature',
                        value: _temperature,
                        min: 0.0,
                        max: 2.0,
                        divisions: 20,
                        onChanged: (value) => setState(() => _temperature = value),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Feature toggles
                      Text(
                        'Supported Features',
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      
                      CheckboxListTile(
                        title: const Text('Image Support'),
                        subtitle: const Text('Model can process images'),
                        value: _supportsImage,
                        onChanged: (value) => setState(() => _supportsImage = value ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      
                      CheckboxListTile(
                        title: const Text('Audio Support'),
                        subtitle: const Text('Model can process audio'),
                        value: _supportsAudio,
                        onChanged: (value) => setState(() => _supportsAudio = value ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Accelerators
                      Text(
                        'Compatible Accelerators',
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      
                      Wrap(
                        spacing: 8,
                        children: [
                          FilterChip(
                            label: const Text('CPU'),
                            selected: _selectedAccelerators.contains('cpu'),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedAccelerators.add('cpu');
                                } else {
                                  _selectedAccelerators.remove('cpu');
                                }
                              });
                            },
                          ),
                          FilterChip(
                            label: const Text('GPU'),
                            selected: _selectedAccelerators.contains('gpu'),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedAccelerators.add('gpu');
                                } else {
                                  _selectedAccelerators.remove('gpu');
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Import progress section
              if (_isImporting) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.file_upload,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Importing ${_nameController.text}...',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: theme.colorScheme.primary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: _importProgress,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(_importProgress * 100).toStringAsFixed(0)}% complete',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Error section
              if (_importError != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: theme.colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _importError!,
                          style: TextStyle(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: !_isImporting ? () => Navigator.of(context).pop() : null,
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  if (_importError != null)
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _importError = null;
                        });
                        _performImport();
                      },
                      child: const Text('Retry'),
                    )
                  else
                    ElevatedButton(
                      onPressed: _selectedAccelerators.isNotEmpty && _nameController.text.isNotEmpty && !_isImporting
                          ? () => _performImport()
                          : null,
                      child: _isImporting 
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Import'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    final isInteger = label.contains('Tokens') || label.contains('Top K');
    final displayValue = isInteger ? value.toInt().toString() : value.toStringAsFixed(2);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(
              displayValue,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }
}