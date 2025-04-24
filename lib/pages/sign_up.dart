import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class MySignUp extends StatefulWidget {
  const MySignUp({Key? key}) : super(key: key);

  @override
  MySignUpState createState() => MySignUpState();
}

class MySignUpState extends State<MySignUp> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/backGround.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        // appBar: AppBar(
        //   // backgroundColor: Colors.purpleAccent,
        //   title: Row(
        //     mainAxisAlignment: MainAxisAlignment.center,
        //     children: [
        //       Text(
        //         "Detect X ",
        //         style: TextStyle(fontSize: 40, fontStyle: FontStyle.italic),
        //       ),
        //       // CircleAvatar(
        //       //   radius: 20,
        //       //   backgroundImage: NetworkImage(
        //       //       "https://img.freepik.com/free-psd/3d-illustration-human-avatar-profile_23-2150671142.jpg"),
        //       // )
        //     ],
        //   ),
        // ),
        backgroundColor: Colors.transparent,
        body: !isLoading ? SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.only(
              top: 48,
              right: 24,
              left: 24,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                spacing: 16,
                children: [
                  Image.asset(
                    'assets/logo.png',
                    height: 200,
                    width: MediaQuery.of(context).size.width,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: "Name",
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: "Phone",
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your phone number';
                      } else if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                        return 'Enter a valid 10-digit phone number';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: "Email",
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      } else if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value)) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: "Password",
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter password';
                      } else if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(),
                  ElevatedButton(
                    onPressed: () => handleSignUp(context),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade900,
                        foregroundColor: Colors.white,
                        textStyle: TextStyle(fontSize: 20),
                        minimumSize: Size(400, 60),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)
                        )
                    ),
                    child: Text("Sign Up"),
                  )
                ],
              ),
            ),
          ),
        ):  Center(child: CircularProgressIndicator()),
      ),
    );
  }
  // New
  handleSignUp(BuildContext context) async {
    // Get values from controllers
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String name = _nameController.text.trim();
    String phone = _phoneController.text.trim();

    // UserProvider provider = Provider.of<UserProvider>(context, listen: false);

    try {
      // provider.registeringUser = true;

      // Create user with email and password
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get the user ID
      String userId = userCredential.user?.uid ?? "";
      // provider.user.id = userId;

      // Save all user data to Realtime Database
      await saveDataToRealtimeDatabase(userId, name, email, password, phone);

      // provider.registeringUser = false;

      if (mounted) {
        setState(() => isLoading = true);
      }
    } catch (e) {
      if (e is FirebaseAuthException) {
        if (e.code == 'email-already-in-use' && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("User already registered"))
          );
          setState(() => isLoading = false);
          return;
        }

        // Log the error to Realtime Database
        await FirebaseDatabase.instance.ref()
            .child("logs")
            .push()
            .set({
          "error": "Unhandled auth exception: ${e.code}",
          "stack_trace": e.message,
          "timestamp": ServerValue.timestamp,
        });
      }

      // Handle other errors
      if (mounted) {
        setState(() => isLoading = false  );
      }
    }
  }

// Helper function to save user data to Realtime Database
  Future<void> saveDataToRealtimeDatabase(
      String userId,
      String name,
      String email,
      String password,
      String phone) async {
    // Create a reference to the user data location
    final DatabaseReference userRef = FirebaseDatabase.instance.ref().child('users').child(userId);

    // Add user data to Realtime Database
    await userRef.set({
      'id': userId,
      'name': name,
      'email': email,
      'password': password, // Note: storing passwords in DB is usually not recommended
      'phone': phone,
      'createdAt': ServerValue.timestamp,
    });
  }
}
