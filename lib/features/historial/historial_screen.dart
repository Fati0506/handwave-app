import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../auth/auth_provider.dart';

class HistorialScreen extends StatelessWidget {
  const HistorialScreen({super.key});

  String _formatFecha(Timestamp? ts) {
    if (ts == null) return '';
    final d = ts.toDate();
    final meses = [
      '', 'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
    ];
    return '${d.day} ${meses[d.month]} · ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _eliminar(
      BuildContext context, String uid, String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('¿Eliminar sesión?',
            style:
                TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        content: const Text(
            'Esta acción no se puede deshacer.',
            style: TextStyle(fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: HandWaveTheme.danger),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .collection('historial')
          .doc(docId)
          .delete();
    }
  }

  void _verDetalle(BuildContext context, Map data) {
    final mensajes =
        List<Map>.from(data['mensajes'] ?? []);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (_, ctrl) => Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: HandWaveTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(data['titulo'] ?? 'Sesión',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                        Text(data['resumen'] ?? '',
                            style: const TextStyle(
                                fontSize: 12,
                                color:
                                    HandWaveTheme.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 0.5),
            Expanded(
              child: mensajes.isEmpty
                  ? const Center(
                      child: Text('Sin mensajes guardados.',
                          style: TextStyle(
                              color:
                                  HandWaveTheme.textSecondary)))
                  : ListView.builder(
                      controller: ctrl,
                      padding: const EdgeInsets.all(16),
                      itemCount: mensajes.length,
                      itemBuilder: (_, i) {
                        final m = mensajes[i];
                        final isTercero =
                            m['tipo'] == 'tercero';
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            margin:
                                const EdgeInsets.only(bottom: 10),
                            constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context)
                                        .size
                                        .width *
                                    0.8),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isTercero
                                      ? 'Vendedor'
                                      : 'Tú',
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: HandWaveTheme
                                          .textSecondary),
                                ),
                                const SizedBox(height: 3),
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 9),
                                  decoration: BoxDecoration(
                                    color: isTercero
                                        ? const Color(0xFFF1F5F9)
                                        : HandWaveTheme.tealLight,
                                    borderRadius: const BorderRadius.only(
                                      topLeft:
                                          Radius.circular(4),
                                      topRight:
                                          Radius.circular(12),
                                      bottomLeft:
                                          Radius.circular(12),
                                      bottomRight:
                                          Radius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    m['texto'] ?? '',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isTercero
                                          ? HandWaveTheme
                                              .textPrimary
                                          : HandWaveTheme.teal,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthProvider>().user?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
        leading: const BackButton(),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .doc(uid)
            .collection('historial')
            .orderBy('fecha', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: HandWaveTheme.purpleLight,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(Icons.history_rounded,
                        color: HandWaveTheme.purple, size: 38),
                  ),
                  const SizedBox(height: 20),
                  const Text('Sin historial aún',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: HandWaveTheme.textPrimary)),
                  const SizedBox(height: 8),
                  const Text(
                    'Las sesiones del Modo bolsillo\nse guardarán aquí.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13,
                        color: HandWaveTheme.textSecondary,
                        height: 1.5),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final doc = docs[i];
              final data = doc.data() as Map;
              final fecha = data['fecha'] as Timestamp?;

              return Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _verDetalle(context, data),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: HandWaveTheme.purpleLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.history_rounded,
                              color: HandWaveTheme.purple,
                              size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(data['titulo'] ?? 'Sesión',
                                  style: HWTextStyles.cardTitle),
                              const SizedBox(height: 3),
                              Text(
                                data['resumen'] ?? '',
                                style: HWTextStyles.cardSubtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(_formatFecha(fecha),
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: HandWaveTheme
                                          .textSecondary)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: HandWaveTheme.textSecondary,
                              size: 18),
                          onPressed: () =>
                              _eliminar(context, uid, doc.id),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}