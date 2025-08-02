import 'package:flutter/material.dart';

/// Categories for organizing shortcuts
enum ShortcutCategory {
  work('Work', Icons.work, 'Work-related shortcuts'),
  study('Study', Icons.school, 'Educational and learning shortcuts'),
  creative('Creative', Icons.palette, 'Creative writing and content'),
  life('Life', Icons.favorite, 'Daily life and personal'),
  development('Development', Icons.code, 'Programming and technical'),
  business('Business', Icons.business, 'Business and professional'),
  other('Other', Icons.more_horiz, 'Miscellaneous shortcuts');

  final String displayName;
  final IconData icon;
  final String description;

  const ShortcutCategory(this.displayName, this.icon, this.description);

  static ShortcutCategory fromString(String value) {
    return ShortcutCategory.values.firstWhere(
      (category) => category.name == value,
      orElse: () => ShortcutCategory.other,
    );
  }
}