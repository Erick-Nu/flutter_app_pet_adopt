import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../adoptions/presentation/screens/home_adopter_screen.dart';
import '../../../foundations/presentation/screens/home_foundation_screen.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'forgot_password_screen.dart';
import 'register_selector_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;

  void _onLogin() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
            AuthLoginRequested(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
            ),
          );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (!mounted) return;

          if (state is AuthError) {
            showAppSnackBar(
              context,
              message: state.message,
              type: AppSnackBarType.error,
            );
          } else if (state is AuthenticatedNoProfile) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => RegisterSelectorScreen(
                  isGoogleAuth: false,
                  googleUser: state.user,
                ),
              ),
            );
          } else if (state is AuthAuthenticated) {
            final type = state.user.type;
            if (type == 'fundacion') {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomeFoundationScreen()),
                (route) => false,
              );
            } else if (type == 'adoptante') {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomeAdopterScreen()),
                (route) => false,
              );
            } else {
              // Tipo indefinido: enviamos al selector para completar perfil
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => RegisterSelectorScreen(
                    isGoogleAuth: false,
                    googleUser: state.user,
                  ),
                ),
              );
            }
          }
        },
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            return Stack(
              children: [
                // 1. FORMULARIO (Fondo)
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    height: size.height,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Spacer(flex: 2),

                          // LOGO O ICONO
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryOrange.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.pets_rounded,
                                size: 60,
                                color: AppTheme.primaryOrange,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          Text(
                            "¡Bienvenido de nuevo!",
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Ingresa para encontrar a tu mejor amigo",
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),

                          const SizedBox(height: 48),

                          // INPUTS
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: "Correo Electrónico",
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (value) =>
                                value!.isEmpty ? "Ingresa tu correo" : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            decoration: InputDecoration(
                              labelText: "Contraseña",
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(_isPasswordVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility),
                                onPressed: () =>
                                    setState(() => _isPasswordVisible = !_isPasswordVisible),
                              ),
                            ),
                            validator: (value) =>
                                value!.length < 6 ? "Mínimo 6 caracteres" : null,
                          ),

                          // OLVIDÉ CONTRASEÑA
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ForgotPasswordScreen(),
                                ),
                              ),
                              child: const Text("¿Olvidaste tu contraseña?"),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // BOTÓN LOGIN
                          ElevatedButton(
                            onPressed: _onLogin,
                            child: const Text("INICIAR SESIÓN"),
                          ),

                          const SizedBox(height: 20),

                          // SEPARADOR
                          Row(
                            children: [
                              Expanded(child: Divider(color: Colors.grey.shade300)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Text(
                                  "O continúa con",
                                  style: TextStyle(color: Colors.grey.shade500),
                                ),
                              ),
                              Expanded(child: Divider(color: Colors.grey.shade300)),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // BOTÓN GOOGLE
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                context.read<AuthBloc>().add(LoginWithGoogleRequested());
                              },
                              icon: const Icon(Icons.g_mobiledata, color: Colors.red, size: 32),
                              label: const Text(
                                "Google",
                                style: TextStyle(fontSize: 16, color: Colors.black87),
                              ),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),

                          const Spacer(flex: 3),

                          // REGISTRO
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("¿No tienes cuenta?"),
                              TextButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const RegisterSelectorScreen(),
                                  ),
                                ),
                                child: const Text(
                                  "Regístrate aquí",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),

                // 2. LOADER GLOBAL (Encima de todo)
                if (state is AuthLoading)
                  Container(
                    color: Colors.white.withOpacity(0.8),
                    child: const Center(
                      child: AppLoader(),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}