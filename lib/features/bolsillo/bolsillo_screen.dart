import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../core/theme.dart';
import '../auth/auth_provider.dart';
import 'package:flutter_tts/flutter_tts.dart';

class BolsilloScreen extends StatefulWidget {
  const BolsilloScreen({super.key});

  @override
  State<BolsilloScreen> createState() => _BolsilloScreenState();
}

class _BolsilloScreenState extends State<BolsilloScreen>
    with TickerProviderStateMixin {
  // ── STT ──────────────────────────────────────────────────────────────────
  final SpeechToText _stt = SpeechToText();
  bool _sttDisponible = false;
  bool _escuchando = false;
  String _transcripcionViva = '';
  double _nivelSonido = 0.0;
  // TTS Y TECLADO (RESPUESTAS)
  final FlutterTts _tts = FlutterTts();
  final TextEditingController _tecladoCtrl = TextEditingController();

  // ── Conversación ──────────────────────────────────────────────────────────
  final List<_Burbuja> _burbujas = [];
  bool _guardando = false;

  // ── Animaciones ───────────────────────────────────────────────────────────
  late AnimationController _pulseCtrl;
  late AnimationController _entradaCtrl;
  late Animation<double> _pulseAnim;

  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _entradaCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _pulseAnim =
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);
    _initSTT();
  }

  Future<void> _initSTT() async {
    _sttDisponible = await _stt.initialize(
      onStatus: (status) {
        if ((status == 'done' || status == 'notListening') &&
            _escuchando) {
          _finalizarEscucha();
        }
      },
      onError: (e) {
        setState(() => _escuchando = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error de micrófono: ${e.errorMsg}'),
              backgroundColor: HandWaveTheme.danger,
            ),
          );
        }
      },
    );
    setState(() {});
  }

  Future<void> _toggleEscuchar() async {
    if (!_sttDisponible) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Micrófono no disponible en este dispositivo.'),
          backgroundColor: HandWaveTheme.amber,
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();

    if (_escuchando) {
      await _stt.stop();
      _finalizarEscucha();
    } else {
      setState(() {
        _escuchando = true;
        _transcripcionViva = '';
        _nivelSonido = 0.0;
      });

      await _stt.listen(
        onResult: (result) {
          setState(() {
            _transcripcionViva = result.recognizedWords;
          });
          // Auto-scroll al final
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollCtrl.hasClients) {
              _scrollCtrl.animateTo(
                _scrollCtrl.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        },
        onSoundLevelChange: (level) {
          setState(() {
            _nivelSonido = (level + 2.0).clamp(0.0, 10.0) / 10.0;
          });
        },
        localeId: 'es-PE',
        listenFor: const Duration(minutes: 3),
        pauseFor: const Duration(seconds: 5),
        partialResults: true,
        cancelOnError: false,
      );
    }
  }

  void _finalizarEscucha() {
    final texto = _transcripcionViva.trim();
    setState(() {
      _escuchando = false;
      _transcripcionViva = '';
      _nivelSonido = 0.0;
    });

    if (texto.isNotEmpty) {
      HapticFeedback.lightImpact();
      setState(() {
        _burbujas.add(_Burbuja(
          texto: texto,
          hora: _hora(),
          tipo: TipoBurbuja.vendedor,
        ));
      });
      _scrollAlFinal();
    }
  }

  void _agregarFraseRapida(String frase) {
    HapticFeedback.selectionClick();
    setState(() {
      _burbujas.add(_Burbuja(
        texto: frase,
        hora: _hora(),
        tipo: TipoBurbuja.usuario,
      ));
    });
    _scrollAlFinal();
  }

  void _scrollAlFinal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _guardarSesion() async {
    if (_burbujas.isEmpty) return;
    setState(() => _guardando = true);

    final uid = context.read<AuthProvider>().user?.uid;
    if (uid == null) {
      setState(() => _guardando = false);
      return;
    }

    final resumen = _burbujas
        .take(3)
        .map((b) =>
            '[${b.tipo == TipoBurbuja.vendedor ? "Vendedor" : "Yo"}] ${b.texto}')
        .join(' · ');

    try {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .collection('historial')
          .add({
        'titulo': 'Bolsillo · ${_hora()}',
        'resumen': resumen.length > 120
            ? '${resumen.substring(0, 120)}...'
            : resumen,
        'mensajes': _burbujas
            .map((b) => {
                  'texto': b.texto,
                  'tipo': b.tipo == TipoBurbuja.vendedor
                      ? 'vendedor'
                      : 'usuario',
                  'hora': b.hora,
                })
            .toList(),
        'fecha': FieldValue.serverTimestamp(),
        'tipo': 'bolsillo',
      });

      if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Sesión guardada en historial'),
              ],
            ),
            backgroundColor: HandWaveTheme.teal,
          ),
        );
        setState(() {
          _burbujas.clear();
          _guardando = false;
        });
      }
    } catch (e) {
      setState(() => _guardando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: HandWaveTheme.danger,
          ),
        );
      }
    }
  }

  Future<void> _hablarTexto(String texto) async {
    if (texto.trim().isEmpty) return;
    HapticFeedback.mediumImpact();
    
    // Configuramos voz en español
    await _tts.setLanguage("es-PE");
    await _tts.setSpeechRate(0.5); // Velocidad normal
    
    // Lo agregamos al chat como burbuja del usuario
    setState(() {
      _burbujas.add(_Burbuja(texto: texto, hora: _hora(), tipo: TipoBurbuja.usuario));
    });
    _scrollAlFinal();
    
    // El celular habla
    await _tts.speak(texto);
    _tecladoCtrl.clear();
  }

  String _hora() {
    final n = DateTime.now();
    return '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _stt.cancel();
    _pulseCtrl.dispose();
    _entradaCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── BUILD ────────────────────────────────────────────────────────────────

@override
  Widget build(BuildContext context) {
    // Detectamos si el teclado está abierto
    final tecladoAbierto = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: HandWaveTheme.surface,
      // 1. ESTO ES VITAL: Evita que el teclado rompa la pantalla bruscamente
      resizeToAvoidBottomInset: true, 
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor:
            _escuchando ? HandWaveTheme.danger : HandWaveTheme.navy,
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Text(
            _escuchando ? 'Escuchando al vendedor...' : 'Modo bolsillo',
            key: ValueKey(_escuchando),
          ),
        ),
        actions: [
          if (_burbujas.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.history_rounded),
              onPressed: () => context.go('/perfil/historial'),
              tooltip: 'Ver historial',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                showDialog(
                  context: context,
                  // Definimos 'dialogContext' para que Flutter sepa qué cerrar
                  builder: (dialogContext) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: const Text('¿Limpiar conversación?',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    content: const Text('Se borrará la sesión actual sin guardar.',
                        style: TextStyle(fontSize: 13)),
                    actions: [
                      TextButton(
                        // Usamos 'dialogContext' para cerrar SOLO el diálogo
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          setState(() => _burbujas.clear());
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: HandWaveTheme.danger),
                        child: const Text('Limpiar'),
                      ),
                    ],
                  ),
                );
              },
              tooltip: 'Limpiar',
            ),
          ],
        ],
      ),
      // 2. ENVOLVEMOS EN UN SAFE AREA Y ORDENAMOS LA COLUMNA
      body: SafeArea(
        child: Column(
          children: [
            // Ocultamos el micrófono si vas a escribir
            if (!tecladoAbierto) _buildBanner(),
            if (!tecladoAbierto) _buildMicrofono(),
            if (_transcripcionViva.isNotEmpty) _buildTranscripcionViva(),

            // La conversación se expande para llenar el espacio libre
            Expanded(
              child: Container(
                color: Colors.white,
                child: _buildConversacion(),
              ),
            ),

            // Ocultamos las frases rápidas si el teclado sube
            if (!tecladoAbierto) _buildFrasesRapidas(),
            
            // La caja de texto SIEMPRE visible
            _buildEntradaTextoLibre(),
            
            // La barra de acciones inferior se oculta para dar espacio al teclado
            if (_burbujas.isNotEmpty && !tecladoAbierto) _buildBarraAccion(),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color: _escuchando
          ? HandWaveTheme.dangerLight
          : HandWaveTheme.amberLight,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(
            _escuchando
                ? Icons.radio_button_on_rounded
                : Icons.wifi_off_rounded,
            size: 13,
            color: _escuchando
                ? HandWaveTheme.danger
                : HandWaveTheme.amber,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _escuchando
                  ? 'Grabando — el vendedor está hablando'
                  : 'Sin kiosco — usa el micrófono del teléfono',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: _escuchando
                    ? HandWaveTheme.danger
                    : HandWaveTheme.amber,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMicrofono() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          // Botón micrófono con anillo pulsante
          GestureDetector(
            onTap: _toggleEscuchar,
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) {
                final nivel = _escuchando
                    ? (_nivelSonido * 0.4 + _pulseAnim.value * 0.6)
                    : 0.0;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Anillo externo de nivel de sonido
                    if (_escuchando)
                      Container(
                        width: 96 + nivel * 28,
                        height: 96 + nivel * 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: HandWaveTheme.danger
                              .withOpacity(0.08 + nivel * 0.08),
                        ),
                      ),
                    // Anillo medio
                    if (_escuchando)
                      Container(
                        width: 88 + nivel * 14,
                        height: 88 + nivel * 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: HandWaveTheme.danger
                                .withOpacity(0.2 + nivel * 0.2),
                            width: 2,
                          ),
                        ),
                      ),
                    // Botón central
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 82,
                      height: 82,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _escuchando
                            ? HandWaveTheme.danger
                            : HandWaveTheme.navy,
                        boxShadow: [
                          BoxShadow(
                            color: (_escuchando
                                    ? HandWaveTheme.danger
                                    : HandWaveTheme.navy)
                                .withOpacity(0.3),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(
                        _escuchando
                            ? Icons.stop_rounded
                            : Icons.mic_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          // Waveform visual
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) {
              final heights = [
                5.0, 12.0, 22.0, 30.0, 18.0, 26.0, 14.0, 26.0, 18.0,
                30.0, 22.0, 12.0, 5.0
              ];
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(heights.length, (i) {
                  final h = _escuchando
                      ? heights[i] *
                          (_nivelSonido * 0.5 +
                              _pulseAnim.value * 0.5)
                      : 3.0;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 4,
                    height: h.clamp(3.0, 32.0),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: _escuchando
                          ? HandWaveTheme.danger
                          : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(height: 10),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              key: ValueKey(_escuchando),
              !_sttDisponible
                  ? 'Micrófono no disponible'
                  : _escuchando
                      ? 'Toca para detener'
                      : 'Toca el micrófono para escuchar al vendedor',
              style: TextStyle(
                fontSize: 12,
                fontWeight: _escuchando
                    ? FontWeight.w600
                    : FontWeight.normal,
                color: _escuchando
                    ? HandWaveTheme.danger
                    : HandWaveTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranscripcionViva() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HandWaveTheme.dangerLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: HandWaveTheme.danger.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: HandWaveTheme.danger,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text('Transcribiendo...',
                  style: TextStyle(
                      fontSize: 10,
                      color: HandWaveTheme.danger,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _transcripcionViva,
            style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF991B1B),
                height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildConversacion() {
    if (_burbujas.isEmpty) {
      // ─── TÉCNICA DEFINITIVA ANTI-OVERFLOW DEL TECLADO ───────────
      return CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: HandWaveTheme.surface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chat_bubble_outline_rounded,
                      color: Color(0xFFCBD5E1), size: 34),
                ),
                const SizedBox(height: 16),
                const Text('La conversación aparecerá aquí',
                    style: TextStyle(
                        color: HandWaveTheme.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                const Text(
                  'Activa el micrófono y deja hablar\nal vendedor para empezar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: HandWaveTheme.textSecondary,
                      fontSize: 13,
                      height: 1.5),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        // Leyenda
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Row(
            children: [
              const Text('CONVERSACIÓN',
                  style: HWTextStyles.sectionLabel),
              const Spacer(),
              _LeyendaDot(
                  color: HandWaveTheme.navy, label: 'Yo (frases)'),
              const SizedBox(width: 12),
              _LeyendaDot(
                  color: HandWaveTheme.danger, label: 'Vendedor (voz)'),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            itemCount: _burbujas.length,
            itemBuilder: (_, i) => _buildBurbuja(_burbujas[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildBurbuja(_Burbuja b) {
    final esVendedor = b.tipo == TipoBurbuja.vendedor;
    return Align(
      alignment:
          esVendedor ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.80),
        child: Column(
          crossAxisAlignment: esVendedor
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.end,
          children: [
            // Etiqueta
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!esVendedor) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: HandWaveTheme.blueLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('Frase',
                          style: TextStyle(
                              fontSize: 9,
                              color: HandWaveTheme.blue,
                              fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 5),
                  ],
                  Text(
                    esVendedor
                        ? 'Vendedor · ${b.hora}'
                        : 'Tú · ${b.hora}',
                    style: const TextStyle(
                        fontSize: 10,
                        color: HandWaveTheme.textSecondary),
                  ),
                  if (esVendedor) ...[
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: HandWaveTheme.dangerLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('Voz',
                          style: TextStyle(
                              fontSize: 9,
                              color: HandWaveTheme.danger,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ],
              ),
            ),
            // Burbuja
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: esVendedor
                    ? Colors.white
                    : HandWaveTheme.navy,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft:
                      Radius.circular(esVendedor ? 3 : 14),
                  bottomRight:
                      Radius.circular(esVendedor ? 14 : 3),
                ),
                border: esVendedor
                    ? Border.all(
                        color: HandWaveTheme.border, width: 0.8)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Text(
                b.texto,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: esVendedor
                      ? HandWaveTheme.textPrimary
                      : Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrasesRapidas() {
    final frases = [
      'Pagaré con tarjeta',
      '¿Cuánto cuesta?',
      '¿Tienen otra talla?',
      'Quiero éste',
      'Gracias',
      '¿Hay descuento?',
      'Necesito ayuda',
      '¿Dónde pago?',
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 7),
            child: Text('FRASES RÁPIDAS',
                style: HWTextStyles.sectionLabel),
          ),
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: frases.length,
              itemBuilder: (_, i) => GestureDetector(
                // ─── AQUÍ ESTÁ LA MAGIA ──────────────────────────────
                onTap: () async {
                  final frase = frases[i];
                  
                  // 1. Agregamos la frase a la pantalla (como ya lo hacías)
                  _agregarFraseRapida(frase); 
                  
                  // 2. Hacemos que el celular lo diga en voz alta
                  await _tts.setLanguage("es-ES"); // Acento español
                  await _tts.setSpeechRate(0.5);   // Velocidad normal para que se entienda
                  await _tts.setVolume(1.0);       // Volumen al 100%
                  await _tts.speak(frase);
                },
                // ─────────────────────────────────────────────────────
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: HandWaveTheme.blueLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color:
                            HandWaveTheme.blue.withOpacity(0.3)),
                  ),
                  child: Text(
                    frases[i],
                    style: const TextStyle(
                        fontSize: 12,
                        color: HandWaveTheme.blue,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Añade esto dentro de tus widgets en BolsilloScreen
  Widget _buildEntradaTextoLibre() {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        color: Colors.white,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tecladoCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Escribe para hablar...',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: HandWaveTheme.surface,
                ),
                onSubmitted: _hablarTexto,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                color: HandWaveTheme.blue,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.volume_up_rounded, color: Colors.white),
                onPressed: () => _hablarTexto(_tecladoCtrl.text),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarraAccion() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
            top: BorderSide(
                color: HandWaveTheme.border, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => context.go('/frases'),
              icon: const Icon(Icons.chat_bubble_outline, size: 16),
              label: const Text('Billetera'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _guardando ? null : _guardarSesion,
              icon: _guardando
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.save_rounded, size: 16),
              label: Text(
                  _guardando ? 'Guardando...' : 'Guardar sesión'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────
class _LeyendaDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LeyendaDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
                color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 10,
                color: HandWaveTheme.textSecondary)),
      ],
    );
  }
}

enum TipoBurbuja { usuario, vendedor }

class _Burbuja {
  final String texto;
  final String hora;
  final TipoBurbuja tipo;

  const _Burbuja(
      {required this.texto,
      required this.hora,
      required this.tipo});
}