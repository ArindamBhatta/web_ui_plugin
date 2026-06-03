// ignore_for_file: must_be_immutable
import 'package:web_ui_plugin/web_ui_plugin.dart';

/// Staff model — the developer only writes this class and the framework
/// handles CRUD, real-time updates, form rendering, and list/detail UI.
class DoctorModel extends DataModel {
  String? id;
  String? active;
  String? name;
  String? qualifications;
  String? registrationNumber;
  String? mobile;
  String? whatsapp;
  String? email;
  String? fee;
  String? dob;

  DoctorModel({
    this.id,
    this.active,
    this.name,
    this.qualifications,
    this.registrationNumber,
    this.mobile,
    this.whatsapp,
    this.email,
    this.fee,
    this.dob,
  });

  DoctorModel copyWith({
    String? id,
    String? active,
    String? name,
    String? qualifications,
    String? registrationNumber,
    String? mobile,
    String? whatsapp,
    String? email,
    String? fee,
    String? dob,
  }) {
    return DoctorModel(
      id: id ?? this.id,
      active: active ?? this.active,
      name: name ?? this.name,
      qualifications: qualifications ?? this.qualifications,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      mobile: mobile ?? this.mobile,
      whatsapp: whatsapp ?? this.whatsapp,
      email: email ?? this.email,
      fee: fee ?? this.fee,
      dob: dob ?? this.dob,
    );
  }

  DoctorModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    active = json['active'];
    name = json['name'];
    qualifications = json['qualifications'];
    registrationNumber = json['registrationNumber'];
    mobile = json['mobile'];
    whatsapp = json['whatsapp'];
    email = json['email'];
    fee = json['fee'];
    dob = json['dob'];
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'active': active,
    'name': name,
    'qualifications': qualifications,
    'registrationNumber': registrationNumber,
    'mobile': mobile,
    'whatsapp': whatsapp,
    'email': email,
    'fee': fee,
    'dob': dob,
  };

  @override
  String get uid => id ?? '';

  @override
  String? get title => name;

  @override
  String? get subTitle => mobile;
}
