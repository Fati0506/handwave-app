import 'package:flutter/material.dart';
import '../../core/theme.dart';

class RadarScreen extends StatefulWidget {
  const RadarScreen({super.key});

  @override
  State<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends State<RadarScreen> {
  String _filtro = 'Todos';
  final List<String> _filtros = ['Todos', 'En línea', 'Cercanos'];

  // ─── Base de datos simulada (Mock) con toda la info solicitada ────────
  final List<Map<String, dynamic>> _locales = [
    {
      'nombre': 'Tienda Ripley — Centro',
      'direccion': 'Av. Abancay 123, Lima',
      'distancia': 120,
      'estado': 'online',
      'horario': 'Lunes a Domingo: 10:00 AM - 10:00 PM',
      'indicaciones': 'Frente al paradero del Metropolitano (Estación Central). Ingreso principal por la puerta 2.',
    },
    {
      'nombre': 'Farmacia Inkafarma',
      'direccion': 'Jr. de la Unión 450, Lima',
      'distancia': 340,
      'estado': 'ocupado',
      'horario': 'Lunes a Domingo: 24 horas',
      'indicaciones': 'A media cuadra de la Plaza de Armas. Local esquinero.',
    },
    {
      'nombre': 'Wong Supermercado',
      'direccion': 'Av. Larco 890, Miraflores',
      'distancia': 650,
      'estado': 'online',
      'horario': 'Lunes a Domingo: 08:00 AM - 11:00 PM',
      'indicaciones': 'Cerca al cruce con Av. Benavides. El Kiosco está en la caja de atención preferencial.',
    },
    {
      'nombre': 'Saga Falabella',
      'direccion': 'Jockey Plaza, Surco',
      'distancia': 1200,
      'estado': 'offline',
      'horario': 'Lunes a Domingo: 11:00 AM - 10:00 PM',
      'indicaciones': 'Dentro del Centro Comercial, primer nivel.',
    },
  ];

  List<Map<String, dynamic>> get _filtrados {
    switch (_filtro) {
      case 'En línea':
        return _locales.where((e) => e['estado'] == 'online').toList();
      case 'Cercanos':
        final copia = [..._locales];
        copia.sort((a, b) => (a['distancia'] as int).compareTo(b['distancia'] as int));
        return copia.take(3).toList();
      default:
        return _locales;
    }
  }

  // ─── Ventana emergente con los detalles completos del local ───────────
  void _mostrarDetallesLocal(Map<String, dynamic> local) {
    final estado = local['estado'];
    final bool isOnline = estado == 'online';
    
    Color badgeBg, badgeColor;
    String badgeText;
    if (estado == 'online') {
      badgeBg = HandWaveTheme.greenLight; badgeColor = HandWaveTheme.green; badgeText = 'Kiosco Disponible';
    } else if (estado == 'ocupado') {
      badgeBg = HandWaveTheme.amberLight; badgeColor = HandWaveTheme.amber; badgeText = 'Kiosco Ocupado';
    } else {
      badgeBg = HandWaveTheme.surface; badgeColor = HandWaveTheme.textSecondary; badgeText = 'Fuera de servicio';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle (Rayita superior)
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: HandWaveTheme.border, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 20),
            
            // Título y Estado
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(local['nombre'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: HandWaveTheme.navy)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(20)),
                  child: Text(badgeText, style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Ubicación y Distancia
            _DetalleRow(icon: Icons.location_on_rounded, title: 'Ubicación', content: local['direccion']),
            const SizedBox(height: 12),
            _DetalleRow(icon: Icons.directions_walk_rounded, title: 'Distancia', content: '${local['distancia']} metros de tu ubicación'),
            const SizedBox(height: 12),
            _DetalleRow(icon: Icons.access_time_rounded, title: 'Horario de atención', content: local['horario']),
            const SizedBox(height: 12),
            _DetalleRow(icon: Icons.info_outline_rounded, title: 'Indicaciones', content: local['indicaciones']),
            
            const SizedBox(height: 28),

            // Botón Cómo llegar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Iniciando ruta hacia ${local['nombre']}...'),
                      backgroundColor: HandWaveTheme.blue,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isOnline ? HandWaveTheme.blue : HandWaveTheme.textSecondary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: const Icon(Icons.directions_rounded, color: Colors.white),
                label: const Text('Cómo llegar', style: TextStyle(fontSize: 15)),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Radar inclusivo'),
        actions: [
          IconButton(icon: const Icon(Icons.my_location_rounded), onPressed: () {}, tooltip: 'Mi ubicación'),
        ],
      ),
      body: Column(
        children: [
          // ─── Mapa Interactivo (Simulado) ─────────────────────────────────
          Container(
            height: 220,
            width: double.infinity,
            color: const Color(0xFFD4E8F5),
            child: Stack(
              children: [
                CustomPaint(size: const Size(double.infinity, 220), painter: _MapPainter()),
                // Pines dinámicos basados en la lista filtrada
                ..._filtrados.map((local) {
                  final isOnline = local['estado'] == 'online';
                  final dist = local['distancia'] as int;
                  final left = 60.0 + (dist % 200).toDouble();
                  final top = 50.0 + (dist % 100).toDouble();
                  return Positioned(
                    left: left, top: top,
                    child: GestureDetector(
                      onTap: () => _mostrarDetallesLocal(local),
                      child: _MapPinWidget(online: isOnline),
                    ),
                  );
                }),
                // Pin del usuario
                const Positioned(
                  left: 150, top: 120,
                  child: Icon(Icons.accessibility_new_rounded, color: HandWaveTheme.blue, size: 28),
                ),
                Positioned(
                  bottom: 12, right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(10)),
                    child: const Text('Demostración Prototipo', style: TextStyle(fontSize: 10, color: HandWaveTheme.navy, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),

          // ─── Filtros ───────────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: active ? HandWaveTheme.navy : HandWaveTheme.surface,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(f, style: TextStyle(fontSize: 12, color: active ? Colors.white : HandWaveTheme.textSecondary, fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ─── Lista de locales ──────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filtrados.length,
              itemBuilder: (_, i) {
                final local = _filtrados[i];
                final estado = local['estado'];
                final isOnline = estado == 'online';
                final iconColor = isOnline ? HandWaveTheme.green : (estado == 'ocupado' ? HandWaveTheme.amber : HandWaveTheme.textSecondary);
                final iconBg = isOnline ? HandWaveTheme.greenLight : (estado == 'ocupado' ? HandWaveTheme.amberLight : HandWaveTheme.surface);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _mostrarDetallesLocal(local),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
                            child: Icon(Icons.storefront_rounded, color: iconColor, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(local['nombre'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: HandWaveTheme.navy)),
                                const SizedBox(height: 2),
                                Text(local['direccion'], style: const TextStyle(fontSize: 12, color: HandWaveTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.directions_walk_rounded, size: 12, color: iconColor),
                                    const SizedBox(width: 4),
                                    Text('${local['distancia']}m', style: TextStyle(fontSize: 11, color: iconColor, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: HandWaveTheme.textSecondary),
                        ],
                      ),
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
}

// ─── Widget reutilizable para las filas del Bottom Sheet ───────────────
class _DetalleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;

  const _DetalleRow({required this.icon, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: HandWaveTheme.blue),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: HandWaveTheme.textSecondary)),
              const SizedBox(height: 2),
              Text(content, style: const TextStyle(fontSize: 14, color: HandWaveTheme.textPrimary, height: 1.3)),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Dibujantes y utilidades visuales ──────────────────────────────────
class _MapPinWidget extends StatelessWidget {
  final bool online;
  const _MapPinWidget({required this.online});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18, height: 18,
      decoration: BoxDecoration(
        color: online ? HandWaveTheme.green : HandWaveTheme.amber,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(color: (online ? HandWaveTheme.green : HandWaveTheme.amber).withOpacity(0.4), blurRadius: 6),
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
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.65, size.width, size.height), water);

    final road = Paint()..color = const Color(0xFFA8C8DC)..strokeWidth = 8;
    canvas.drawLine(Offset(0, size.height * 0.5), Offset(size.width, size.height * 0.55), road);
    canvas.drawLine(Offset(size.width * 0.35, 0), Offset(size.width * 0.3, size.height * 0.9), road);
    canvas.drawLine(Offset(size.width * 0.7, 0), Offset(size.width * 0.75, size.height * 0.9), road);

    final block = Paint()..color = const Color(0xFFB0CCDE)..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.05, size.height * 0.1, 80, 40), const Radius.circular(4)), block);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.45, size.height * 0.1, 70, 60), const Radius.circular(4)), block);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.1, size.height * 0.7, 90, 30), const Radius.circular(4)), block);
  }

  @override
  bool shouldRepaint(_) => false;
}