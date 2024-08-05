import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:telenant/FirebaseServices/services.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _fullnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _idTypeController = TextEditingController();
  final TextEditingController _idNumberController = TextEditingController();

  String passwordStr = '';
  String emailAvail = '';
  String personalIdType = '';
  String personalIdIssuedDate = '';
  DateTime birthDate = DateTime.now();
  bool loading = false;

  List<String> idTypes = [
    'National ID',
    'Passport',
    "Driver’s License",
    'SSS UMID',
    'PRC ID',
    "Voter’s ID",
    'Senior Citizen ID',
    'Philhealth ID',
    'TIN Card',
    'Postal ID',
    'NBI Clearance',
    'Police Clearance',
    'Cedula',
  ];
  @override
  void dispose() {
    _fullnameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Column idDetails(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ID Details',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        DropdownMenu(
            hintText: 'Select Type Of ID',
            leadingIcon: const Icon(Icons.credit_card),
            width: MediaQuery.of(context).size.width / 1.5,
            menuHeight: 250,
            enableFilter: true,
            controller: _idTypeController,
            onSelected: (value) {
              // onCategorySelected(value);
              setState(() {
                personalIdType = value.toString();
              });
              print(personalIdType);
            },
            dropdownMenuEntries:
                idTypes.map<DropdownMenuEntry<String>>((category) {
              return DropdownMenuEntry(
                value: category,
                label: category,
              );
            }).toList()),
        SizedBox(
          height: 10,
        ),
        TextFormField(
          controller: _idNumberController,
          decoration: InputDecoration(
              labelText: 'ID Number',
              border:
                  const OutlineInputBorder(borderSide: BorderSide(width: 1.0))),
        ),
      ],
    );
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
            mainAxisAlignment: MainAxisAlignment.start,
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
              idDetails(context),
              const SizedBox(
                height: 10,
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Credential Details',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                child: TextFormField(
                  controller: _emailController,
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
              const SizedBox(
                height: 20,
              ),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      fixedSize: const Size(double.maxFinite, 40)),
                  onPressed: () async {
                    setState(() {
                      loading = true;
                    });
                    try {
                      await FirebaseAuth.instance
                          .createUserWithEmailAndPassword(
                        email: _emailController.text,
                        password: _passwordController.text,
                      )
                          .then((value) {
                        FirebaseFirestoreService.instance.addUserDetails(
                            uid: value.user!.uid,
                            idType: personalIdType,
                            idNumber: _idNumberController.text,
                            email: _emailController.text);
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
                      });
                      setState(() {
                        loading = false;
                      });
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
                      ? SizedBox(
                          height: 25,
                          width: 25,
                          child: CircularProgressIndicator(
                            color: Theme.of(context).primaryColor,
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
