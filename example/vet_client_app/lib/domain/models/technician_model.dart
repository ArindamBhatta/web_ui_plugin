// ignore_for_file: must_be_immutable

import 'package:web_ui_plugin/web_ui_plugin.dart';

class TechnicianModel extends DataModel {
  String? id;
  String? active;
  String? name;
  String? designation;
  String? mobile;
  String? whatsapp;
  String? dob;
  String? address;
  String? aadhaarUid;
  List<String>? uploads;

  TechnicianModel({
    this.id,
    this.active,
    this.name,
    this.designation,
    this.mobile,
    this.whatsapp,
    this.dob,
    this.address,
    this.aadhaarUid,
    this.uploads,
  });

  TechnicianModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    active = json['active'];
    name = json['name'];
    designation = json['designation'];
    mobile = json['mobile'];
    whatsapp = json['whatsapp'];
    dob = json['dob'];
    address = json['address'];
    aadhaarUid = json['aadhaarUid'];
    if (json['uploads'] != null) {
      uploads = List<String>.from(json['uploads']);
    }
  }

  @override
  String? get uid => id;

  @override
  String? get title => name;

  @override
  String? get subTitle => mobile;

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = id;
    data['active'] = active;
    data['name'] = name;
    data['designation'] = designation;
    data['mobile'] = mobile;
    data['whatsapp'] = whatsapp;
    data['dob'] = dob;
    data['address'] = address;
    data['aadhaarUid'] = aadhaarUid;
    data['uploads'] = uploads;
    return data;
  }

  TechnicianModel copyWith({
    String? id,
    String? active,
    String? name,
    String? designation,
    String? mobile,
    String? whatsapp,
    String? dob,
    String? address,
    String? aadhaarUid,
    List<String>? uploads,
  }) {
    return TechnicianModel(
      id: id ?? this.id,
      active: active ?? this.active,
      name: name ?? this.name,
      designation: designation ?? this.designation,
      mobile: mobile ?? this.mobile,
      whatsapp: whatsapp ?? this.whatsapp,
      dob: dob ?? this.dob,
      address: address ?? this.address,
      aadhaarUid: aadhaarUid ?? this.aadhaarUid,
      uploads: uploads ?? this.uploads,
    );
  }
}
