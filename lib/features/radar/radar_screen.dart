import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme.dart';

class RadarScreen extends StatefulWidget {
  const RadarScreen({super.key});

  @override
  State<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends State<RadarScreen> {
  String _filtro = 'Todos';
  final List<String> _filtros = ['Todos', 'En línea', 'Cercanos'];

  // Datos de ejemplo precargados para demo (semana 4 → Google Maps real)
  final List<Map<String, dynamic>> _ejemplos = [
    {
      'nombre': 'Tienda Ripley — Centro',
      'direccion': 'Av. Abancay 123, Lima',
      'distancia': 120,
      'estado': 'online',
      'kioscoId': 'HW-001',
    },
    {
      'nombre': 'Farmacia Inkafarma',
      'direccion': 'Jr. de la Unión 450',
      'distancia': 340,
      'estado': 'ocupado',
      'kioscoId': 'HW-002',
    },
    {
      'nombre': 'Wong Supermercado',
      'direccion': 'Av. Larco 890, Miraflores',
      'distancia': 650,
      'estado': 'online',
      'kioscoId': 'HW-003',
    },
    {
      'nombre': 'Saga Falabella',
      'direccion': 'Jockey Plaza, Surco',
      'distancia': 1200,
      'estado': 'offline',
      'kioscoId': 'HW-004',
    },
  ];

  List<Map<String, dynamic>> get _filtrados {
    switch (_filtro) {
      case 'En línea':
        return _ejemplos.where((e) => e['estado'] == 'online').toList();
      case 'Cercanos':
        final copia = [..._ejemplos];
        copia.sort((a, b) =>
            (a['distancia'] as int).compareTo(b['distancia'] as int));
        return copia.take(3).toList();
      default:
        return _ejemplos;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Radar inclusivo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => setState(() {}),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Mapa placeholder ────────────────────────────────────────
          Container(
            height: 200,
            width: double.infinity,
            color: const Color(0xFFD4E8F5),
            child: Stack(
              children: [
                // Mapa simulado
                CustomPaint(
                  size: const Size(double.infinity, 200),
                  painter: _MapPainter(),
                ),
                // Pins
                ..._filtrados.map((local) {
                  final isOnline = local['estado'] == 'online';
                  final dist = local['distancia'] as int;
                  // Posiciones simuladas basadas en distancia
                  final left = 60.0 + (dist % 200).toDouble();
                  final top = 50.0 + (dist % 80).toDouble();
                  return Positioned(
                    left: left, top: top,
                    child: _MapPinWidget(online: isOnline),
                  );
                }),
                // Banner Google Maps
                Positioned(
                  bottom: 12, left: 0, right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.map_outlined,
                              size: 13, color: HandWaveTheme.navy),
                          SizedBox(width: 5),
                          Text(
                            'Google Maps en semana 4',
                            style: TextStyle(
                                fontSize: 11,
                                color: HandWaveTheme.navy,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Filtros ─────────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _filtros.map((f) {
                        final active = _filtro == f;
                        return GestureDetector(
                          onTap: () => setState(() => _filtro = f),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: active
                                  ? HandWaveTheme.navy
                                  : HandWaveTheme.surface,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              f,
                              style: TextStyle(
                                fontSize: 12,
                                color: active
                                    ? Colors.white
                                    : HandWaveTheme.textSecondary,
                                fontWeight: active
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                Text(
                  '${_filtrados.length} locales',
                  style: const TextStyle(
                      fontSize: 11,
                      color: HandWaveTheme.textSecondary),
                ),
              ],
            ),
          ),

          // ── Lista de locales ─────────────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('kioscos')
                  .snapshots(),
              builder: (_, snap) {
                // Combinar datos reales con ejemplos
                List<Map<String, dynamic>> todos = [..._filtrados];
                if (snap.hasData && snap.data!.docs.isNotEmpty) {
                  for (final doc in snap.data!.docs) {
                    final d = doc.data() as Map<String, dynamic>;
                    d['kioscoId'] = doc.id;
                    todos.insert(0, d);
                  }
                }

                if (todos.isEmpty) {
                  return const Center(
                    child: Text('No hay locales con este filtro.',
                        style: TextStyle(
                            color: HandWaveTheme.textSecondary)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: todos.length,
                  itemBuilder: (_, i) => _LocalCard(local: todos[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LocalCard extends StatelessWidget {
  final Map<String, dynamic> local;
  const _LocalCard({required this.local});

  @override
  Widget build(BuildContext context) {
    final estado = local['estado'] ?? 'online';
    final dist = local['distancia'] as int? ?? 0;

    Color badgeBg, badgeColor;
    String badgeText;
    Color iconBg, iconColor;

    switch (estado) {
      case 'online':
        badgeBg = HandWaveTheme.greenLight;
        badgeColor = HandWaveTheme.green;
        badgeText = 'En línea';
        iconBg = HandWaveTheme.greenLight;
        iconColor = HandWaveTheme.green;
        break;
      case 'ocupado':
        badgeBg = HandWaveTheme.amberLight;
        badgeColor = HandWaveTheme.amber;
        badgeText = 'Ocupado';
        iconBg = HandWaveTheme.amberLight;
        iconColor = HandWaveTheme.amber;
        break;
      default:
        badgeBg = HandWaveTheme.surface;
        badgeColor = HandWaveTheme.textSecondary;
        badgeText = 'Offline';
        iconBg = HandWaveTheme.surface;
        iconColor = HandWaveTheme.textSecondary;
    }

    final distText = dist < 1000
        ? '${dist}m de distancia'
        : '${(dist / 1000).toStringAsFixed(1)}km';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12)),
              child:
                  Icon(Icons.storefront_rounded, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(local['nombre'] ?? 'Local HandWave',
                      style: HWTextStyles.cardTitle),
                  const SizedBox(height: 2),
                  Text(
                    local['direccion'] ?? '',
                    style: HWTextStyles.cardSubtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(distText,
                      style: const TextStyle(
                          fontSize: 10,
                          color: HandWaveTheme.textSecondary)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            HWBadge(text: badgeText, bg: badgeBg, color: badgeColor),
          ],
        ),
      ),
    );
  }
}

class _MapPinWidget extends StatelessWidget {
  final bool online;
  const _MapPinWidget({required this.online});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14, height: 14,
      decoration: BoxDecoration(
        color: online ? HandWaveTheme.green : HandWaveTheme.amber,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: (online ? HandWaveTheme.green : HandWaveTheme.amber)
                .withOpacity(0.4),
            blurRadius: 6,
          ),
        ],
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFFD4E8F5);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);

    final water = Paint()..color = const Color(0xFFB8D8EE);
    canvas.drawRect(
        Rect.fromLTWH(0, size.height * 0.6, size.width, size.height), water);

    final road = Paint()
      ..color = const Color(0xFFA8C8DC)
      ..strokeWidth = 6;
    canvas.drawLine(Offset(0, size.height * 0.55),
        Offset(size.width, size.height * 0.55), road);
    canvas.drawLine(Offset(size.width * 0.35, 0),
        Offset(size.width * 0.35, size.height * 0.9), road);
    canvas.drawLine(Offset(size.width * 0.65, 0),
        Offset(size.width * 0.65, size.height * 0.9), road);

    final block = Paint()
      ..color = const Color(0xFFB0CCDE)
      ..style = PaintingStyle.fill;

    final rects = [
      Rect.fromLTWH(
          size.width * 0.05, size.height * 0.1, 80, 30),
      Rect.fromLTWH(
          size.width * 0.42, size.height * 0.05, 60, 25),
      Rect.fromLTWH(
          size.width * 0.7, size.height * 0.15, 70, 28),
      Rect.fromLTWH(
          size.width * 0.1, size.height * 0.65, 50, 20),
      Rect.fromLTWH(
          size.width * 0.5, size.height * 0.68, 90, 18),
    ];
    for (final r in rects) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(r, const Radius.circular(3)), block);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}