// ignore_for_file: must_be_immutable
import 'package:web_ui_plugin/web_ui_plugin.dart';

/// Booking model representing appointment slots, doctors, and clients.
class BookingModel extends DataModel {
  String? id;
  String? petOwnerId;
  String? petOwnerName;
  String? doctorId;
  String? doctorName;
  String? date;
  String? time;
  String? status; // 'scheduled', 'inProgress', 'completed', 'cancelled', 'noShow'

  BookingModel({
    this.id,
    this.petOwnerId,
    this.petOwnerName,
    this.doctorId,
    this.doctorName,
    this.date,
    this.time,
    this.status,
  });

  BookingModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    petOwnerId = json['petOwnerId'];
    petOwnerName = json['petOwnerName'];
    doctorId = json['doctorId'];
    doctorName = json['doctorName'];
    date = json['date'];
    time = json['time'];
    status = json['status'];
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'petOwnerId': petOwnerId,
      'petOwnerName': petOwnerName,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'date': date,
      'time': time,
      'status': status,
    };
  }

  @override
  String get uid => id ?? '';

  @override
  String? get title => 'Appointment: $doctorName';

  @override
  String? get subTitle => 'Client: $petOwnerName | $date at $time';
}
