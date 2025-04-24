import 'package:firebase_database/firebase_database.dart';

class User{
  final String id;

  User({required this.id});

  static List<User> fromSnapshot(DataSnapshot? snapshot, String id){
    if (snapshot == null) return [];
    List<User> users = [];
    for(DataSnapshot snapshot in snapshot.children){
      if (id == snapshot.child("id").value) continue;
      users.add(User(id: snapshot.child("id").value.toString()));
    }
    return users;
  }
}