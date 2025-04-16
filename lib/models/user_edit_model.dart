class UserEditModel {
  String name;
  String email;
  String phone;
  String street;
  String suite;
  String city;
  String zipcode;
  String website;
  String companyName;
  String companyCatchPhrase;
  String companyBs;

  UserEditModel({
    required this.name,
    required this.email,
    required this.phone,
    required this.street,
    required this.suite,
    required this.city,
    required this.zipcode,
    required this.website,
    required this.companyName,
    required this.companyCatchPhrase,
    required this.companyBs,
  });

  Map<String, dynamic> toJson(int id) {
    return {
      "id": id,
      "name": name,
      "email": email,
      "phone": phone,
      "website": website,
      "username": name.split(' ').first,
      "address": {
        "street": street,
        "suite": suite,
        "city": city,
        "zipcode": zipcode,
        "geo": {"lat": "0.0000", "lng": "0.0000"},
      },
      "company": {
        "name": companyName,
        "catchPhrase": companyCatchPhrase,
        "bs": companyBs,
      },
    };
  }
}
