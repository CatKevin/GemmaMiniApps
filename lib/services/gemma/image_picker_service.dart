import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerService {
  static final ImagePicker _picker = ImagePicker();

  /// Pick an image from gallery
  static Future<Uint8List?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        return await image.readAsBytes();
      }
      return null;
    } catch (e) {
      print('Error picking image from gallery: $e');
      return null;
    }
  }

  /// Take a photo with camera
  static Future<Uint8List?> takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        return await image.readAsBytes();
      }
      return null;
    } catch (e) {
      print('Error taking photo: $e');
      return null;
    }
  }

  /// Pick multiple images from gallery
  static Future<List<Uint8List>> pickMultipleImages({int maxImages = 5}) async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (images.isEmpty) {
        return [];
      }
      
      // Limit the number of images
      final selectedImages = images.take(maxImages).toList();
      
      final List<Uint8List> imageBytes = [];
      for (final image in selectedImages) {
        final bytes = await image.readAsBytes();
        imageBytes.add(bytes);
      }
      
      return imageBytes;
    } catch (e) {
      print('Error picking multiple images: $e');
      return [];
    }
  }

  /// Show dialog to choose image source
  static Future<List<Uint8List>> showImageSourceDialog(BuildContext context) async {
    final List<Uint8List> selectedImages = [];
    
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: Icon(
                    Icons.photo_library,
                    color: theme.colorScheme.onSurface,
                  ),
                  title: Text(
                    'Choose from Gallery',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    final images = await pickMultipleImages();
                    selectedImages.addAll(images);
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.camera_alt,
                    color: theme.colorScheme.onSurface,
                  ),
                  title: Text(
                    'Take Photo',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    final image = await takePhoto();
                    if (image != null) {
                      selectedImages.add(image);
                    }
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
    
    return selectedImages;
  }
}