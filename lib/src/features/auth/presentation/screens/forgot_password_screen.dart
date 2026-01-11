import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/app_loader.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      
      context.read<AuthBloc>().add(
        AuthRecoverPasswordRequested(_emailCtrl.text.trim()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      // 1. ELIMINADO EL APPBAR
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            showAppSnackBar(
              context,
              message: state.message,
              type: AppSnackBarType.error,
            );
          } else if (state is AuthRecoverySuccess) {
            showAppSnackBar(
              context,
              message: state.message,
              type: AppSnackBarType.success,
            );
            Navigator.of(context).pop();
          }
        },
        child: SafeArea(
          // 2. CONTENIDO CENTRADO
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Icono de candado
                    Icon(
                      Icons.lock_outline,
                      size: 80,
                      color: AppTheme.primaryOrange,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "Recuperar Contraseña",
                      textAlign: TextAlign.center,
                      style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Ingresa el correo electrónico asociado a tu cuenta y te enviaremos las instrucciones.",
                      textAlign: TextAlign.center,
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // INPUT EMAIL
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: AppTheme.lightTheme.textTheme.bodyLarge,
                      decoration: InputDecoration(
                        labelText: 'Correo Electrónico',
                        prefixIcon: Icon(Icons.email_outlined, color: AppTheme.primaryOrange),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'El correo es requerido';
                        if (!_emailRegex.hasMatch(v)) return 'Formato de correo inválido';
                        return null;
                      },
                    ),

                    const SizedBox(height: 32),

                    // BOTÓN ENVIAR
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        if (state is AuthLoading) {
                          return const Center(child: AppLoader());
                        }
                        return ElevatedButton(
                          onPressed: _onSubmit,
                          child: const Text("Enviar Instrucciones"),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 24),

                    // OPCIONAL: Botón sutil para cancelar/regresar (ya que quitamos el AppBar)
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "Cancelar",
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
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