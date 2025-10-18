import 'package:flutter/material.dart';

class EditInformationPage extends StatelessWidget {
  const EditInformationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: const Center(
        child: Text(
          'This is the Edit Profile Page',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}