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
              TextFormField(
                controller: _fullnameController,
                decoration: const InputDecoration(
                    labelText: 'Fullname',
                    border:
                        OutlineInputBorder(borderSide: BorderSide(width: 1.0))),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                child: TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(
                          borderSide: BorderSide(width: 1.0))),
                ),
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                    labelText: 'Password',
                    helperText: 'Minimum of 6 characters',
                    border:
                        OutlineInputBorder(borderSide: BorderSide(width: 1.0))),
              ),
            ],
          ),
        ]),
      ),
    );
  }
}
