import 'package:firebase_database/firebase_database.dart';

class User{
  final String id, name, email, phone;

  User({
    required this.name,
    required this.email,
    required this.phone,
    required this.id,
  });

  static List<User> fromSnapshot(DataSnapshot? snapshot, String id){
    if (snapshot == null) return [];
    List<User> users = [];
    for(DataSnapshot snapshot in snapshot.children){
      Map map = snapshot.value as Map;
      if (id == snapshot.child("id").value) continue;
      users.add(User(
        id: map['id'],
        name: map['name'],
        email: map['email'],
        phone: map['phone'],
      ));
    }
    return users;
  }
}