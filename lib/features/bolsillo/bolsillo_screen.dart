import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../core/theme.dart';

class BolsilloScreen extends StatefulWidget {
  const BolsilloScreen({super.key});

  @override
  State<BolsilloScreen> createState() => _BolsilloScreenState();
}

class _BolsilloScreenState extends State<BolsilloScreen>
    with TickerProviderStateMixin {
  final SpeechToText _speech = SpeechToText();
  bool _available = false;
  bool _listening = false;
  String _lastWords = '';

  final List<Map<String, String>> _historial = [];
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (_lastWords.isNotEmpty) {
            setState(() {
              _historial.add({
                'texto': _lastWords,
                'tipo': 'tercero',
                'hora': _horaActual(),
              });
              _lastWords = '';
            });
          }
          setState(() => _listening = false);
        }
      },
      onError: (error) => setState(() => _listening = false),
    );
    setState(() {});
  }

  String _horaActual() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _toggleListening() async {
    HapticFeedback.mediumImpact();
    if (_listening) {
      await _speech.stop();
      setState(() => _listening = false);
    } else {
      setState(() => _listening = true);
      await _speech.listen(
        onResult: (result) {
          setState(() => _lastWords = result.recognizedWords);
        },
        localeId: 'es_PE',
        listenFor: const Duration(minutes: 2),
        pauseFor: const Duration(seconds: 5),
      );
    }
  }

  void _guardarSesion() {
    if (_historial.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sesión guardada en Firebase')),
    );
    // TODO: guardar en Firestore
  }

  @override
  void dispose() {
    _speech.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            _listening ? HandWaveTheme.danger : HandWaveTheme.navy,
        title: Text(_listening ? 'Escuchando...' : 'Modo bolsillo'),
        actions: [
          if (_historial.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.save_outlined),
              onPressed: _guardarSesion,
              tooltip: 'Guardar sesión',
            ),
          if (_historial.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => setState(() => _historial.clear()),
              tooltip: 'Limpiar',
            ),
        ],
      ),
      body: Column(
        children: [
          // Aviso sin kiosco
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: _listening
                ? HandWaveTheme.dangerLight
                : HandWaveTheme.amberLight,
            child: Row(
              children: [
                Icon(
                  _listening
                      ? Icons.radio_button_on
                      : Icons.wifi_off_rounded,
                  size: 14,
                  color: _listening
                      ? HandWaveTheme.danger
                      : HandWaveTheme.amber,
                ),
                const SizedBox(width: 8),
                Text(
                  _listening
                      ? 'Grabando — habla el tercero'
                      : 'Sin kiosco — usando micrófono del teléfono',
                  style: TextStyle(
                    fontSize: 11,
                    color: _listening
                        ? const Color(0xFF791F1F)
                        : HandWaveTheme.amber,
                  ),
                ),
              ],
            ),
          ),

          // Botón de micrófono
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            color: Colors.white,
            child: Column(
              children: [
                GestureDetector(
                  onTap: _available ? _toggleListening : null,
                  child: AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (_, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          if (_listening)
                            Container(
                              width: 90 + _pulseCtrl.value * 14,
                              height: 90 + _pulseCtrl.value * 14,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: HandWaveTheme.danger
                                      .withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                            ),
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: _listening
                                  ? HandWaveTheme.danger
                                  : HandWaveTheme.navy,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _listening ? Icons.stop : Icons.mic,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Waveform visual
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(9, (i) {
                    final heights = [8.0, 18.0, 24.0, 14.0, 20.0, 10.0, 22.0, 16.0, 8.0];
                    return AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (_, __) {
                        final h = _listening
                            ? heights[i] * (0.5 + _pulseCtrl.value * 0.5)
                            : 4.0;
                        return Container(
                          width: 3,
                          height: h,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: _listening
                                ? HandWaveTheme.danger
                                : const Color(0xFFD1D5DB),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        );
                      },
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Text(
                  _available
                      ? (_listening
                          ? 'Toca para detener'
                          : 'Toca para escuchar al tercero')
                      : 'Micrófono no disponible',
                  style: TextStyle(
                    fontSize: 12,
                    color: _listening
                        ? HandWaveTheme.danger
                        : const Color(0xFF6B7280),
                    fontWeight: _listening
                        ? FontWeight.w500
                        : FontWeight.normal,
                  ),
                ),

                // Texto en tiempo real
                if (_lastWords.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: HandWaveTheme.dangerLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _lastWords,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF791F1F)),
                    ),
                  ),
              ],
            ),
          ),

          // Historial
          Expanded(
            child: _historial.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.chat_bubble_outline,
                            size: 36, color: Color(0xFFD1D5DB)),
                        SizedBox(height: 10),
                        Text('La transcripción aparecerá aquí',
                            style: TextStyle(
                                color: Color(0xFF9CA3AF), fontSize: 13)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _historial.length,
                    itemBuilder: (_, i) {
                      final item = _historial[i];
                      final isSistema = item['tipo'] == 'sistema';
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.82),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isSistema
                                    ? 'Sistema'
                                    : 'Tercero · ${item['hora']}',
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF9CA3AF)),
                              ),
                              const SizedBox(height: 3),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSistema
                                      ? const Color(0xFFE6F1FB)
                                      : const Color(0xFFF3F4F6),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(4),
                                    topRight: Radius.circular(12),
                                    bottomLeft: Radius.circular(12),
                                    bottomRight: Radius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  item['texto']!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isSistema
                                        ? const Color(0xFF0C447C)
                                        : const Color(0xFF111827),
                                    fontStyle: isSistema
                                        ? FontStyle.italic
                                        : FontStyle.normal,
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

          // Accesos rápidos
          if (_listening || _historial.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                    top: BorderSide(color: Color(0xFFE5E7EB), width: 0.5)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      child: const Text('Abrir billetera'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _guardarSesion,
                      child: const Text('Guardar sesión'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}