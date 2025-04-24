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
        return user.data == null?
        const MySignUp()
        /*Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.deepPurple,
            title: const Row(

              mainAxisAlignment: MainAxisAlignment.spaceBetween,
            ),
          ),

          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              TextField(
                keyboardType: const TextInputType.numberWithOptions(signed: true),
                controller: numberController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  filled: true,
                  fillColor: const Color(0xFF242424),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.0),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: UnderlineInputBorder(
                      borderRadius: BorderRadius.circular(16)
                  ),
                ),
              ), //text field for phone number

              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: () async {
                  await auth.verifyPhoneNumber(
                    phoneNumber: "+91${numberController.text}",
                    verificationCompleted: (PhoneAuthCredential credential) async {
                      await auth.signInWithCredential(credential);
                    },
                    verificationFailed: (FirebaseAuthException error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Verification Failed")
                          ));
                    },
                    codeSent: (String verificationId, int? forceResendingToken) {
                      verificationID = verificationId;
                    },
                    codeAutoRetrievalTimeout: (String verificationId) {
                      verificationID = verificationId;
                    },
                  );
                },
                child: const Text('Login'),
              ),

              const SizedBox(height: 32),

              TextField(
                keyboardType: const TextInputType.numberWithOptions(signed: true),
                controller: codeController,
                decoration: InputDecoration(
                  labelText: 'Verification Code',
                  filled: true,
                  fillColor: const Color(0xFF242424),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.0),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: UnderlineInputBorder(
                      borderRadius: BorderRadius.circular(16)
                  ),
                ),
              ),

              const SizedBox(height: 16),

              ElevatedButton(

                onPressed: () async {
                  if(verificationID != "") {
                    PhoneAuthCredential credential = PhoneAuthProvider.credential(
                      verificationId: verificationID,
                      smsCode: codeController.text,
                    );
                    await auth.signInWithCredential(credential);

                    FirebaseDatabase.instance.ref()
                        .child(auth.currentUser!.uid.toString())
                        .set({
                      "id": auth.currentUser?.phoneNumber
                    });
                  }else{
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid code")));
                  }
                },
                child: const Text('Verify'),
              ),
            ],
          ),
        )*/ :
        const HomePage();
      }),
    );
  }
}
