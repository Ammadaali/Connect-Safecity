class GuardianModel {
  String? name;
  String? id;
  String? phone;
  String? gemail;
  String? type;

  GuardianModel({this.name, this.gemail, this.id, this.phone, this.type});

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        'id': id,
        'guardianEmail': gemail,
        'type': type
      };
}
