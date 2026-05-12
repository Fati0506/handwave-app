import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  
  int _page = 0;

  late AnimationController _fadeCtrl;
  late AnimationController _slideCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final List<_OBPage> _pages = const [
    _OBPage(
      icon: Icons.sign_language_rounded,
      titulo: 'Bienvenido a HandWave',
      subtitulo:
          'La primera app de comunicación bidireccional para personas con discapacidad auditiva en entornos de retail peruano.',
      colorFondo: Color(0xFF1B3F72),
      colorAccent: Color(0xFF5DCAA5),
      detalle: 'Diseñada con y para la comunidad sorda del Perú.',
    ),
    _OBPage(
      icon: Icons.record_voice_over_rounded,
      titulo: 'Transcribe la voz del vendedor',
      subtitulo:
          'Activa el micrófono y HandWave convierte lo que dice el vendedor en texto en tiempo real. Sin intermediarios, sin barreras.',
      colorFondo: Color(0xFF0D7A6A),
      colorAccent: Color(0xFFFBD26A),
      detalle: 'STT optimizado para español peruano.',
    ),
    _OBPage(
      icon: Icons.chat_bubble_rounded,
      titulo: 'Tú respondes con frases rápidas',
      subtitulo:
          'Guarda tus frases más usadas y envíalas al kiosco HandWave con un solo toque. Rápido, claro y sin escribir.',
      colorFondo: Color(0xFF5B21B6),
      colorAccent: Color(0xFF93C5FD),
      detalle: '¿Pagaré con tarjeta? ¿Tienen otra talla? Con un toque.',
    ),
    _OBPage(
      icon: Icons.location_on_rounded,
      titulo: 'Encuentra locales inclusivos',
      subtitulo:
          'El Radar HandWave muestra qué tiendas y farmacias tienen el sistema activo cerca de ti, en tiempo real.',
      colorFondo: Color(0xFF14532D),
      colorAccent: Color(0xFFFBCFE8),
      detalle: 'La inclusión empieza por saber dónde ir.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _fadeAnim =
        CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
            begin: const Offset(0, 0.10), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    _animateIn();
  }

  void _animateIn() {
    _fadeCtrl.forward(from: 0);
    _slideCtrl.forward(from: 0);
  }

  @override
  void dispose() {
    
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _pages.length - 1) {
      setState(() {
        _page++;
      });
        _animateIn();
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final p = _pages[_page];

    return Scaffold(
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! < 0) {
            _next();
          } 
          else if (details.primaryVelocity! > 0) {
            if (_page > 0) {
              setState(() => _page--);
              _animateIn();
            }
          }
        },         

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        color: p.colorFondo,
        child: SafeArea(
          child: Column(
            children: [
              // ── Top: skip ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Dots
                    Row(
                      children: List.generate(_pages.length, (i) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(right: 6),
                          width: i == _page ? 24 : 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: i == _page
                                ? Colors.white
                                : Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    TextButton(
                      onPressed: _finish,
                      child: const Text('Saltar',
                          style: TextStyle(
                              color: Colors.white60, fontSize: 13)),
                    ),
                  ],
                ),
              ),

              // ── Ilustración ─────────────────────────────────────────
              Expanded(
                flex: 5,
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: _Ilustracion(page: p),
                ),
              ),

              // ── Card inferior ───────────────────────────────────────
              FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(28)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Detalle chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: p.colorFondo.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            p.detalle,
                            style: TextStyle(
                                fontSize: 11,
                                color: p.colorFondo,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                        const SizedBox(height: 14),

                        Text(p.titulo,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: p.colorFondo,
                              letterSpacing: -0.5,
                              height: 1.2,
                            )),
                        const SizedBox(height: 10),

                        Text(p.subtitulo,
                            style: const TextStyle(
                              fontSize: 14,
                              color: HandWaveTheme.textSecondary,
                              height: 1.6,
                            )),
                        const SizedBox(height: 28),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _next,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: p.colorFondo,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(14)),
                            ),
                            child: Text(
                              _page == _pages.length - 1
                                  ? '¡Empezar ahora!'
                                  : 'Siguiente',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700),
                            ),
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
    ),
    );
  }
}

// ── Modelo ─────────────────────────────────────────────────────────────────
class _OBPage {
  final IconData icon;
  final String titulo;
  final String subtitulo;
  final Color colorFondo;
  final Color colorAccent;
  final String detalle;

  const _OBPage({
    required this.icon,
    required this.titulo,
    required this.subtitulo,
    required this.colorFondo,
    required this.colorAccent,
    required this.detalle,
  });
}

// ── Ilustraciones animadas ──────────────────────────────────────────────────
class _Ilustracion extends StatefulWidget {
  final _OBPage page;
  const _Ilustracion({required this.page});

  @override
  State<_Ilustracion> createState() => _IlustracionState();
}

class _IlustracionState extends State<_Ilustracion>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.page;
    return Center(
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (_, __) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Anillo exterior pulsante
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 160 + _pulse.value * 20,
                    height: 160 + _pulse.value * 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.06),
                    ),
                  ),
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.12),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 2),
                    ),
                    child: Icon(p.icon,
                        color: Colors.white,
                        size: 64),
                  ),
                  // Chip accent animado
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Transform.translate(
                      offset: Offset(0, _pulse.value * -4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: p.colorAccent,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: p.colorAccent.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Text(
                          _chipTexto(p.icon),
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Barra de progreso de audio simulada (para STT)
              if (p.icon == Icons.record_voice_over_rounded)
                _WaveformDemo(
                    color: p.colorAccent, anim: _pulse),
            ],
          );
        },
      ),
    );
  }

  String _chipTexto(IconData icon) {
    if (icon == Icons.sign_language_rounded) return 'HandWave';
    if (icon == Icons.record_voice_over_rounded) return 'STT en vivo';
    if (icon == Icons.chat_bubble_rounded) return '1 toque';
    return 'GPS activo';
  }
}

class _WaveformDemo extends StatelessWidget {
  final Color color;
  final Animation<double> anim;
  const _WaveformDemo({required this.color, required this.anim});

  @override
  Widget build(BuildContext context) {
    final heights = [8.0, 20.0, 32.0, 18.0, 28.0, 12.0, 28.0, 20.0, 8.0];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(heights.length, (i) {
        return Container(
          width: 4,
          height: heights[i] * (0.4 + anim.value * 0.6),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: color.withOpacity(0.85),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}