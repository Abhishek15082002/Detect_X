import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
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

  // @override
  // void initState() {
  //   super.initState();
  //
  //   FirebaseDatabase.instance.ref("kuchbhi").set({"kuchnhi": "lamba"});
  //
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Phonix', style: TextStyle(color: Colors.white),),
          backgroundColor: const Color(0xFF242627),
          actions: [
            IconButton(onPressed: (){
              FirebaseAuth.instance.signOut();
            }, icon: const Icon(Ionicons.log_out, color: Colors.white))
          ],
        ),
        body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 16,),
          const Text("Contacts", style: TextStyle(fontSize: 16),),
          Expanded(child: ListView(children: [
            FutureBuilder(
                future: FirebaseDatabase.instance.ref().get(),
                builder: (context, AsyncSnapshot<DataSnapshot> snapshot){
                  List<my_user.User> users = my_user.User.fromSnapshot(
                      snapshot.data,
                      FirebaseAuth.instance.currentUser?.phoneNumber
                  );
                  return Column(children: users.map<Widget>( (user) {
                    return Container(
                      width: MediaQuery.of(context).size.width,
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Row(children: [
                          const Icon(Ionicons.person_circle, size: 32),
                          const SizedBox(width: 16),
                          Text(user.id, style: const TextStyle(fontSize: 16)),
                        ]),
                        Row(children: [
                          IconButton(
                            onPressed: (){
                              String myNumber = FirebaseAuth.instance.currentUser!.phoneNumber!;
                              int otherId = int.parse(user.id),
                                  myId = int.parse(myNumber);

                              int roomId = myId + otherId;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AudioCallingPage(roomId: roomId, userId: myNumber)
                                ),
                              );
                            },
                            icon: const Icon(Ionicons.call_outline, color: Colors.white),
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
                            icon: const Icon(Ionicons.videocam_outline, color: Colors.white),
                          ),
                        ])
                      ]),
                    );
                  }).toList(),);
                })
          ],))
        ],),
    );
  }
}
