import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:ionicons/ionicons.dart';

import '../calling/audio_call_page.dart';
import '../calling/video_call_page.dart';
import '../models/user_model.dart' as my_user;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Phonix'),
        backgroundColor: Colors.white,
        actions: [
          IconButton(onPressed: (){
            FirebaseAuth.instance.signOut();
          }, icon: const Icon(Iconsax.logout5)),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 16, children: [
          const SizedBox(),
          const Text("Contacts", ),
          Expanded(child: ListView(children: [
            FutureBuilder(
                future: FirebaseDatabase.instance.ref().get(),
                builder: (context, AsyncSnapshot<DataSnapshot> snapshot){
                  List<my_user.User> users = my_user.User.fromSnapshot(
                      snapshot.data,
                      FirebaseAuth.instance.currentUser?.email ?? ""
                  );
                  return Column(children: users.map<Widget>( (my_user.User user) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [BoxShadow(color: Colors.grey.shade300.withAlpha(64), blurRadius: 8)],
                      ),
                      width: MediaQuery.of(context).size.width,
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      child: Row(children: [
                        const SizedBox(width: 4),
                        Expanded(child: Row(children: [
                          const Icon(Ionicons.person_circle, size: 32),
                          const SizedBox(width: 16),
                          Text(user.id, style: const TextStyle(fontSize: 16)),
                        ])),
                        Row(children: [
                          IconButton(
                            onPressed: (){
                              String myId = FirebaseAuth.instance.currentUser!.uid;
                              String otherId = user.id;

                              String roomId = myId + otherId;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AudioCallingPage(roomId: roomId, userId: myId)
                                ),
                              );
                            },
                            icon: const Icon(Iconsax.call5),
                          ),
                          IconButton(
                            onPressed: (){
                              String myNumber = FirebaseAuth.instance.currentUser!.phoneNumber!;
                              int otherId = int.parse(user.id),
                                  myId = int.parse(myNumber);

                              int roomId = myId + otherId;

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => VideoCallingPage(roomId: roomId, userId: myNumber)
                                ),
                              );
                            },
                            icon: const Icon(Iconsax.video5),
                          ),
                        ]),
                      ]),
                    );
                  }).toList(),);
                })
          ],))
        ],),
      ),
    );
  }
}
