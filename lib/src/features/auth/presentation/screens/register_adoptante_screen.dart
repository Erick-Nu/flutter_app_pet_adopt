import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';

class RegisterAdoptanteScreen extends StatefulWidget {
  const RegisterAdoptanteScreen({super.key});

  @override
  State<RegisterAdoptanteScreen> createState() => _RegisterAdoptanteScreenState();
}

class _RegisterAdoptanteScreenState extends State<RegisterAdoptanteScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores
  final _nombreCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _cedulaCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  
  bool _isPassVisible = false;

  void _onRegister() {
    if (_formKey.currentState!.validate()) {
      // Disparamos el evento de REGISTRO
      context.read<AuthBloc>().add(
        AuthRegisterAdoptanteRequested(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim(),
          nombre: _nombreCtrl.text.trim(),
          cedula: _cedulaCtrl.text.trim(),
          telefono: _telefonoCtrl.text.trim(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registro Adoptante")),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          } else if (state is AuthAuthenticated) {
            // Registro exitoso -> Ir al Home (o Login)
            Navigator.of(context).popUntil((route) => route.isFirst);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("¡Cuenta creada! Bienvenido.")),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Icon(Icons.person_add, size: 60, color: Colors.orange),
                const SizedBox(height: 20),
                
                // Nombre
                TextFormField(
                  controller: _nombreCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre Completo', prefixIcon: Icon(Icons.person)),
                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),

                // Cédula
                TextFormField(
                  controller: _cedulaCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Cédula / ID', prefixIcon: Icon(Icons.badge)),
                  validator: (v) => v!.length < 10 ? 'Cédula inválida' : null,
                ),
                const SizedBox(height: 16),

                // Teléfono
                TextFormField(
                  controller: _telefonoCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Celular', prefixIcon: Icon(Icons.phone)),
                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Correo Electrónico', prefixIcon: Icon(Icons.email)),
                  validator: (v) => !v!.contains('@') ? 'Correo inválido' : null,
                ),
                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passCtrl,
                  obscureText: !_isPassVisible,
                  decoration: InputDecoration(
                    labelText: 'Contraseña', 
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(_isPassVisible ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _isPassVisible = !_isPassVisible),
                    ),
                  ),
                  validator: (v) => v!.length < 6 ? 'Mínimo 6 caracteres' : null,
                ),
                const SizedBox(height: 30),

                // Botón Registrar
                SizedBox(
                  width: double.infinity,
                  child: BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      if (state is AuthLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return FilledButton(
                        onPressed: _onRegister,
                        child: const Text("Crear Cuenta"),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}