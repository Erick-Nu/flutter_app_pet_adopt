import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart'; // Importamos el tema
import '../../../../core/services/logger_service.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/app_loader.dart';
import '../bloc/auth_bloc.dart';
import 'login_screen.dart';

final _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

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

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    _cedulaCtrl.dispose();
    _telefonoCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _onRegister() {
    if (_formKey.currentState!.validate()) {
      LoggerService.section('Registro Adoptante');
      LoggerService.auth('Intento de registro adoptante', data: {
        'nombre': _nombreCtrl.text,
        'cedula': _cedulaCtrl.text,
        'telefono': _telefonoCtrl.text,
        'email': _emailCtrl.text,
      });
      FocusScope.of(context).unfocus();

      context.read<AuthBloc>().add(
        AuthRegisterAdoptanteRequested(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim(),
          nombre: _nombreCtrl.text.trim(),
          cedula: _cedulaCtrl.text.trim(),
          telefono: _telefonoCtrl.text.trim(),
        ),
      );
      LoggerService.auth('Evento AuthRegisterAdoptanteRequested enviado');
    }
  }

  // Widget auxiliar simplificado que hereda del AppTheme
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
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        obscureText: obscureText,
        textCapitalization: capitalization,
        textInputAction: action,
        style: AppTheme.lightTheme.textTheme.bodyLarge, // Texto del input
        // La decoración base viene del AppTheme, aquí solo agregamos lo específico
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppTheme.primaryOrange), // Icono con color de marca
          suffixIcon: suffixIcon,
        ),
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            LoggerService.error('Registro adoptante falló', context: 'Auth', error: state.message);
            showAppSnackBar(
              context,
              message: state.message,
              type: AppSnackBarType.error,
            );
          } else if (state is AuthAuthenticated) {
            LoggerService.success('Registro adoptante completado', context: 'Auth');
            context.read<AuthBloc>().add(AuthLogoutRequested());
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
            showAppSnackBar(
              context,
              message: "Cuenta creada. Revisa tu correo e inicia sesión.",
              type: AppSnackBarType.success,
            );
          }
        },
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- ENCABEZADO ---
                    Icon(
                      Icons.person_add_rounded, 
                      size: 64, 
                      color: AppTheme.primaryOrange
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Registro Adoptante",
                      textAlign: TextAlign.center,
                      style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Completa tus datos para encontrar a tu compañero ideal.",
                      textAlign: TextAlign.center,
                      style: AppTheme.lightTheme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 32),

                    // --- CAMPOS DE TEXTO ---
                    
                    _buildTextField(
                      controller: _nombreCtrl,
                      label: 'Nombre Completo',
                      icon: Icons.person_outline_rounded,
                      capitalization: TextCapitalization.words,
                      validator: (v) => (v == null || v.isEmpty) ? 'El nombre es requerido' : null,
                    ),

                    _buildTextField(
                      controller: _cedulaCtrl,
                      label: 'Cédula / ID',
                      icon: Icons.badge_outlined, // Badge no tiene rounded en versions viejas, pero si existe usalo
                      type: TextInputType.number,
                      validator: (v) => (v == null || v.length < 10) ? 'Cédula inválida' : null,
                    ),

                    _buildTextField(
                      controller: _telefonoCtrl,
                      label: 'Celular',
                      icon: Icons.phone_android_rounded,
                      type: TextInputType.phone,
                      validator: (v) => (v == null || v.isEmpty) ? 'El teléfono es requerido' : null,
                    ),

                    _buildTextField(
                      controller: _emailCtrl,
                      label: 'Correo Electrónico',
                      icon: Icons.email_outlined,
                      type: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'El correo es requerido';
                        if (!_emailRegex.hasMatch(v)) return 'Formato de correo inválido';
                        return null;
                      },
                    ),

                    _buildTextField(
                      controller: _passCtrl,
                      label: 'Contraseña',
                      icon: Icons.lock_outline_rounded,
                      obscureText: !_isPassVisible,
                      action: TextInputAction.done,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPassVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                          color: AppTheme.textSecondary,
                        ),
                        onPressed: () => setState(() => _isPassVisible = !_isPassVisible),
                      ),
                      validator: (v) => (v == null || v.length < 8) ? 'Mínimo 8 caracteres' : null,
                    ),

                    const SizedBox(height: 24),

                    // --- BOTÓN REGISTRAR ---
                    SizedBox(
                      height: 56,
                      child: BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          if (state is AuthLoading) {
                            return ElevatedButton(
                              onPressed: null,
                              child: const AppLoader(size: 24, color: AppTheme.surface),
                            );
                          }
                          return ElevatedButton(
                            onPressed: _onRegister,
                            child: const Text("Crear Cuenta"),
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