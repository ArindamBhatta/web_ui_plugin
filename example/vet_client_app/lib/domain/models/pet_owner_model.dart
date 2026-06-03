// ignore_for_file: must_be_immutable
import 'package:web_ui_plugin/web_ui_plugin.dart';

/// Pet owner model — the minimal model a developer defines to onboard a new section.
class PetOwnerModel extends DataModel {
  String? id;
  String? name;
  String? address;
  String? mobile;
  String? email;
  String? whatsapp;

  PetOwnerModel({
    this.id,
    this.name,
    this.address,
    this.mobile,
    this.email,
    this.whatsapp,
  });

  PetOwnerModel copyWith({
    String? id,
    String? name,
    String? address,
    String? mobile,
    String? alternateMobile,
    String? email,
    String? whatsapp,
    String? pincode,
  }) {
    return PetOwnerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      whatsapp: whatsapp ?? this.whatsapp,
    );
  }

  PetOwnerModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    address = json['address'];
    mobile = json['mobile'];
    email = json['email'];
    whatsapp = json['whatsapp'];
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = id;
    data['name'] = name;
    data['address'] = address;
    data['mobile'] = mobile;
    data['email'] = email;
    data['whatsapp'] = whatsapp;
    return data;
  }

  @override
  String? get uid => id;

  @override
  String? get title => name;

  @override
  String? get subTitle => mobile;
}
