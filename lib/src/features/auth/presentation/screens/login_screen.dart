import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import 'register_selector_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  // Controladores
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isPasswordVisible = false;

  // Animaciones
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    // Configuración de animación de entrada (Slide Up + Fade)
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onLoginPressed() {
    // Ocultar teclado al presionar login para ver mejor el feedback
    FocusScope.of(context).unfocus();
    
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      // GestureDetector para cerrar el teclado al tocar cualquier parte vacía
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            // 1. DECORACIÓN DE FONDO (Círculo sutil esquina superior derecha)
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.primaryColor.withOpacity(0.05),
                ),
              ),
            ),
            
            // 2. BOTÓN ATRÁS FLOTANTE
            Positioned(
              top: 50,
              left: 20,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: CircleAvatar(
                  backgroundColor: Colors.grey.shade100,
                  radius: 24,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black87),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),

            // 3. CONTENIDO PRINCIPAL CON BLOC LISTENER
            BlocListener<AuthBloc, AuthState>(
              listener: (context, state) {
                if (state is AuthError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.white),
                          const SizedBox(width: 10),
                          Expanded(child: Text(state.message)),
                        ],
                      ),
                      backgroundColor: Colors.red.shade400,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                } else if (state is AuthAuthenticated) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text("¡Bienvenido de nuevo!"),
                      backgroundColor: Colors.green.shade600,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  // Navegación...
                }
              },
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 60), // Espacio para el botón de atrás
                            
                            // ICONO DE LOGO (Opcional)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Icon(Icons.pets, color: theme.primaryColor, size: 32),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // TÍTULOS
                            Text(
                              'Bienvenido\nde nuevo 👋',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: Colors.grey.shade900,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Ingresa a tu cuenta para continuar explorando.',
                              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 40),

                            // INPUT EMAIL
                            _buildLabel("Correo Electrónico"),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next, // Botón "Siguiente" en teclado
                              decoration: const InputDecoration(
                                hintText: 'ejemplo@correo.com',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'El correo es requerido';
                                if (!value.contains('@')) return 'Ingresa un correo válido';
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),

                            // INPUT PASSWORD
                            _buildLabel("Contraseña"),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              textInputAction: TextInputAction.done, // Botón "Enviar" en teclado
                              decoration: InputDecoration(
                                hintText: '********',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                                ),
                              ),
                              validator: (value) =>
                                  (value == null || value.isEmpty) ? 'La contraseña es requerida' : null,
                            ),

                            // OLVIDÉ CONTRASEÑA
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                     const SnackBar(content: Text("Próximamente: Recuperar contraseña")),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: theme.primaryColor,
                                ),
                                child: const Text(
                                  '¿Olvidaste tu contraseña?',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),

                            // BOTÓN PRINCIPAL
                            BlocBuilder<AuthBloc, AuthState>(
                              builder: (context, state) {
                                if (state is AuthLoading) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }
                                
                                return SizedBox(
                                  height: 56, // Altura táctil ideal
                                  child: FilledButton(
                                    onPressed: _onLoginPressed,
                                    style: FilledButton.styleFrom(
                                      elevation: 4,
                                      shadowColor: theme.primaryColor.withOpacity(0.4),
                                    ),
                                    child: const Text('Iniciar Sesión'),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 30),

                            // SEPARADOR SOCIAL (Visual Only)
                            Row(
                              children: [
                                Expanded(child: Divider(color: Colors.grey.shade300)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text("O continúa con", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                ),
                                Expanded(child: Divider(color: Colors.grey.shade300)),
                              ],
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // BOTONES SOCIALES (Visual placeholders)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _socialButton(Icons.g_mobiledata, Colors.red), // Google fake
                                _socialButton(Icons.apple, Colors.black), // Apple fake
                              ],
                            ),

                            const SizedBox(height: 30),

                            // FOOTER REGISTRO
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("¿No tienes cuenta? ", style: TextStyle(color: Colors.grey.shade600)),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const RegisterSelectorScreen()),
                                    );
                                  },
                                  child: Text(
                                    "Regístrate",
                                    style: TextStyle(
                                      color: theme.primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper para etiquetas de inputs
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade800,
        ),
      ),
    );
  }

  // Helper para botones sociales
  Widget _socialButton(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Icon(icon, color: color, size: 30),
    );
  }
}