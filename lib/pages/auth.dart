import 'package:blabla/pages/login.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'home.dart';
// import 'login.dart';
import 'sign_up.dart';

class IndexPage extends StatefulWidget {
  const IndexPage({Key? key}) : super(key: key);

  @override
  IndexPageState createState() => IndexPageState();
}

class IndexPageState extends State<IndexPage> {
  late FirebaseAuth auth;
  TextEditingController numberController = TextEditingController(),
  codeController = TextEditingController();

  @override
  void initState() {
    super.initState();

    auth = FirebaseAuth.instance;
    initPermission();
  }

  initPermission() async {
    if (!(await Permission.camera.request().isGranted) ||
        !(await Permission.microphone.request().isGranted)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:
          Text('You need to have audio and video permission to enter')));
      }
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    // String verificationID = "";
    return Scaffold(
      body: StreamBuilder(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, AsyncSnapshot<User?> user){
        // return user.data == null?
        // const MyLogin(registeredEmail: "", registeredPassword: "")
        // :
        return const HomePage();
      }),
    );
  }
}
