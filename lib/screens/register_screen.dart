import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  String fullName = '';
  String phoneNumber = '';
  String password = '';
  String confirmPassword = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Registration', style: TextStyle(fontSize: 24)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Full Name
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  labelStyle: TextStyle(fontSize: 20),
                  border: OutlineInputBorder(),
                ),
                style: TextStyle(fontSize: 20),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter your full name' : null,
                onSaved: (value) => fullName = value!,
              ),
              SizedBox(height: 16),

              // Phone Number
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  labelStyle: TextStyle(fontSize: 20),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                style: TextStyle(fontSize: 20),
                validator: (value) => value!.isEmpty || value.length < 10
                    ? 'Enter a valid phone number'
                    : null,
                onSaved: (value) => phoneNumber = value!,
              ),
              SizedBox(height: 16),

              // Password
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(fontSize: 20),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                style: TextStyle(fontSize: 20),
                validator: (value) => value!.length < 8
                    ? 'Password must be at least 8 characters'
                    : null,
                onSaved: (value) => password = value!,
              ),
              SizedBox(height: 16),

              // Confirm Password
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  labelStyle: TextStyle(fontSize: 20),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                style: TextStyle(fontSize: 20),
                validator: (value) =>
                    value != password ? 'Passwords do not match' : null,
                onSaved: (value) => confirmPassword = value!,
              ),
              SizedBox(height: 16),

              // Optional: Upload Profile Photo
              ElevatedButton.icon(
                icon: Icon(Icons.photo, size: 28),
                label: Text(
                  'Upload Profile Photo',
                  style: TextStyle(fontSize: 22),
                ),
                onPressed: () {
                  // Future: implement image picker
                },
              ),
              SizedBox(height: 24),

              // Register Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 60),
                  textStyle: TextStyle(fontSize: 22),
                ),
                child: Text('Register'),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    // Future: save user to backend, send SMS verification
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Registration Successful')),
                    );
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
