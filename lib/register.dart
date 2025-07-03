import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String selectedRole = 'user'; // Default role
  String message = '';

  Future<void> register() async {
    final url = Uri.parse('http://172.20.10.4/flutter_api/register.php');

    final response = await http.post(
      url,
      body: {
        'email': emailController.text,
        'password': passwordController.text,
        'role': selectedRole,
      },
    );

    if (response.statusCode == 200) {
      final responseBody = response.body;

      setState(() {
        if (responseBody.contains('"success":true')) {
          message = "✅ Account created successfully!";
        } else if (responseBody.contains('already registered')) {
          message = "⚠️ Email already registered.";
        } else {
          message = "❌ Registration failed.";
        }
      });
    } else {
      setState(() {
        message = "❌ Server error. Try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Account')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 12),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedRole,
              items: ['user']
                  .map((role) => DropdownMenuItem(
                        value: role,
                        child: Text(role.toUpperCase()),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedRole = value!;
                });
              },
              decoration: InputDecoration(labelText: 'Select Role'),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: register,
              child: Text('Create Account'),
            ),
            SizedBox(height: 20),
            Text(
              message,
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
