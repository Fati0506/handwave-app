import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../core/theme.dart';
import '../../shared/services/firebase_realtime_service.dart';
import '../auth/auth_provider.dart';

// ─── Modos de la pantalla ────────────────────────────────────────────────────
enum BolsilloModo { inicio, camara, microfono }

class BolsilloScreen extends StatefulWidget {
  const BolsilloScreen({super.key});

  @override
  State<BolsilloScreen> createState() => _BolsilloScreenState();
}

class _BolsilloScreenState extends State<BolsilloScreen>
    with TickerProviderStateMixin {
  // ── Estado general
  BolsilloModo _modo = BolsilloModo.inicio;
  final List<_Mensaje> _conversacion = [];
  bool _guardando = false;

  // ── Cámara (para LSP)
  CameraController? _camCtrl;
  List<CameraDescription> _camaras = [];
  bool _camaraLista = false;
  final bool _procesandoGesto = false;
  String _gestoActual = '';
  double _confianzaActual = 0.0;
  String _fraseAcumulada = '';

  // ── STT (para voz del vendedor)
  final SpeechToText _stt = SpeechToText();
  bool _sttDisponible = false;
  bool _escuchando = false;
  String _transcripcionViva = '';

  // ── Animaciones
  late AnimationController _pulseCtrl;
  late AnimationController _fadeCtrl;

  // ── Firebase (modo kiosco opcional)
  String? _kioscoId;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _initCamara();
    _initSTT();
  }

  Future<void> _initCamara() async {
    try {
      _camaras = await availableCameras();
      if (_camaras.isEmpty) return;
      // Preferir cámara frontal para captar gestos del usuario
      final frontal = _camaras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _camaras.first,
      );
      _camCtrl = CameraController(
        frontal,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await _camCtrl!.initialize();
      if (mounted) setState(() => _camaraLista = true);
    } catch (_) {
      // Permiso denegado o cámara no disponible
    }
  }

  Future<void> _initSTT() async {
    _sttDisponible = await _stt.initialize(
      onStatus: (s) {
        if ((s == 'done' || s == 'notListening') && _escuchando) {
          _finalizarEscucha();
        }
      },
      onError: (_) => setState(() => _escuchando = false),
    );
    setState(() {});
  }

  // ── Modo cámara: captura de LSP ──────────────────────────────────────────

  void _iniciarCamara() {
    setState(() {
      _modo = BolsilloModo.camara;
      _gestoActual = '';
      _fraseAcumulada = '';
    });
    _fadeCtrl.forward(from: 0);

    // Simulación del pipeline MediaPipe → TFLite que haría el Gateway.
    // En la semana 5 cuando el Gateway publique en Firebase, aquí leemos
    // el nodo en tiempo real. Por ahora simulamos la detección.
    _simularDeteccionGestos();
  }

  void _simularDeteccionGestos() {
    // TODO semana 5: reemplazar por stream de Firebase Realtime
    // FirebaseRealtimeService.gestoStream(_kioscoId!).listen((gesto) { ... })

    // Simulación progresiva para demo:
    final gestos = [
      _GestoSim('Hola', 0.97, 1800),
      _GestoSim('¿', 0.88, 2200),
      _GestoSim('Cuánto', 0.91, 2000),
      _GestoSim('cuesta', 0.94, 2100),
      _GestoSim('?', 0.89, 1500),
    ];

    Future<void> procesar(int i) async {
      if (!mounted || i >= gestos.length || _modo != BolsilloModo.camara) return;
      await Future.delayed(Duration(milliseconds: gestos[i].delayMs));
      if (!mounted || _modo != BolsilloModo.camara) return;
      setState(() {
        _gestoActual = gestos[i].texto;
        _confianzaActual = gestos[i].confianza;
        if (gestos[i].confianza >= 0.75) {
          _fraseAcumulada =
              ('$_fraseAcumulada ${gestos[i].texto}').trim();
        }
      });
      await procesar(i + 1);
    }

    procesar(0);
  }

  void _confirmarFraseLSP() {
    if (_fraseAcumulada.trim().isEmpty) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _conversacion.add(_Mensaje(
        texto: _fraseAcumulada.trim(),
        tipo: TipoMensaje.usuario,
        hora: _horaActual(),
        origen: 'LSP',
      ));
      _fraseAcumulada = '';
      _gestoActual = '';
    });

    // Enviar a Firebase si hay kiosco conectado
    if (_kioscoId != null) {
      FirebaseRealtimeService.enviarFrase(_kioscoId!, _fraseAcumulada);
    }
  }

  void _limpiarFraseLSP() => setState(() => _fraseAcumulada = '');

  // ── Modo micrófono: STT para respuesta del vendedor ──────────────────────

  void _iniciarMicrofono() {
    setState(() => _modo = BolsilloModo.microfono);
    _fadeCtrl.forward(from: 0);
    _toggleSTT();
  }

  Future<void> _toggleSTT() async {
    HapticFeedback.mediumImpact();
    if (_escuchando) {
      await _stt.stop();
      _finalizarEscucha();
    } else {
      setState(() => _escuchando = true);
      await _stt.listen(
        onResult: (r) => setState(() => _transcripcionViva = r.recognizedWords),
        localeId: 'es-PE',
        listenFor: const Duration(minutes: 2),
        pauseFor: const Duration(seconds: 4),
      );
    }
  }

  void _finalizarEscucha() {
    if (_transcripcionViva.trim().isEmpty) {
      setState(() => _escuchando = false);
      return;
    }
    setState(() {
      _conversacion.add(_Mensaje(
        texto: _transcripcionViva.trim(),
        tipo: TipoMensaje.vendedor,
        hora: _horaActual(),
        origen: 'Voz',
      ));
      _transcripcionViva = '';
      _escuchando = false;
    });
  }

  // ── Guardado en Firebase ─────────────────────────────────────────────────

  Future<void> _guardarSesion() async {
    if (_conversacion.isEmpty) return;
    setState(() => _guardando = true);

    final uid = context.read<AuthProvider>().user?.uid;
    if (uid == null) return;

    final resumen = _conversacion
        .take(3)
        .map((m) => '[${m.origen}] ${m.texto}')
        .join(' / ');

    try {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .collection('historial')
          .add({
        'titulo': 'Modo bolsillo · ${_horaActual()}',
        'resumen': resumen.length > 100
            ? '${resumen.substring(0, 100)}...'
            : resumen,
        'mensajes': _conversacion
            .map((m) => {
                  'texto': m.texto,
                  'tipo': m.tipo == TipoMensaje.usuario ? 'usuario' : 'vendedor',
                  'origen': m.origen,
                  'hora': m.hora,
                })
            .toList(),
        'fecha': FieldValue.serverTimestamp(),
        'tipo': 'bolsillo_lsp',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ Sesión guardada en historial')),
        );
        setState(() {
          _conversacion.clear();
          _guardando = false;
          _modo = BolsilloModo.inicio;
        });
      }
    } catch (e) {
      setState(() => _guardando = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  String _horaActual() {
    final n = DateTime.now();
    return '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _camCtrl?.dispose();
    _stt.cancel();
    _pulseCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HandWaveTheme.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: _modo == BolsilloModo.microfono
            ? HandWaveTheme.danger
            : _modo == BolsilloModo.camara
                ? HandWaveTheme.teal
                : HandWaveTheme.navy,
        title: Text(_titulo),
        actions: [
          if (_conversacion.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.history_rounded),
              onPressed: () => context.go('/perfil/historial'),
              tooltip: 'Ver historial',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => setState(() {
                _conversacion.clear();
                _modo = BolsilloModo.inicio;
              }),
              tooltip: 'Limpiar',
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // ── Banner modo activo ─────────────────────────────────────
          _buildBanner(),

          // ── Área principal según modo ──────────────────────────────
          if (_modo == BolsilloModo.camara) _buildCamara(),
          if (_modo == BolsilloModo.microfono) _buildMicrofono(),
          if (_modo == BolsilloModo.inicio) _buildInicio(),

          // ── Conversación acumulada ─────────────────────────────────
          if (_conversacion.isNotEmpty) _buildConversacion(),

          // ── Botones de acción ──────────────────────────────────────
          if (_conversacion.isNotEmpty) _buildAcciones(),
        ],
      ),
    );
  }

  String get _titulo {
    switch (_modo) {
      case BolsilloModo.camara:
        return 'Cámara LSP activa';
      case BolsilloModo.microfono:
        return 'Escuchando...';
      default:
        return 'Modo bolsillo';
    }
  }

  Widget _buildBanner() {
    Color bg;
    Color fg;
    IconData icon;
    String texto;

    switch (_modo) {
      case BolsilloModo.camara:
        bg = HandWaveTheme.tealLight;
        fg = HandWaveTheme.teal;
        icon = Icons.camera_alt_rounded;
        texto = 'Haz señas frente a la cámara — se acumulan en la frase';
        break;
      case BolsilloModo.microfono:
        bg = HandWaveTheme.dangerLight;
        fg = HandWaveTheme.danger;
        icon = Icons.radio_button_on_rounded;
        texto = 'Grabando — habla el vendedor';
        break;
      default:
        bg = HandWaveTheme.amberLight;
        fg = HandWaveTheme.amber;
        icon = Icons.wifi_off_rounded;
        texto = 'Sin kiosco — usa la cámara o el micrófono';
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color: bg,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 8),
          Expanded(
            child: Text(texto,
                style: TextStyle(
                    fontSize: 11, color: fg, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  // ── Pantalla inicio: selector de modo ────────────────────────────────────
  Widget _buildInicio() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              // Modo cámara LSP
              Expanded(
                child: GestureDetector(
                  onTap: _iniciarCamara,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: HandWaveTheme.tealLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: HandWaveTheme.teal.withOpacity(0.3)),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.sign_language_rounded,
                            color: HandWaveTheme.teal, size: 42),
                        SizedBox(height: 10),
                        Text('Hacer señas',
                            style: TextStyle(
                                color: HandWaveTheme.teal,
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                        SizedBox(height: 4),
                        Text(
                          'Cámara detecta\nLSP peruano',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: HandWaveTheme.teal,
                              fontSize: 11,
                              height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Modo micrófono vendedor
              Expanded(
                child: GestureDetector(
                  onTap: _sttDisponible ? _iniciarMicrofono : null,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: HandWaveTheme.dangerLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: HandWaveTheme.danger.withOpacity(0.3)),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.record_voice_over_rounded,
                            color: HandWaveTheme.danger, size: 42),
                        SizedBox(height: 10),
                        Text('Escuchar',
                            style: TextStyle(
                                color: HandWaveTheme.danger,
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                        SizedBox(height: 4),
                        Text(
                          'STT — transcribe\nvoz del vendedor',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: HandWaveTheme.danger,
                              fontSize: 11,
                              height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Billetera de frases rápidas
          GestureDetector(
            onTap: () => context.go('/frases'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: HandWaveTheme.blueLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: HandWaveTheme.blue.withOpacity(0.25)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.chat_bubble_rounded,
                      color: HandWaveTheme.blue, size: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Billetera de frases',
                            style: TextStyle(
                                color: HandWaveTheme.blue,
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                        Text('Frases guardadas de uso rápido',
                            style: TextStyle(
                                color: HandWaveTheme.blue,
                                fontSize: 11)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: HandWaveTheme.blue),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Modo cámara LSP ──────────────────────────────────────────────────────
  Widget _buildCamara() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Preview de cámara
          SizedBox(
            height: 220,
            child: Stack(
              children: [
                if (_camaraLista && _camCtrl != null)
                  Positioned.fill(
                    child: ClipRRect(
                      child: CameraPreview(_camCtrl!),
                    ),
                  )
                else
                  Container(
                    color: Colors.black87,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_outlined,
                              color: Colors.white54, size: 40),
                          SizedBox(height: 8),
                          Text('Iniciando cámara...',
                              style: TextStyle(
                                  color: Colors.white54, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),

                // Overlay: gesto detectado en tiempo real
                if (_gestoActual.isNotEmpty)
                  Positioned(
                    top: 12, left: 12, right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Detectado: $_gestoActual',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _confianzaActual >= 0.75
                                  ? HandWaveTheme.teal
                                  : HandWaveTheme.amber,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${(_confianzaActual * 100).toInt()}%',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Botón cerrar cámara
                Positioned(
                  bottom: 12, right: 12,
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _modo = BolsilloModo.inicio;
                      _gestoActual = '';
                    }),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Frase acumulada
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.format_quote_rounded,
                        color: HandWaveTheme.teal, size: 16),
                    const SizedBox(width: 6),
                    const Text('Frase acumulada',
                        style: TextStyle(
                            color: HandWaveTheme.teal,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                    const Spacer(),
                    if (_fraseAcumulada.isNotEmpty)
                      GestureDetector(
                        onTap: _limpiarFraseLSP,
                        child: const Text('Limpiar',
                            style: TextStyle(
                                color: HandWaveTheme.textSecondary,
                                fontSize: 11)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: HandWaveTheme.tealLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: HandWaveTheme.teal.withOpacity(0.3)),
                  ),
                  child: Text(
                    _fraseAcumulada.isEmpty
                        ? 'Haz señas para construir la frase...'
                        : _fraseAcumulada,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: _fraseAcumulada.isEmpty
                          ? FontWeight.normal
                          : FontWeight.w600,
                      color: _fraseAcumulada.isEmpty
                          ? HandWaveTheme.textSecondary
                          : HandWaveTheme.teal,
                      height: 1.4,
                    ),
                  ),
                ),
                if (_fraseAcumulada.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _limpiarFraseLSP,
                          style: OutlinedButton.styleFrom(
                              foregroundColor: HandWaveTheme.teal,
                              side: const BorderSide(
                                  color: HandWaveTheme.teal)),
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Repetir'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _confirmarFraseLSP,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: HandWaveTheme.teal),
                          icon: const Icon(Icons.check_rounded,
                              size: 16),
                          label: const Text('Confirmar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Modo micrófono (STT vendedor) ─────────────────────────────────────────
  Widget _buildMicrofono() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Botón de micrófono con animación
          GestureDetector(
            onTap: _sttDisponible ? _toggleSTT : null,
            child: AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_escuchando)
                      Container(
                        width: 88 + _pulseCtrl.value * 18,
                        height: 88 + _pulseCtrl.value * 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: HandWaveTheme.danger.withOpacity(0.2),
                            width: 2,
                          ),
                        ),
                      ),
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color: _escuchando
                            ? HandWaveTheme.danger
                            : HandWaveTheme.navy,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (_escuchando
                                    ? HandWaveTheme.danger
                                    : HandWaveTheme.navy)
                                .withOpacity(0.2),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      child: Icon(
                        _escuchando ? Icons.stop_rounded : Icons.mic_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          // Waveform animado
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(11, (i) {
              final h = [4.0,10.0,18.0,24.0,14.0,22.0,12.0,24.0,16.0,10.0,4.0];
              return AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, __) => Container(
                  width: 3,
                  height: _escuchando
                      ? h[i] * (0.4 + _pulseCtrl.value * 0.6)
                      : 3.0,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: _escuchando
                        ? HandWaveTheme.danger
                        : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            _escuchando
                ? 'Toca para detener'
                : 'Toca para grabar al vendedor',
            style: TextStyle(
              fontSize: 12,
              color: _escuchando
                  ? HandWaveTheme.danger
                  : HandWaveTheme.textSecondary,
              fontWeight:
                  _escuchando ? FontWeight.w600 : FontWeight.normal,
            ),
          ),

          // Transcripción en vivo
          if (_transcripcionViva.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: HandWaveTheme.dangerLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _transcripcionViva,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF991B1B), height: 1.4),
              ),
            ),
          ],

          const SizedBox(height: 10),
          // Botón volver al inicio
          TextButton.icon(
            onPressed: () => setState(() => _modo = BolsilloModo.inicio),
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text('Volver al inicio'),
            style:
                TextButton.styleFrom(foregroundColor: HandWaveTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  // ── Conversación acumulada ────────────────────────────────────────────────
  Widget _buildConversacion() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Row(
              children: [
                Text('CONVERSACIÓN', style: HWTextStyles.sectionLabel),
                Spacer(),
                // Leyenda
                _Leyenda(color: HandWaveTheme.teal, label: 'Tú (LSP)'),
                SizedBox(width: 12),
                _Leyenda(color: HandWaveTheme.danger, label: 'Vendedor'),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _conversacion.length,
              itemBuilder: (_, i) {
                final m = _conversacion[i];
                final isUsuario = m.tipo == TipoMensaje.usuario;
                return Align(
                  alignment: isUsuario
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    constraints: BoxConstraints(
                        maxWidth:
                            MediaQuery.of(context).size.width * 0.78),
                    child: Column(
                      crossAxisAlignment: isUsuario
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isUsuario ? 'Tú · ${m.hora}' : 'Vendedor · ${m.hora}',
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: HandWaveTheme.textSecondary),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: isUsuario
                                    ? HandWaveTheme.tealLight
                                    : HandWaveTheme.dangerLight,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                m.origen,
                                style: TextStyle(
                                    fontSize: 9,
                                    color: isUsuario
                                        ? HandWaveTheme.teal
                                        : HandWaveTheme.danger,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 13, vertical: 10),
                          decoration: BoxDecoration(
                            color: isUsuario
                                ? HandWaveTheme.tealLight
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(12),
                              topRight: const Radius.circular(12),
                              bottomLeft: Radius.circular(isUsuario ? 12 : 3),
                              bottomRight: Radius.circular(isUsuario ? 3 : 12),
                            ),
                          ),
                          child: Text(
                            m.texto,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: isUsuario
                                  ? HandWaveTheme.teal
                                  : HandWaveTheme.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Barra de acciones ─────────────────────────────────────────────────────
  Widget _buildAcciones() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: HandWaveTheme.border, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => setState(() {
                _modo = BolsilloModo.inicio;
              }),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Continuar'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _guardando ? null : _guardarSesion,
              icon: _guardando
                  ? const SizedBox(
                      width: 14, height: 14,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.save_outlined, size: 16),
              label: Text(_guardando ? 'Guardando...' : 'Guardar sesión'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers internos ──────────────────────────────────────────────────────────

class _Leyenda extends StatelessWidget {
  final Color color;
  final String label;
  const _Leyenda({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: HandWaveTheme.textSecondary)),
      ],
    );
  }
}

class _GestoSim {
  final String texto;
  final double confianza;
  final int delayMs;
  _GestoSim(this.texto, this.confianza, this.delayMs);
}

enum TipoMensaje { usuario, vendedor }

class _Mensaje {
  final String texto;
  final TipoMensaje tipo;
  final String hora;
  final String origen; // 'LSP', 'Voz', 'Frase'

  _Mensaje({
    required this.texto,
    required this.tipo,
    required this.hora,
    required this.origen,
  });
}
