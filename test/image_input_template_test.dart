import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:gemma_mini_apps/models/shortcuts/editor_models.dart';
import 'package:gemma_mini_apps/models/shortcuts/shortcut_definition.dart';

void main() {
  group('ComponentTemplateLibrary Image Input Tests', () {
    test('should contain image input template', () {
      // Check that image input template exists in the templates list
      final templates = ComponentTemplateLibrary.templates;
      final imageInputTemplate = templates.firstWhere(
        (template) => template.id == 'image-input',
      );
      
      expect(imageInputTemplate, isNotNull);
      expect(imageInputTemplate.name, 'Image Input');
      expect(imageInputTemplate.type, ComponentType.imageInput);
      expect(imageInputTemplate.category, ComponentCategory.input);
      expect(imageInputTemplate.icon, Icons.add_a_photo);
    });

    test('image input template should have correct default properties', () {
      final templates = ComponentTemplateLibrary.templates;
      final imageInputTemplate = templates.firstWhere(
        (template) => template.id == 'image-input',
      );
      
      expect(imageInputTemplate.defaultProperties['allowCamera'], true);
      expect(imageInputTemplate.defaultProperties['allowGallery'], true);
      expect(imageInputTemplate.defaultProperties['maxImages'], 1);
      expect(imageInputTemplate.defaultProperties['required'], false);
    });

    test('image input template should have correct editable properties', () {
      final templates = ComponentTemplateLibrary.templates;
      final imageInputTemplate = templates.firstWhere(
        (template) => template.id == 'image-input',
      );
      
      final propertyKeys = imageInputTemplate.editableProperties.map((p) => p.key).toSet();
      expect(propertyKeys, contains('label'));
      expect(propertyKeys, contains('variableName'));
      expect(propertyKeys, contains('allowCamera'));
      expect(propertyKeys, contains('allowGallery'));
      expect(propertyKeys, contains('maxImages'));
      expect(propertyKeys, contains('required'));
    });

    test('getTemplate method should return image input template', () {
      final template = ComponentTemplateLibrary.getTemplate(ComponentType.imageInput);
      expect(template, isNotNull);
      expect(template?.id, 'image-input');
      expect(template?.type, ComponentType.imageInput);
    });

    test('getByCategory should include image input in input category', () {
      final inputTemplates = ComponentTemplateLibrary.getByCategory(ComponentCategory.input);
      final hasImageInput = inputTemplates.any((t) => t.id == 'image-input');
      expect(hasImageInput, true);
    });
  });
}