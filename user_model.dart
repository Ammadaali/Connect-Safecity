import 'dart:ffi';

class UserModel {
  String? name;
  String? id;
  String? phone;
  String? childEmail;
  String? guardianEmail;
  String? type;
  bool? isDeleted;

  UserModel(
      {this.name,
      this.childEmail,
      this.id,
      this.guardianEmail,
      this.phone,
      this.type,
      this.isDeleted});

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        'id': id,
        'childEmail': childEmail,
        'guardiantEmail': guardianEmail,
        'type': type,
        'isDeleted': isDeleted,
      };
}
