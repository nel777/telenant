import 'package:flutter/material.dart';
import 'package:telenant/authentication/register.dart';
import 'package:telenant/home/homepage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
              bottom: -45,
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: Image.asset(
                  'assets/images/login.png',
                  fit: BoxFit.contain,
                ),
              )),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Telenant',
                    style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Baguio City transient reservation',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w300),
                  ),
                  const SizedBox(
                    height: 40,
                  ),
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(
                            borderSide: BorderSide(width: 1.0))),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.5),
                        labelText: 'Password',
                        helperText: 'Enter password maximum of 6 characters',
                        hintStyle: const TextStyle(color: Colors.black87),
                        border: const OutlineInputBorder(
                            borderSide: BorderSide(width: 1.0))),
                  ),
                  const SizedBox(
                    height: 50,
                  ),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          fixedSize: const Size(double.maxFinite, 40)),
                      onPressed: () {
                        Navigator.of(context).pushReplacement(MaterialPageRoute(
                            builder: ((context) => const HomePage())));
                      },
                      child: const Text('Login')),
                  // const SizedBox(
                  //   height: 50,
                  // ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('''Don't have an account yet?'''),
                      TextButton(
                          onPressed: () {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: ((context) => const RegisterPage())));
                          },
                          child: const Text('Register'))
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
