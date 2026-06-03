// ignore_for_file: must_be_immutable
import 'package:web_ui_plugin/web_ui_plugin.dart';

class PetModel extends DataModel {
  String? id;
  String? ownerId;
  String? name;
  String? species;
  String? breed;
  int? age;

  PetModel({
    this.id,
    this.ownerId,
    this.name,
    this.species,
    this.breed,
    this.age,
  });

  PetModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    ownerId = json['ownerId'];
    name = json['name'];
    species = json['species'];
    breed = json['breed'];
    age = json['age'] is int ? json['age'] : int.tryParse(json['age']?.toString() ?? '');
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerId': ownerId,
      'name': name,
      'species': species,
      'breed': breed,
      'age': age,
    };
  }

  @override
  String get uid => id ?? '';

  @override
  String? get title => name;

  @override
  String? get subTitle => '$species ($breed)';
}
