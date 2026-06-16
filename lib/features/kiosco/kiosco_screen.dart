import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';
import '../../shared/services/firebase_realtime_service.dart';
import 'package:flutter_tts/flutter_tts.dart';

class KioscoScreen extends StatefulWidget {
  const KioscoScreen({super.key});

  @override
  State<KioscoScreen> createState() => _KioscoScreenState();
}

class _KioscoScreenState extends State<KioscoScreen> {
  String? _kioscoId;
  bool _conectado = false;
  bool _cargando = false;
  final _idCtrl = TextEditingController();

  StreamSubscription<GestoDetectado?>? _gestoSub;
  StreamSubscription<String>? _mensajeSub;
  StreamSubscription<String>? _estadoSub;

  GestoDetectado? _ultimoGesto;
  String _mensajeTFT = '';
  String _estadoKiosco = 'offline';
  final List<Map<String, dynamic>> _conversacionChat = [];

  final FlutterTts _flutterTts = FlutterTts();
  String _ultimoGestoHablado = '';

  @override
  void initState() {
    super.initState();
    // Configuramos la voz en español
    _flutterTts.setLanguage("es-ES");
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    _gestoSub?.cancel();
    _mensajeSub?.cancel();
    _estadoSub?.cancel();
    if (_kioscoId != null) {
      FirebaseRealtimeService.setAppConectada(_kioscoId!, false);
    }
    super.dispose();
  }

  Future<void> _conectar(String id) async {
    if (id.trim().isEmpty) return;
    setState(() => _cargando = true);
    try {
      final existe = await FirebaseRealtimeService.kioscoExiste(id.trim());
      if (!existe && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Kiosco no encontrado. Verifica el ID.')),
        );
        setState(() => _cargando = false);
        return;
      }

      await FirebaseRealtimeService.setAppConectada(id.trim(), true);

      _gestoSub = FirebaseRealtimeService.gestoStream(id.trim()).listen((g) {
        if (g == null || !mounted) return;
        setState(() {
          _ultimoGesto = g;
          if (g.esValido) {
            if (g.texto != _ultimoGestoHablado) {
              _flutterTts.speak(g.texto);
              _ultimoGestoHablado = g.texto;
            }
            _conversacionChat.insert(0, {
              'sender': 'usuario',
              'texto': g.texto,
              'hora': _hora(),
            });
            if (_conversacionChat.length > 20) _conversacionChat.removeLast();
          }
        });
        if (g.esValido) HapticFeedback.lightImpact();
      });

      _mensajeSub = FirebaseRealtimeService.mensajeTFTStream(id.trim()).listen((msg) {
        if (mounted && msg.isNotEmpty) {
          setState(() {
            _mensajeTFT = msg;
            _conversacionChat.insert(0, {
              'sender': 'vendedor',
              'texto': msg,
              'hora': _hora(),
            });
            if (_conversacionChat.length > 20) _conversacionChat.removeLast();
          });
        }
      });

      _estadoSub =
          FirebaseRealtimeService.estadoStream(id.trim()).listen((estado) {
        if (mounted) setState(() => _estadoKiosco = estado);
      });

      setState(() {
        _kioscoId = id.trim();
        _conectado = true;
        _cargando = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _cargando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de conexión: Verifica tu internet.')),
        );
      }
    }
  }

  Future<void> _desconectar() async {
    await _flutterTts.stop();
    _ultimoGestoHablado = '';
    _gestoSub?.cancel();
    _mensajeSub?.cancel();
    _estadoSub?.cancel();
    if (_kioscoId != null) {
      await FirebaseRealtimeService.setAppConectada(_kioscoId!, false);
    }
    setState(() {
      _kioscoId = null;
      _conectado = false;
      _mensajeTFT = '';
      _ultimoGesto = null;
      _conversacionChat.clear();
      _estadoKiosco = 'offline';
    });
  }

  Future<void> _enviarFrase(String frase) async {
    if (_kioscoId == null) return;
    HapticFeedback.mediumImpact();
    await FirebaseRealtimeService.enviarFrase(_kioscoId!, frase);
    if (mounted) {
      setState(() {
        _conversacionChat.insert(0, {
          'sender': 'usuario',
          'texto': frase,
          'hora': _hora(),
        });
      });

      _flutterTts.speak(frase);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enviado: "$frase"')),
      );
    }
  }

  String _hora() {
    final n = DateTime.now();
    return '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}';
  }

  void _showConectarDialog() {
    _idCtrl.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Conectar al kiosco',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            const Text(
              'Ingresa el ID del kiosco (ej: HW-001).\nEl QR automático llega en semana 5.',
              style: TextStyle(
                  fontSize: 12,
                  color: HandWaveTheme.textSecondary,
                  height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _idCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.none,
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(
                labelText: 'ID del kiosco',
                prefixIcon: Icon(Icons.qr_code_rounded, size: 20),
                hintText: 'HW-001',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _conectar(_idCtrl.text);
              },
              child: const Text('Conectar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kiosco HandWave'),
        leading: const BackButton(),
        actions: [
          if (_conectado)
            TextButton.icon(
              onPressed: _desconectar,
              icon: const Icon(Icons.link_off, color: Colors.white60, size: 18),
              label: const Text('Desconectar',
                  style: TextStyle(color: Colors.white60, fontSize: 12)),
            ),
        ],
      ),
      body: _conectado ? _buildConectado() : _buildDesconectado(),
    );
  }

  Widget _buildDesconectado() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: HandWaveTheme.blueLight,
                borderRadius: BorderRadius.circular(26),
              ),
              child: const Icon(Icons.qr_code_scanner_rounded,
                  color: HandWaveTheme.blue, size: 48),
            ),
            const SizedBox(height: 24),
            const Text('Sin kiosco conectado',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: HandWaveTheme.textPrimary)),
            const SizedBox(height: 10),
            const Text(
              'Conéctate a un kiosco HandWave para recibir los gestos detectados por el Gateway en tiempo real.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13,
                  color: HandWaveTheme.textSecondary,
                  height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _cargando ? null : _showConectarDialog,
                icon: _cargando
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.add_link_rounded, size: 20),
                label: Text(_cargando ? 'Conectando...' : 'Conectar kiosco'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConectado() {
    final frases = [
      'Pagaré con tarjeta',
      '¿Cuánto cuesta?',
      '¿Tienen otra talla?',
      'Necesito ayuda',
      'Gracias',
      'Quiero éste',
      '¿Hay descuento?',
      '¿Dónde está la caja?',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Estado
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: HandWaveTheme.greenLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: HandWaveTheme.green.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                      color: HandWaveTheme.green, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Conectado',
                          style: TextStyle(
                              color: HandWaveTheme.green,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                      Text('Kiosco: $_kioscoId · Estado: $_estadoKiosco',
                          style: const TextStyle(
                              color: HandWaveTheme.green, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Gesto en tiempo real
          const Text('GESTO DETECTADO (TIEMPO REAL)',
              style: HWTextStyles.sectionLabel),
          const SizedBox(height: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _ultimoGesto?.esValido == true
                  ? HandWaveTheme.tealLight
                  : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _ultimoGesto?.esValido == true
                    ? HandWaveTheme.teal.withOpacity(0.4)
                    : HandWaveTheme.border,
              ),
            ),
            child: _ultimoGesto == null
                ? const Row(children: [
                    Icon(Icons.sign_language_outlined,
                        color: HandWaveTheme.textSecondary, size: 22),
                    SizedBox(width: 10),
                    Text('Esperando gestos del Gateway...',
                        style: HWTextStyles.cardSubtitle),
                  ])
                : Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_ultimoGesto!.texto,
                                style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: HandWaveTheme.teal)),
                            Text('Confianza: ${_ultimoGesto!.confianzaPct}',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: HandWaveTheme.textSecondary)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _ultimoGesto!.esValido
                              ? HandWaveTheme.teal
                              : HandWaveTheme.amber,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _ultimoGesto!.esValido ? 'Válido' : 'Baja confianza',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),

          // Mensaje TFT
          const Text('RESPUESTA EN PANTALLA TFT',
              style: HWTextStyles.sectionLabel),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: HandWaveTheme.border, width: 0.8),
            ),
            child: _mensajeTFT.isEmpty
                ? const Row(children: [
                    Icon(Icons.monitor_rounded,
                        color: HandWaveTheme.textSecondary, size: 20),
                    SizedBox(width: 10),
                    Text('Sin mensaje en pantalla TFT aún.',
                        style: HWTextStyles.cardSubtitle),
                  ])
                : Text(_mensajeTFT,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: HandWaveTheme.textPrimary,
                        height: 1.4)),
          ),
          const SizedBox(height: 16),

          // Frases rápidas
          const Text('ENVIAR FRASE RÁPIDA', style: HWTextStyles.sectionLabel),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: frases
                .map((f) => GestureDetector(
                      onTap: () => _enviarFrase(f),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: HandWaveTheme.tealLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: HandWaveTheme.teal.withOpacity(0.3)),
                        ),
                        child: Text(f,
                            style: const TextStyle(
                                fontSize: 12,
                                color: HandWaveTheme.teal,
                                fontWeight: FontWeight.w500)),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),

          // Historial de gestos
          if (_conversacionChat.isNotEmpty) ...[
            const Text('CONVERSACIÓN EN VIVO (CHAT)',
                style: HWTextStyles.sectionLabel),
            const SizedBox(height: 12),
            ..._conversacionChat.take(10).map((msg) {
              // Verificamos quién envió el mensaje
              bool esUsuarioSordo = msg['sender'] == 'usuario';

              return Align(
                alignment: esUsuarioSordo ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75),
                  decoration: BoxDecoration(
                    // Verde/Teal para el sordo (Derecha), Azul para el vendedor (Izquierda)
                    color: esUsuarioSordo
                        ? HandWaveTheme.tealLight
                        : HandWaveTheme.blue,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      // Redondeamos las esquinas opuestas para dar el efecto de burbuja
                      bottomLeft: Radius.circular(esUsuarioSordo ? 16 : 0),
                      bottomRight: Radius.circular(esUsuarioSordo ? 0 : 16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: esUsuarioSordo
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Text(
                        msg['texto'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: esUsuarioSordo
                              ? HandWaveTheme.textPrimary
                              : Colors.white, // Letras blancas para el fondo azul
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        msg['hora'] as String,
                        style: TextStyle(
                          fontSize: 9,
                          color: esUsuarioSordo
                              ? HandWaveTheme.textSecondary
                              : Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
