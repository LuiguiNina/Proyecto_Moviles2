import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:restmap/services/firebase_auth_service.dart';

class AddSupervisorPage extends StatefulWidget {
  const AddSupervisorPage({Key? key}) : super(key: key);

  @override
  _AddSupervisorPageState createState() => _AddSupervisorPageState();
}

class _AddSupervisorPageState extends State<AddSupervisorPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuthService _authService = FirebaseAuthService();
  User? currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
  }

  Future<void> _addSupervisor() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Todos los campos deben estar completos para agregar el supervisor.')),
        );
      }
      return;
    }

    try {
      User? user = await _authService.createUserWithEmailAndPassword(
        _emailController.text,
        _passwordController.text,
        {'rol': 'supervisor', 'approved': true},
      );

      if (user != null) {
        await user.sendEmailVerification();

       
        await _authService.signInWithEmailAndPassword(
          currentUser!.email!,
          "adminPassword", 
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Supervisor creado exitosamente')),
          );

          Navigator.pushReplacementNamed(context, '/adminHome');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al agregar el supervisor: $e')),
        );
      }
    }

    if (mounted) {
      _emailController.clear();
      _passwordController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Supervisor'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Correo del Supervisor'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Contraseña'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addSupervisor,
              child: const Text('Agregar Supervisor'),
            ),
          ],
        ),
      ),
    );
  }
}
