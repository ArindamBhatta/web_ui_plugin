import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// ── Section enum ──────────────────────────────────────────────────────────────
// The developer just adds values here; the plugin registry generates the sidebar.
enum VetAppSection {
  dashboard,
  petOwners,
  doctors,
  technicians,
}

extension VetAppSectionHelper on VetAppSection {
  String get label {
    switch (this) {
      case VetAppSection.dashboard:
        return 'Dashboard';
      case VetAppSection.petOwners:
        return 'Pet Owners';
      case VetAppSection.doctors:
        return 'Doctors';
      case VetAppSection.technicians:
        return 'Technicians';
    }
  }

  IconData get icon {
    switch (this) {
      case VetAppSection.dashboard:
        return FontAwesomeIcons.chartPie;
      case VetAppSection.petOwners:
        return FontAwesomeIcons.person;
      case VetAppSection.doctors:
        return FontAwesomeIcons.userDoctor;
      case VetAppSection.technicians:
        return FontAwesomeIcons.userNurse;
    }
  }

  Color get color {
    switch (this) {
      case VetAppSection.dashboard:
        return Colors.purple;
      case VetAppSection.petOwners:
        return Colors.blue;
      case VetAppSection.doctors:
        return Colors.green;
      case VetAppSection.technicians:
        return Colors.orange;
    }
  }

  int get order {
    switch (this) {
      case VetAppSection.dashboard:
        return -1;
      case VetAppSection.petOwners:
        return 0;
      case VetAppSection.doctors:
        return 1;
      case VetAppSection.technicians:
        return 2;
    }
  }
}

// ── Persona / Role enum ───────────────────────────────────────────────────────
enum VetApplicationEnums { admin, operator }

extension VetApplicationEnumsX on VetApplicationEnums {
  String get label {
    switch (this) {
      case VetApplicationEnums.admin:
        return 'Admin';
      case VetApplicationEnums.operator:
        return 'Operator';
    }
  }
}

// ── Appointment status enum ───────────────────────────────────────────────────
enum AppointmentStatus { scheduled, inProgress, completed, cancelled, noShow }

extension AppointmentStatusX on AppointmentStatus {
  String get label {
    switch (this) {
      case AppointmentStatus.scheduled:
        return 'Scheduled';
      case AppointmentStatus.inProgress:
        return 'In Progress';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.cancelled:
        return 'Cancelled';
      case AppointmentStatus.noShow:
        return 'No Show';
    }
  }

  Color get color {
    switch (this) {
      case AppointmentStatus.scheduled:
        return Colors.blue;
      case AppointmentStatus.inProgress:
        return Colors.orange;
      case AppointmentStatus.completed:
        return Colors.green;
      case AppointmentStatus.cancelled:
        return Colors.red;
      case AppointmentStatus.noShow:
        return Colors.grey;
    }
  }
}
