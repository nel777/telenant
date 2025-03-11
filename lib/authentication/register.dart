import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:telenant/FirebaseServices/services.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

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
  bool _obscurePassword = true;

  List<String> idTypes = [
    'National ID',
    'Passport',
    "Driver's License",
    'SSS UMID',
    'PRC ID',
    "Voter's ID",
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
    _idTypeController.dispose();
    _idNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white,
                  Colors.blue.shade50,
                ],
              ),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button and title
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Registration Form
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ID Details Section
                          Text(
                            'ID Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // ID Type Dropdown
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                              color: Colors.grey.shade50,
                            ),
                            child: DropdownMenu<String>(
                              hintText: 'Select Type Of ID',
                              leadingIcon: Icon(Icons.credit_card,
                                  color: colorScheme.primary),
                              width: MediaQuery.of(context).size.width -
                                  88, // Accounting for padding
                              menuHeight: 250,
                              enableFilter: true,
                              controller: _idTypeController,
                              onSelected: (value) {
                                setState(() {
                                  personalIdType = value.toString();
                                });
                              },
                              textStyle: TextStyle(
                                color: Colors.grey.shade800,
                                fontSize: 16,
                              ),
                              inputDecorationTheme: InputDecorationTheme(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                              ),
                              dropdownMenuEntries: idTypes
                                  .map<DropdownMenuEntry<String>>((category) {
                                return DropdownMenuEntry(
                                  value: category,
                                  label: category,
                                );
                              }).toList(),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // ID Number Field
                          TextFormField(
                            controller: _idNumberController,
                            decoration: InputDecoration(
                              labelText: 'ID Number',
                              hintText: 'Enter your ID number',
                              prefixIcon: Icon(Icons.numbers,
                                  color: colorScheme.primary),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: colorScheme.primary, width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Credential Details Section
                          Text(
                            'Credential Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Email Field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              hintText: 'Enter your email',
                              errorText: emailAvail.isEmpty ? null : emailAvail,
                              prefixIcon: Icon(Icons.email_outlined,
                                  color: colorScheme.primary),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: colorScheme.primary, width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Password Field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              hintText: 'Enter your password',
                              errorText:
                                  passwordStr.isEmpty ? null : passwordStr,
                              helperText: 'Minimum of 6 characters',
                              helperStyle:
                                  TextStyle(color: Colors.grey.shade600),
                              prefixIcon: Icon(Icons.lock_outline,
                                  color: colorScheme.primary),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.grey.shade600,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: colorScheme.primary, width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Register Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: loading
                                  ? null
                                  : () async {
                                      // Validate inputs
                                      if (_emailController.text.isEmpty ||
                                          _passwordController.text.isEmpty ||
                                          _idNumberController.text.isEmpty ||
                                          personalIdType.isEmpty) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Please fill in all fields'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                        return;
                                      }

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
                                          FirebaseFirestoreService.instance
                                              .addUserDetails(
                                                  uid: value.user!.uid,
                                                  idType: personalIdType,
                                                  idNumber:
                                                      _idNumberController.text,
                                                  email: _emailController.text);

                                          showDialog(
                                              context: context,
                                              barrierDismissible: false,
                                              builder: ((context) {
                                                return AlertDialog(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            16),
                                                  ),
                                                  title: const Row(
                                                    children: [
                                                      Icon(Icons.check_circle,
                                                          color: Colors.green,
                                                          size: 28),
                                                      SizedBox(width: 8),
                                                      Text('Success'),
                                                    ],
                                                  ),
                                                  content: const Text(
                                                      'Your account has been created successfully.'),
                                                  actions: [
                                                    TextButton(
                                                        onPressed: () {
                                                          Navigator.of(context)
                                                              .pop();
                                                        },
                                                        child: const Text(
                                                            'Cancel')),
                                                    ElevatedButton(
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          backgroundColor:
                                                              colorScheme
                                                                  .primary,
                                                          foregroundColor:
                                                              Colors.white,
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8),
                                                          ),
                                                        ),
                                                        onPressed: () {
                                                          Navigator.of(context)
                                                              .pop();
                                                          Navigator.of(context)
                                                              .pop();
                                                        },
                                                        child: const Text(
                                                            'Go to Login'))
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
                                            passwordStr =
                                                'The password provided is too weak.';
                                          });
                                        } else if (e.code ==
                                            'email-already-in-use') {
                                          setState(() {
                                            passwordStr = '';
                                            emailAvail =
                                                'The account already exists for that email.';
                                          });
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content:
                                                  Text('Error: ${e.message}'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                        setState(() {
                                          loading = false;
                                        });
                                      } catch (e) {
                                        setState(() {
                                          loading = false;
                                        });
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text('Error: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: loading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Text(
                                      'Create Account',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Login Link
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account?',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: colorScheme.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: const Text(
                            'Login',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Background Image
                  SizedBox(
                    height: 180,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Image.asset(
                        'assets/images/login.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
