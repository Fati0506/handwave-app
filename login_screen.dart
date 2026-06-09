import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import 'auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _isRegister = false;
  bool _loading = false;
  bool _obscure = true;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    String? error;
    if (_isRegister) {
      error = await auth.registerWithEmail(
          _emailCtrl.text, _passwordCtrl.text, _nameCtrl.text);
    } else {
      error = await auth.signInWithEmail(_emailCtrl.text, _passwordCtrl.text);
    }
    if (!mounted) return;
    setState(() => _loading = false);
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    } else {
      context.go('/home');
    }
  }

  void _toggle() {
    _animCtrl.reset();
    setState(() => _isRegister = !_isRegister);
    _animCtrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Fondo con gradiente diagonal azul marino
          Container(
            height: size.height * 0.52,
            decoration: const BoxDecoration(
              color: HandWaveTheme.navy,
            ),
          ),

          // Patrón decorativo de ondas (simula lenguaje de señas)
          const Positioned(
            top: 0, right: -30,
            child: Opacity(
              opacity: 0.07,
              child: Icon(Icons.sign_language_rounded,
                  size: 220, color: Colors.white),
            ),
          ),
          const Positioned(
            top: 60, left: -20,
            child: Opacity(
              opacity: 0.05,
              child: Icon(Icons.waving_hand_rounded,
                  size: 140, color: Colors.white),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // ─── Header con logo ────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 32, 28, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const HandWaveLogo(size: 52),
                        const SizedBox(height: 28),

                        // Mensaje de bienvenida
                        Text(
                          _isRegister
                              ? 'Crea tu cuenta'
                              : 'Bienvenido de vuelta',
                          style: HWTextStyles.displayLarge,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _isRegister
                              ? 'Únete a HandWave y comunícate sin barreras'
                              : 'Inicia sesión para continuar',
                          style: HWTextStyles.subheading,
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),

                  // ─── Formulario flotante ────────────────────────────
                  Container(
                    width: double.infinity,
                    constraints: BoxConstraints(
                        minHeight: size.height * 0.55),
                    decoration: const BoxDecoration(
                      color: HandWaveTheme.surface,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Chips de login / registro
                            Container(
                              decoration: BoxDecoration(
                                color: HandWaveTheme.border,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.all(3),
                              child: Row(
                                children: [
                                  _TabChip(
                                    label: 'Iniciar sesión',
                                    active: !_isRegister,
                                    onTap: () {
                                      if (_isRegister) _toggle();
                                    },
                                  ),
                                  _TabChip(
                                    label: 'Registrarme',
                                    active: _isRegister,
                                    onTap: () {
                                      if (!_isRegister) _toggle();
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            if (_isRegister) ...[
                              TextFormField(
                                controller: _nameCtrl,
                                textCapitalization:
                                    TextCapitalization.words,
                                decoration: const InputDecoration(
                                  labelText: 'Nombre completo',
                                  prefixIcon:
                                      Icon(Icons.person_outline, size: 20),
                                ),
                                validator: (v) =>
                                    v!.isEmpty ? 'Ingresa tu nombre' : null,
                              ),
                              const SizedBox(height: 12),
                            ],

                            TextFormField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Correo electrónico',
                                prefixIcon:
                                    Icon(Icons.email_outlined, size: 20),
                              ),
                              validator: (v) =>
                                  v!.isEmpty ? 'Ingresa tu correo' : null,
                            ),
                            const SizedBox(height: 12),

                            TextFormField(
                              controller: _passwordCtrl,
                              obscureText: _obscure,
                              decoration: InputDecoration(
                                labelText: 'Contraseña',
                                prefixIcon:
                                    const Icon(Icons.lock_outline, size: 20),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 20,
                                  ),
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                ),
                              ),
                              validator: (v) => v!.length < 6
                                  ? 'Mínimo 6 caracteres'
                                  : null,
                            ),
                            
                            if (!_isRegister)
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () async {
                                    // Verificamos que el usuario haya escrito su correo arriba
                                    if (_emailCtrl.text.trim().isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Escribe tu correo arriba para enviarte el enlace.')),
                                      );
                                      return;
                                    }

                                    try {
                                      // Enviamos el correo de recuperación
                                      await FirebaseAuth.instance.sendPasswordResetEmail(
                                        email: _emailCtrl.text.trim(),
                                      );
                                      // ¡Notificación en la app!
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('¡Enlace enviado! Revisa el correo en tu celular.')),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Ocurrió un error al enviar el correo.')),
                                      );
                                    }
                                  },
                                  child: const Text(
                                    '¿Olvidaste tu contraseña?',
                                    style: TextStyle(
                                      fontSize: 13, 
                                      fontWeight: FontWeight.w600,
                                    ), 
                                  ),
                                ),
                              ),

                            // Ajustamos el espacio dependiendo de si hay botón de olvido o no
                            SizedBox(height: _isRegister ? 28 : 8),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _submit,
                                child: _loading
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2),
                                      )
                                    : Text(_isRegister
                                        ? 'Crear mi cuenta'
                                        : 'Ingresar'),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Pie informativo de accesibilidad
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: HandWaveTheme.blueLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.accessibility_new,
                                      color: HandWaveTheme.blue, size: 18),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'HandWave es una herramienta de comunicación para personas con discapacidad auditiva.',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: HandWaveTheme.blue,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TabChip(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight:
                  active ? FontWeight.w600 : FontWeight.normal,
              color: active
                  ? HandWaveTheme.navy
                  : HandWaveTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}