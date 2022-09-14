import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _fullnameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String passwordStr = '';
  String emailAvail = '';
  bool loading = false;
  @override
  void dispose() {
    _fullnameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.only(top: 16.0, right: 16.0, left: 16.0),
        child: Stack(children: [
          Positioned(
              bottom: -45,
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: Image.asset(
                  'assets/images/login.png',
                  fit: BoxFit.contain,
                ),
              )),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            //crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Center(
                child: Text(
                  'REGISTER',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              // TextFormField(
              //   controller: _fullnameController,
              //   decoration: const InputDecoration(
              //       labelText: 'Fullname',
              //       border:
              //           OutlineInputBorder(borderSide: BorderSide(width: 1.0))),
              // ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                child: TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                      labelText: 'Email',
                      errorText: emailAvail == '' ? null : emailAvail,
                      border: const OutlineInputBorder(
                          borderSide: BorderSide(width: 1.0))),
                ),
              ),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                    labelText: 'Password',
                    helperText: 'Minimum of 6 characters',
                    errorText: passwordStr == '' ? null : passwordStr,
                    border: const OutlineInputBorder(
                        borderSide: BorderSide(width: 1.0))),
              ),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      fixedSize: const Size(double.maxFinite, 40)),
                  onPressed: () async {
                    setState(() {
                      loading = true;
                    });
                    try {
                      final credential = await FirebaseAuth.instance
                          .createUserWithEmailAndPassword(
                        email: _usernameController.text,
                        password: _passwordController.text,
                      );
                      setState(() {
                        loading = false;
                      });
                      showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: ((context) {
                            return AlertDialog(
                              title: const Text('Success'),
                              content: const Text(
                                  'Successfully registered your credentials.'),
                              actions: [
                                ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text('Okay'))
                              ],
                            );
                          }));
                    } on FirebaseAuthException catch (e) {
                      if (e.code == 'weak-password') {
                        setState(() {
                          emailAvail = '';
                          passwordStr = 'The password provided is too weak.';
                        });
                      } else if (e.code == 'email-already-in-use') {
                        print('The account already exists for that email.');
                        setState(() {
                          passwordStr = '';
                          emailAvail =
                              'The account already exists for that email.';
                        });
                      }
                      setState(() {
                        loading = false;
                      });
                    } catch (e) {
                      setState(() {
                        loading = false;
                      });
                      print(e);
                    }
                  },
                  child: loading
                      ? const SizedBox(
                          height: 25,
                          width: 25,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        )
                      : const Text('Register')),
            ],
          ),
        ]),
      ),
    );
  }
}
