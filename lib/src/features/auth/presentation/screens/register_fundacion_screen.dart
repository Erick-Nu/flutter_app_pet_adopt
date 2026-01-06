import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import 'login_screen.dart';

class RegisterFundacionScreen extends StatefulWidget {
  const RegisterFundacionScreen({super.key});

  @override
  State<RegisterFundacionScreen> createState() => _RegisterFundacionScreenState();
}

class _RegisterFundacionScreenState extends State<RegisterFundacionScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores específicos para Fundación
  final _nombreCtrl = TextEditingController(); // Nombre de la fundación
  final _direccionCtrl = TextEditingController(); // Dirección física
  final _telefonoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  
  bool _isPassVisible = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _direccionCtrl.dispose();
    _telefonoCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _onRegister() {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();

      // Disparamos el evento específico de Fundación
      context.read<AuthBloc>().add(
        AuthRegisterFundacionRequested(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim(),
          nombre: _nombreCtrl.text.trim(),
          direccion: _direccionCtrl.text.trim(),
          telefono: _telefonoCtrl.text.trim(),
        ),
      );
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType type = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    TextCapitalization capitalization = TextCapitalization.none,
    TextInputAction action = TextInputAction.next,
    int maxLines = 1,
  }) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        obscureText: obscureText,
        textCapitalization: capitalization,
        textInputAction: action,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
          ),
        ),
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red.shade400,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is AuthAuthenticated) {
            // Tras registro, forzamos logout y enviamos a Login para verificación
            context.read<AuthBloc>().add(AuthLogoutRequested());
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text("Fundación registrada. Revisa tu correo y luego inicia sesión."),
                backgroundColor: Colors.green.shade600,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    
                    // --- ENCABEZADO DIFERENTE PARA FUNDACIÓN ---
                    // Usamos un ícono que represente refugio/casa
                    Icon(Icons.pets_rounded, size: 64, color: Colors.blueAccent), 
                    const SizedBox(height: 16),
                    Text(
                      "Registro Fundación",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Únete para gestionar adopciones y ayudar a más mascotas.",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // --- CAMPOS DE TEXTO ---
                    
                    // Nombre de la Fundación
                    _buildTextField(
                      controller: _nombreCtrl,
                      label: 'Nombre de la Fundación',
                      icon: Icons.domain_rounded,
                      capitalization: TextCapitalization.words,
                      validator: (v) => (v == null || v.isEmpty) ? 'El nombre es requerido' : null,
                    ),

                    // Dirección (Campo importante para fundaciones)
                    _buildTextField(
                      controller: _direccionCtrl,
                      label: 'Dirección Física',
                      icon: Icons.location_on_outlined,
                      capitalization: TextCapitalization.sentences,
                      validator: (v) => (v == null || v.isEmpty) ? 'La dirección es requerida' : null,
                    ),

                    // Teléfono de Contacto
                    _buildTextField(
                      controller: _telefonoCtrl,
                      label: 'Teléfono de Contacto',
                      icon: Icons.phone_rounded,
                      type: TextInputType.phone,
                      validator: (v) => (v == null || v.isEmpty) ? 'El teléfono es requerido' : null,
                    ),

                    // Email
                    _buildTextField(
                      controller: _emailCtrl,
                      label: 'Correo Electrónico',
                      icon: Icons.email_outlined,
                      type: TextInputType.emailAddress,
                      validator: (v) => (v == null || !v.contains('@')) ? 'Correo inválido' : null,
                    ),

                    // Password
                    _buildTextField(
                      controller: _passCtrl,
                      label: 'Contraseña',
                      icon: Icons.lock_outline,
                      obscureText: !_isPassVisible,
                      action: TextInputAction.done,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPassVisible ? Icons.visibility : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                        onPressed: () => setState(() => _isPassVisible = !_isPassVisible),
                      ),
                      validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
                    ),

                    const SizedBox(height: 20),

                    // --- BOTÓN REGISTRAR ---
                    SizedBox(
                      height: 56,
                      child: BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          if (state is AuthLoading) {
                            return ElevatedButton(
                              onPressed: null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const SizedBox(
                                width: 24, 
                                height: 24, 
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              ),
                            );
                          }
                          return ElevatedButton(
                            onPressed: _onRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "Registrar Fundación",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}