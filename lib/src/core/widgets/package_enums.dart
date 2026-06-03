import 'package:flutter/material.dart';

enum SectionLayoutMode { list, grid }

enum SortOrder { ascending, descending }

enum SortBy { name, id }

enum SuccessStatus { waiting, success, error, warning }

enum AvailabilityStatus { available, unavailable, unsure }

//extend this enum to return color based on status
extension SuccessStatusExtension on SuccessStatus {
  Color get color {
    return switch (this) {
      SuccessStatus.waiting => Colors.grey,
      SuccessStatus.success => Colors.green,
      SuccessStatus.error => Colors.red,
      SuccessStatus.warning => Colors.amber,
    };
  }
}
