import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme.dart';

class RadarScreen extends StatelessWidget {
  const RadarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Radar inclusivo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Placeholder del mapa (semana 4 se integra Google Maps)
          Container(
            height: 220,
            width: double.infinity,
            color: const Color(0xFFD4E8F5),
            child: Stack(
              children: [
                // Fondo tipo mapa simple
                CustomPaint(
                  size: const Size(double.infinity, 220),
                  painter: _SimpleMapPainter(),
                ),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.map, size: 14, color: HandWaveTheme.navy),
                        SizedBox(width: 6),
                        Text(
                          'Google Maps se integra en semana 4',
                          style: TextStyle(
                              fontSize: 11, color: HandWaveTheme.navy),
                        ),
                      ],
                    ),
                  ),
                ),
                // Pins simulados
                Positioned(
                  top: 80, left: 120,
                  child: _MapPin(active: true),
                ),
                Positioned(
                  top: 110, left: 200,
                  child: _MapPin(active: false),
                ),
                Positioned(
                  top: 60, left: 60,
                  child: _MapPin(active: true),
                ),
              ],
            ),
          ),

          // Lista de locales
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('kioscos')
                  .snapshots(),
              builder: (context, snap) {
                // Mientras no hay datos reales, mostramos ejemplos
                final locales = snap.hasData && snap.data!.docs.isNotEmpty
                    ? snap.data!.docs
                    : null;

                final ejemplos = [
                  {
                    'nombre': 'Tienda Ripley — Centro',
                    'distancia': '120m',
                    'estado': 'online',
                  },
                  {
                    'nombre': 'Farmacia Inkafarma',
                    'distancia': '340m',
                    'estado': 'ocupado',
                  },
                  {
                    'nombre': 'Wong Supermercado',
                    'distancia': '650m',
                    'estado': 'online',
                  },
                ];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text('CERCANOS A TI',
                          style: HWTextStyles.sectionLabel),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: locales?.length ?? ejemplos.length,
                        itemBuilder: (_, i) {
                          final Map data = locales != null
                              ? (locales[i].data() as Map)
                              : ejemplos[i];
                          final estado = data['estado'] ?? 'online';
                          return _LocalCard(
                            nombre: data['nombre'] ?? 'Local HandWave',
                            distancia: data['distancia'] ?? '--',
                            estado: estado,
                          );
                        },
                      ),
                    ),
                  ],
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
  final String nombre;
  final String distancia;
  final String estado;

  const _LocalCard(
      {required this.nombre,
      required this.distancia,
      required this.estado});

  @override
  Widget build(BuildContext context) {
    final isOnline = estado == 'online';
    final isOcupado = estado == 'ocupado';

    Color badgeBg = isOnline
        ? const Color(0xFFEAF3DE)
        : isOcupado
            ? HandWaveTheme.amberLight
            : const Color(0xFFF3F4F6);
    Color badgeColor = isOnline
        ? const Color(0xFF3B6D11)
        : isOcupado
            ? HandWaveTheme.amber
            : const Color(0xFF6B7280);
    String badgeText = isOnline
        ? 'En línea'
        : isOcupado
            ? 'Ocupado'
            : 'Offline';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isOnline
                    ? const Color(0xFFEAF3DE)
                    : HandWaveTheme.amberLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.storefront_outlined,
                color:
                    isOnline ? const Color(0xFF3B6D11) : HandWaveTheme.amber,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nombre, style: HWTextStyles.cardTitle),
                  const SizedBox(height: 2),
                  Text('$distancia · $badgeText',
                      style: HWTextStyles.cardSubtitle),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(badgeText,
                  style: TextStyle(
                      fontSize: 10,
                      color: badgeColor,
                      fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  final bool active;
  const _MapPin({required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: active ? HandWaveTheme.navy : HandWaveTheme.amber,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }
}

class _SimpleMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFC8DFF0)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.5, size.width, size.height * 0.5), paint);

    final streetPaint = Paint()
      ..color = const Color(0xFFA0C4DC)
      ..strokeWidth = 2;
    canvas.drawLine(Offset(0, size.height * 0.55),
        Offset(size.width, size.height * 0.55), streetPaint);
    canvas.drawLine(Offset(size.width * 0.4, 0),
        Offset(size.width * 0.4, size.height), streetPaint);

    final buildingPaint = Paint()
      ..color = const Color(0xFFB8D0E8)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(size.width * 0.15, size.height * 0.15, 50, 30),
            const Radius.circular(2)),
        buildingPaint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(size.width * 0.55, size.height * 0.2, 60, 25),
            const Radius.circular(2)),
        buildingPaint);
  }

  @override
  bool shouldRepaint(_) => false;
}