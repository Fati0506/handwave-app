import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../auth/auth_provider.dart';
import 'package:go_router/go_router.dart';

class HistorialScreen extends StatelessWidget {
  const HistorialScreen({super.key});

  String _formatFecha(Timestamp? ts) {
    if (ts == null) return '';
    final d = ts.toDate();
    final ahora = DateTime.now();
    final diff = ahora.difference(d);
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    if (diff.inDays == 1) return 'Ayer';
    final meses = ['','ene','feb','mar','abr','may','jun',
                   'jul','ago','sep','oct','nov','dic'];
    return '${d.day} ${meses[d.month]}';
  }

  Color _tipoColor(String tipo) {
    if (tipo == 'bolsillo') return HandWaveTheme.amber;
    if (tipo == 'bolsillo_lsp') return HandWaveTheme.teal;
    return HandWaveTheme.purple;
  }

  String _tipoLabel(String tipo) {
    if (tipo == 'bolsillo') return 'Bolsillo';
    if (tipo == 'bolsillo_lsp') return 'LSP';
    return 'Kiosco';
  }

  Future<void> _eliminar(BuildContext context, String uid, String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      // 1. Nombramos el contexto del diálogo como 'dialogContext'
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('¿Eliminar sesión?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        content: const Text('Esta acción no se puede deshacer.',
            style: TextStyle(fontSize: 13, color: HandWaveTheme.textSecondary)),
        actions: [
          TextButton(
              // 2. Usamos 'dialogContext' para cerrar SOLO la ventanita
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            // 2. Igual aquí
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: HandWaveTheme.danger),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    // 3. Solo si el usuario confirmó, procedemos a borrar en la nube
    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(uid)
            .collection('historial')
            .doc(docId)
            .delete();
            
        // Opcional: Feedback visual de que se borró
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sesión eliminada correctamente')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar: $e'), backgroundColor: HandWaveTheme.danger),
          );
        }
      }
    }
  }

  void _verDetalle(BuildContext context, Map data) {
    final mensajes = List<Map>.from(data['mensajes'] ?? []);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: HandWaveTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['titulo'] ?? 'Sesión',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(data['resumen'] ?? '',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: HandWaveTheme.textSecondary),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
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
                                color: HandWaveTheme.textSecondary)))
                    : ListView.builder(
                        controller: ctrl,
                        padding: const EdgeInsets.all(16),
                        itemCount: mensajes.length,
                        itemBuilder: (_, i) {
                          final m = mensajes[i];
                          final isVendedor = m['tipo'] == 'vendedor';
                          return Align(
                            alignment: isVendedor
                                ? Alignment.centerLeft
                                : Alignment.centerRight,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width *
                                          0.78),
                              child: Column(
                                crossAxisAlignment: isVendedor
                                    ? CrossAxisAlignment.start
                                    : CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    isVendedor
                                        ? 'Vendedor · ${m['hora'] ?? ''}'
                                        : 'Tú · ${m['hora'] ?? ''}',
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color: HandWaveTheme.textSecondary),
                                  ),
                                  const SizedBox(height: 3),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 9),
                                    decoration: BoxDecoration(
                                      color: isVendedor
                                          ? HandWaveTheme.surface
                                          : HandWaveTheme.navy,
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(12),
                                        topRight: const Radius.circular(12),
                                        bottomLeft: Radius.circular(
                                            isVendedor ? 3 : 12),
                                        bottomRight: Radius.circular(
                                            isVendedor ? 12 : 3),
                                      ),
                                    ),
                                    child: Text(
                                      m['texto'] ?? '',
                                      style: TextStyle(
                                        fontSize: 13,
                                        height: 1.4,
                                        color: isVendedor
                                            ? HandWaveTheme.textPrimary
                                            : Colors.white,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthProvider>().user?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/bolsillo'),
          
        ),
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
                    width: 80,
                    height: 80,
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
                          fontWeight: FontWeight.w700,
                          color: HandWaveTheme.textPrimary)),
                  const SizedBox(height: 8),
                  const Text(
                    'Las sesiones del Modo bolsillo\ny el Kiosco se guardarán aquí.',
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
              final tipo = data['tipo'] as String? ?? 'bolsillo';
              final color = _tipoColor(tipo);
              final mensajes =
                  List<Map>.from(data['mensajes'] ?? []);

              return Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _verDetalle(context, data),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        // Ícono tipo
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.history_rounded,
                              color: color, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                        data['titulo'] ?? 'Sesión',
                                        style: HWTextStyles.cardTitle),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.12),
                                      borderRadius:
                                          BorderRadius.circular(20),
                                    ),
                                    child: Text(_tipoLabel(tipo),
                                        style: TextStyle(
                                            fontSize: 9,
                                            color: color,
                                            fontWeight:
                                                FontWeight.w600)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                data['resumen'] ?? '',
                                style: HWTextStyles.cardSubtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.access_time_rounded,
                                      size: 11,
                                      color: HandWaveTheme.textSecondary),
                                  const SizedBox(width: 3),
                                  Text(_formatFecha(fecha),
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color:
                                              HandWaveTheme.textSecondary)),
                                  const SizedBox(width: 10),
                                  Icon(Icons.chat_bubble_outline_rounded,
                                      size: 11,
                                      color: HandWaveTheme.textSecondary),
                                  const SizedBox(width: 3),
                                  Text('${mensajes.length} mensajes',
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color:
                                              HandWaveTheme.textSecondary)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTapDown: (_) {}, // Bloquea el toque hacia la tarjeta
                          child: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                                color: HandWaveTheme.danger, size: 20),
                            onPressed: () => _eliminar(context, uid, doc.id),
                          ),
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