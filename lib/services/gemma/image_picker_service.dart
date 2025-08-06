import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerService {
  static final ImagePicker _picker = ImagePicker();

  /// Pick an image from gallery
  static Future<Uint8List?> pickImageFromGallery() async {
    try {
      print('DEBUG: Starting to pick image from gallery');
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        final bytes = await image.readAsBytes();
        print('DEBUG: Successfully picked image from gallery. Size: ${bytes.length} bytes');
        return bytes;
      } else {
        print('DEBUG: No image selected from gallery');
        return null;
      }
    } catch (e) {
      print('ERROR: Error picking image from gallery: $e');
      return null;
    }
  }

  /// Take a photo with camera
  static Future<Uint8List?> takePhoto() async {
    try {
      print('DEBUG: Starting to take photo with camera');
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        final bytes = await image.readAsBytes();
        print('DEBUG: Successfully took photo with camera. Size: ${bytes.length} bytes');
        return bytes;
      } else {
        print('DEBUG: Photo capture cancelled');
        return null;
      }
    } catch (e) {
      print('ERROR: Error taking photo: $e');
      return null;
    }
  }

  /// Pick multiple images from gallery
  static Future<List<Uint8List>> pickMultipleImages({int maxImages = 5}) async {
    try {
      print('DEBUG: Starting to pick multiple images from gallery (max: $maxImages)');
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (images.isEmpty) {
        print('DEBUG: No images selected');
        return [];
      }
      
      print('DEBUG: User selected ${images.length} images');
      
      // Limit the number of images
      final selectedImages = images.take(maxImages).toList();
      if (images.length > maxImages) {
        print('DEBUG: Limited to first $maxImages images');
      }
      
      final List<Uint8List> imageBytes = [];
      for (int i = 0; i < selectedImages.length; i++) {
        final image = selectedImages[i];
        final bytes = await image.readAsBytes();
        imageBytes.add(bytes);
        print('DEBUG: Processed image ${i + 1}/${selectedImages.length}, size: ${bytes.length} bytes');
      }
      
      print('DEBUG: Successfully processed ${imageBytes.length} images');
      return imageBytes;
    } catch (e) {
      print('ERROR: Error picking multiple images: $e');
      return [];
    }
  }

  /// Show dialog to choose image source
  static Future<List<Uint8List>> showImageSourceDialog(BuildContext context) async {
    final List<Uint8List>? selectedImages = await showModalBottomSheet<List<Uint8List>>(
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
                    print('DEBUG: User chose gallery from image source dialog');
                    final images = await pickMultipleImages();
                    print('DEBUG: Picked ${images.length} images from gallery, returning them');
                    Navigator.pop(context, images); // Return the images
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
                    print('DEBUG: User chose camera from image source dialog');
                    final image = await takePhoto();
                    if (image != null) {
                      print('DEBUG: Took photo with camera, returning it');
                      Navigator.pop(context, [image]); // Return the single image in a list
                    } else {
                      print('DEBUG: No photo taken from camera');
                      Navigator.pop(context, <Uint8List>[]); // Return empty list
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
    
    return selectedImages ?? [];
  }
}