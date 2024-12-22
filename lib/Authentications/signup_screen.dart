import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../methods/common_methods.dart';
import '../pages/home_page.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _username = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  CommonMethods cMethods = CommonMethods();
  checkIfNetworkIsAvailable()
  {
    cMethods.checkConnectivity(context);

  }
  signUpFormValidation()
  {
    if (_username.text.trim().length < 3)
    {
      cMethods.displaysnackBar("Your name must be atleast 4 or more characters. ", context);
    }
    else if (_passwordController.text.trim().length < 8)
    {
      cMethods.displaysnackBar("Your password must be atleast 8 or more characters. ", context);
    }
    else if (_phoneController.text.trim().length < 11)
    {
      cMethods.displaysnackBar("Your phone must be atleast 8 or more numbers. ", context);
    }
    else if (!_emailController.text.contains("@"))
    {
      cMethods.displaysnackBar("Please enter valid email. ", context);
    }
    else
    {
      registerNewUser();
    }
  }


  registerNewUser()async
  {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context )=> Center(child: CircularProgressIndicator(),),
    );

    try {
      FirebaseAuth auth = FirebaseAuth.instance;
      UserCredential userCredential = await auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      Navigator.pop(context); // Close the dialog
      cMethods.displaysnackBar(
          "Registration successful! Welcome, ${userCredential.user!.email}",
          context);

      // Optionally navigate to another screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (c) => HomePage()),
      );
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context); // Close the dialog
      if (e.code == 'email-already-in-use') {
        cMethods.displaysnackBar("Email is already in use.", context);
      } else if (e.code == 'weak-password') {
        cMethods.displaysnackBar("Password is too weak.", context);
      } else {
        cMethods.displaysnackBar("Error: ${e.message}", context);
      }
    } catch (e) {
      Navigator.pop(context); // Close the dialog
      cMethods.displaysnackBar("An error occurred. Please try again.", context);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(),
        body: SingleChildScrollView(
          child:
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const Text("Sign up",
                    style:TextStyle(
                      fontSize: 30.0,
                      fontWeight: FontWeight.bold,
                    )
                ),
                const SizedBox(height: 20.0,),
                TextFormField(
                  controller: _username,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: "Name",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),

                  ),
                ),
//phone
                const SizedBox(height: 20.0,),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Phone",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),

                  ),
                ),

//email
                const SizedBox(height: 20.0,),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),

                  ),
                ),

                //password
                const SizedBox(height: 20.0,),
                TextFormField(
                  controller: _passwordController,
                  keyboardType: TextInputType.visiblePassword,
                  decoration: const InputDecoration(
                    labelText: "Password",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),

                  ),
                ),

                const SizedBox(height: 20.0),
                ElevatedButton(
                  onPressed: (){
                    checkIfNetworkIsAvailable();
                    signUpFormValidation();
                  },
                  child: const Text("Sign up"),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                        'Already have an account?'
                    ),
                    TextButton(onPressed: ()
                    {
                      Navigator.push(context, MaterialPageRoute(builder: (c)=> LoginScreen()));
                    },
                      child: const Text("Log In"),
                    ),
                  ],
                )
              ],
            ),
          ),
        )
    );
  }
}
