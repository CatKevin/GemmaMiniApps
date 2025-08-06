import 'dart:io';
import 'package:flutter/material.dart';

class ModelImportProgressDialog extends StatelessWidget {
  final String fileName;
  final double progress;
  final String? error;
  
  const ModelImportProgressDialog({
    super.key,
    required this.fileName,
    required this.progress,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              'Importing Model',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            
            // Error state
            if (error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
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
                        error!,
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ]
            // Progress state
            else ...[
              Text(
                fileName,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              
              LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              
              Text(
                '${(progress * 100).toStringAsFixed(1)}% complete',
                style: theme.textTheme.bodySmall,
              ),
              
              if (progress >= 1.0) ...[
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Import complete!',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}