import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/app_loader.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'login_screen.dart';
import '../../domain/entities/user_entity.dart';

class RegisterFundacionScreen extends StatefulWidget {
  final bool isGoogleAuth;
  final UserEntity? googleUser;

  const RegisterFundacionScreen({
    super.key,
    this.isGoogleAuth = false,
    this.googleUser,
  });

  @override
  State<RegisterFundacionScreen> createState() => _RegisterFundacionScreenState();
}

class _RegisterFundacionScreenState extends State<RegisterFundacionScreen> {
  final _formKey = GlobalKey<FormState>();

  // Regex para validación estricta de email
  final _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  
  // Controladores (sin dirección, se completará luego en perfil)
  final _nombreCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  
  bool _isPassVisible = false;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    if (widget.isGoogleAuth) {
      final currentUser = Supabase.instance.client.auth.currentUser;
      final metadata = currentUser?.userMetadata ?? {};
      final googleEmail = widget.googleUser?.email;

      _nombreCtrl.text = (metadata['full_name'] as String?)
              ?? (metadata['name'] as String?)
              ?? googleEmail?.split('@').first
              ?? '';
      _emailCtrl.text = googleEmail ?? currentUser?.email ?? '';
      _avatarUrl = metadata['avatar_url'] as String?;
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _onRegister() {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();

      if (widget.isGoogleAuth) {
        // REGISTRO DESDE GOOGLE
        context.read<AuthBloc>().add(
          CreateGoogleProfileFundacion({
            'nombre': _nombreCtrl.text.trim(),
            'direccion': _telefonoCtrl.text.trim(),
            'logo_url': _avatarUrl,
          }),
        );
      } else {
        // REGISTRO NORMAL
        context.read<AuthBloc>().add(
          AuthRegisterFundacionRequested(
            email: _emailCtrl.text.trim(),
            password: _passCtrl.text.trim(),
            nombre: _nombreCtrl.text.trim(),
            telefono: _telefonoCtrl.text.trim(),
          ),
        );
      }
    }
  }

  // Widget auxiliar para inputs consistentes con el tema
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
    int? maxLength,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        obscureText: obscureText,
        textCapitalization: capitalization,
        textInputAction: action,
        maxLength: maxLength,
        style: AppTheme.lightTheme.textTheme.bodyLarge,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppTheme.primaryOrange),
          suffixIcon: suffixIcon,
          counterText: '', // Ocultar el contador de caracteres
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
            showAppSnackBar(
              context,
              message: state.message,
              type: AppSnackBarType.error,
            );
          } else if (state is AuthAuthenticated) {
            if (widget.isGoogleAuth) {
              Navigator.of(context).popUntil((route) => route.isFirst);
              showAppSnackBar(
                context,
                message: "Perfil de fundación creado con Google.",
                type: AppSnackBarType.success,
              );
            } else {
              // Logout forzado para obligar verificación de correo
              context.read<AuthBloc>().add(AuthLogoutRequested());
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
              showAppSnackBar(
                context,
                message: "Fundación registrada. Revisa tu correo para activar la cuenta.",
                type: AppSnackBarType.success,
              );
            }
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
                      Icons.volunteer_activism_rounded, // Icono distintivo de fundación
                      size: 64, 
                      color: AppTheme.primaryOrange
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Registro Fundación",
                      textAlign: TextAlign.center,
                      style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Únete para gestionar adopciones y dar visibilidad a tus rescatados.",
                      textAlign: TextAlign.center,
                      style: AppTheme.lightTheme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 32),

                    // --- CAMPOS DE TEXTO ---
                    
                    _buildTextField(
                      controller: _nombreCtrl,
                      label: 'Nombre de la Fundación',
                      icon: Icons.business_rounded,
                      capitalization: TextCapitalization.words,
                      validator: (v) => (v == null || v.isEmpty) ? 'El nombre es requerido' : null,
                    ),

                    _buildTextField(
                      controller: _telefonoCtrl,
                      label: 'Teléfono de Contacto',
                      icon: Icons.phone_rounded,
                      type: TextInputType.phone,
                      maxLength: 10,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'El teléfono es requerido';
                        if (v.length != 10) return 'El teléfono debe tener exactamente 10 dígitos';
                        if (!RegExp(r'^\d+$').hasMatch(v)) return 'El teléfono solo debe contener números';
                        return null;
                      },
                    ),

                    if (!widget.isGoogleAuth)
                      _buildTextField(
                        controller: _emailCtrl,
                        label: 'Correo Institucional',
                        icon: Icons.email_outlined,
                        type: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'El correo es requerido';
                          if (!_emailRegex.hasMatch(v)) return 'Formato de correo inválido';
                          return null;
                        },
                      ),

                    if (!widget.isGoogleAuth)
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
                        // Validación de seguridad: Mínimo 8 caracteres
                        validator: (v) => (v == null || v.length < 8) ? 'Mínimo 8 caracteres' : null,
                      ),

                    const SizedBox(height: 24),

                    // --- BOTÓN REGISTRAR ---
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        if (state is AuthLoading) {
                          return const Center(child: AppLoader());
                        }
                        return ElevatedButton(
                          onPressed: _onRegister,
                          child: const Text("Registrar Fundación"),
                        );
                      },
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