import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dashboard.dart';
import 'register.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool isAdminLogin = false;

  Future<void> loginUser() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final response = await http.post(
      Uri.parse('http://172.20.10.4/flutter_api/login.php'),
      body: {
        'email': emailController.text,
        'password': passwordController.text,
        if (isAdminLogin) 'is_admin': '1', // send only if checkbox checked
      },
    );

    setState(() => isLoading = false);

    try {
      final result = jsonDecode(response.body);

      if (result['success']) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardPage(
              role: result['role'],
              userId: result['userId'].toString(),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Login failed')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Invalid server response.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/1.png', height: 100),
                  const SizedBox(height: 20),
                  Text(
                    'Login to CIGAL CONSTRUCT',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Form(
                    key: formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value!.isEmpty ? 'Enter your email' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value!.isEmpty ? 'Enter your password' : null,
                        ),
                        const SizedBox(height: 12),
                        CheckboxListTile(
                          title: const Text("Login as Admin"),
                          value: isAdminLogin,
                          onChanged: (value) {
                            setState(() => isAdminLogin = value ?? false);
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : loginUser,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                            ),
                            child: isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text('Login'),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RegisterPage(),
                              ),
                            );
                          },
                          child: Text(
                            "Create New Account",
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
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
