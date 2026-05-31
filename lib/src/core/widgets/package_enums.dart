import 'package:flutter/material.dart';

enum EntityType { weekday, taxSlab, availabilityStatus, persona }

enum SectionLayoutMode { list, grid }

enum SortOrder { ascending, descending }

enum SortBy { name, id }

enum SuccessStatus { waiting, success, error, warning }

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

enum TaxSlab { exempt, slab1, slab2, slab3, slab4 }

extension TaxSlabExtension on TaxSlab {
  double get value {
    switch (this) {
      case TaxSlab.exempt:
        return 0.0;
      case TaxSlab.slab1:
        return 5.0;
      case TaxSlab.slab2:
        return 12.0;
      case TaxSlab.slab3:
        return 18.0;
      case TaxSlab.slab4:
        return 28.0;
    }
  }
}

enum Weekday { monday, tuesday, wednesday, thursday, friday, saturday, sunday }

extension WeekdayExtension on Weekday {
  String get name {
    switch (this) {
      case Weekday.monday:
        return 'Monday';
      case Weekday.tuesday:
        return 'Tuesday';
      case Weekday.wednesday:
        return 'Wednesday';
      case Weekday.thursday:
        return 'Thursday';
      case Weekday.friday:
        return 'Friday';
      case Weekday.saturday:
        return 'Saturday';
      case Weekday.sunday:
        return 'Sunday';
    }
  }

  String get value {
    switch (this) {
      case Weekday.monday:
        return 'monday';
      case Weekday.tuesday:
        return 'tuesday';
      case Weekday.wednesday:
        return 'wednesday';
      case Weekday.thursday:
        return 'thursday';
      case Weekday.friday:
        return 'friday';
      case Weekday.saturday:
        return 'saturday';
      case Weekday.sunday:
        return 'sunday';
    }
  }

  int get index {
    switch (this) {
      case Weekday.monday:
        return 1;
      case Weekday.tuesday:
        return 2;
      case Weekday.wednesday:
        return 3;
      case Weekday.thursday:
        return 4;
      case Weekday.friday:
        return 5;
      case Weekday.saturday:
        return 6;
      case Weekday.sunday:
        return 7;
    }
  }

  // String to enum
  static Weekday fromString(String day) {
    switch (day.toLowerCase()) {
      case 'monday':
        return Weekday.monday;
      case 'tuesday':
        return Weekday.tuesday;
      case 'wednesday':
        return Weekday.wednesday;
      case 'thursday':
        return Weekday.thursday;
      case 'friday':
        return Weekday.friday;
      case 'saturday':
        return Weekday.saturday;
      case 'sunday':
        return Weekday.sunday;
      default:
        throw Exception('Invalid weekday: $day');
    }
  }
}

enum AvailabilityStatus { available, unavailable, unsure }

enum SessionStatus {
  booked,
  workInProgress,
  cancelled,
  workDone,
  noShow,
  expired,
}

SessionStatus? sessionStatusFromJson(dynamic value) {
  if (value == null) return null;
  if (value is SessionStatus) return value;

  switch (value.toString().trim().toLowerCase()) {
    case 'work in progress':
      return SessionStatus.workInProgress;
    case 'cancelled':
      return SessionStatus.cancelled;
    case 'work done':
      return SessionStatus.workDone;
    case 'booked':
      return SessionStatus.booked;
    case 'no show':
      return SessionStatus.noShow;
    case 'expired':
      return SessionStatus.expired;
    default:
      return null;
  }
}

String? sessionStatusToJson(SessionStatus? status) {
  if (status == null) return null;
  switch (status) {
    case SessionStatus.workInProgress:
      return 'work in progress';
    case SessionStatus.noShow:
      return 'no show';
    case SessionStatus.workDone:
      return 'work done';
    default:
      return status.name;
  }
}

extension AvailabilityStatusExtension on AvailabilityStatus {
  String get name {
    switch (this) {
      case AvailabilityStatus.available:
        return 'Available';
      case AvailabilityStatus.unavailable:
        return 'Unavailable';
      case AvailabilityStatus.unsure:
        return 'Unsure';
    }
  }

  Color get color {
    switch (this) {
      case AvailabilityStatus.available:
        return Colors.green;
      case AvailabilityStatus.unavailable:
        return Colors.red;
      case AvailabilityStatus.unsure:
        return Colors.amber;
    }
  }

  // String to enum
  static AvailabilityStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return AvailabilityStatus.available;
      case 'unavailable':
        return AvailabilityStatus.unavailable;
      case 'unsure':
        return AvailabilityStatus.unsure;
      default:
        throw Exception('Invalid availability status: $status');
    }
  }
}
