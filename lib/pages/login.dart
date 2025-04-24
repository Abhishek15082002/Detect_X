import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'choose.dart';

class MyLogin extends StatefulWidget {
  final String registeredEmail;
  final String registeredPassword;


  const MyLogin({
    super.key,
    required this.registeredEmail,
    required this.registeredPassword,
  });

  @override
  MyLoginState createState() => MyLoginState();
}

class MyLoginState extends State<MyLogin> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _showSignUpButton = false;
  bool isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void handleSwitchToLogin() {
    final enteredEmail = _emailController.text;
    final enteredPassword = _passwordController.text;

    if (enteredEmail == widget.registeredEmail &&
        enteredPassword == widget.registeredPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login successful')),
      );
      setState(() {
        _showSignUpButton = false;
      });

      // Navigate to Choose screen
      Future.delayed(const Duration(milliseconds: 500), () {
        if(mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const Choose()),
          );
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid email or password')),
      );
      setState(() {
        _showSignUpButton = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/BackGround.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Container( //1 for image
              alignment: Alignment.topCenter,
              padding: const EdgeInsets.only(top: 50),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/logo.png',
                    height: 400,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Welcome Back',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 33,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).size.height * 0.5,
                  right: 36,
                  left: 36,
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        fillColor: Colors.grey.shade100,
                        filled: true,
                        hintText: "Email",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        fillColor: Colors.grey.shade100,
                        filled: true,
                        hintText: "Password",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: handleSwitchToLogin,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade900,
                          foregroundColor: Colors.white,
                          minimumSize: Size(360, 60),
                          textStyle: const TextStyle(fontSize: 20),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)
                          )
                      ),
                      child: const Text("Sign In"),
                    ),
                    if (_showSignUpButton) ...[
                      const SizedBox(height: 10),
                      const Text(
                        "Don't have an account?",
                        style: TextStyle(color: Colors.white),
                      ),
                      TextButton(
                        onPressed: (() => handleLogin(context)),
                        child: const Text(
                          "New here? Sign Up",
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 20,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> handleLogin(BuildContext context) async {
    // Get values from controllers
    String email = _emailController.text.trim();
    String password = _passwordController.text;

    // UserProvider provider = Provider.of<UserProvider>(context, listen: false);

    try {
      // provider.loggingIn = true;

      // Sign in user with email and password
      // UserCredential userCredential =
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get the user ID
      // String userId = userCredential.user?.uid ?? "";
      // provider.user.id = userId;

      // provider.loggingIn = false;

      if (mounted) {
        // Navigate to home or dashboard screen after successful login
        setState(() => isLoading = true);
      }
    } catch (e) {
      // provider.loggingIn = false;

      if (e is FirebaseAuthException) {
        if(context.mounted) {
          if (e.code == 'user-not-found') {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("No user found with this email"))
            );
          } else if (e.code == 'wrong-password') {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Incorrect password"))
            );
          } else {
            // Log the error to Realtime Database
            await FirebaseDatabase.instance.ref()
                .child("logs")
                .push()
                .set({
              "error": "Login error: ${e.code}",
              "stack_trace": e.message,
              "timestamp": ServerValue.timestamp,
            });

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Login failed. Please try again."))
              );
            }
          }
        }
      }

      // Stay on login screen
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }
}
