import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../auth/auth_provider.dart';

class FrasesScreen extends StatefulWidget {
  const FrasesScreen({super.key});

  @override
  State<FrasesScreen> createState() => _FrasesScreenState();
}

class _FrasesScreenState extends State<FrasesScreen> {
  final _db = FirebaseFirestore.instance;
  String? _selected;
  String _categoria = 'Frecuentes';

  // Frases por defecto si el usuario no tiene ninguna aún
  final List<Map<String, String>> _defaultFrases = [
    {'texto': 'Pagaré con tarjeta', 'categoria': 'Frecuentes'},
    {'texto': '¿Tienen otra talla?', 'categoria': 'Frecuentes'},
    {'texto': 'Necesito ayuda', 'categoria': 'Frecuentes'},
    {'texto': '¿Cuánto cuesta?', 'categoria': 'Frecuentes'},
    {'texto': 'Quiero éste', 'categoria': 'Frecuentes'},
    {'texto': 'Gracias', 'categoria': 'Frecuentes'},
    {'texto': '¿Hay descuento?', 'categoria': 'Compras'},
    {'texto': '¿Tienen factura?', 'categoria': 'Compras'},
    {'texto': 'Necesito una bolsa', 'categoria': 'Compras'},
    {'texto': '¿Dónde está la caja?', 'categoria': 'Navegación'},
    {'texto': 'Busco los probadores', 'categoria': 'Navegación'},
  ];

  CollectionReference get _frasesRef {
    final uid = context.read<AuthProvider>().user!.uid;
    return _db.collection('usuarios').doc(uid).collection('frases');
  }

  Future<void> _initFrases() async {
    final snap = await _frasesRef.limit(1).get();
    if (snap.docs.isEmpty) {
      final batch = _db.batch();
      for (final f in _defaultFrases) {
        batch.set(_frasesRef.doc(), f);
      }
      await batch.commit();
    }
  }

  @override
  void initState() {
    super.initState();
    _initFrases();
  }

  void _enviarFrase(String texto) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Enviado: "$texto"')),
    );
    // TODO semana 5: enviar via Firebase Realtime al ESP32
  }

  void _showAddDialog() {
    final ctrl = TextEditingController();
    String cat = _categoria;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Nueva frase',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Escribe la frase'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: cat,
              decoration: const InputDecoration(labelText: 'Categoría'),
              items: ['Frecuentes', 'Compras', 'Navegación', 'Emergencia']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => cat = v!,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (ctrl.text.isNotEmpty) {
                  await _frasesRef
                      .add({'texto': ctrl.text.trim(), 'categoria': cat});
                  if (mounted) Navigator.pop(context);
                }
              },
              child: const Text('Guardar frase'),
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
        title: const Text('Billetera de frases'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: StreamBuilder<QuerySnapshot>(
            stream: _frasesRef.snapshots(),
            builder: (_, snap) {
              final cats = ['Todas'];
              if (snap.hasData) {
                final found = snap.data!.docs
                    .map((d) => (d.data() as Map)['categoria'] as String? ?? '')
                    .toSet()
                    .toList()
                  ..sort();
                cats.addAll(found);
              }
              return SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: cats.map((c) {
                    final active = _categoria == c;
                    return GestureDetector(
                      onTap: () => setState(() => _categoria = c),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8, bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: active
                              ? Colors.white
                              : Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          c,
                          style: TextStyle(
                            fontSize: 12,
                            color: active
                                ? HandWaveTheme.navy
                                : Colors.white,
                            fontWeight: active
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: HandWaveTheme.navy,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _frasesRef.orderBy('categoria').snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? [];
          final filtered = _categoria == 'Todas'
              ? docs
              : docs.where((d) {
                  final data = d.data() as Map;
                  return data['categoria'] == _categoria;
                }).toList();

          if (filtered.isEmpty) {
            return const Center(
              child: Text('No hay frases en esta categoría.',
                  style: TextStyle(color: Color(0xFF9CA3AF))),
            );
          }

          return Column(
            children: [
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final data = filtered[i].data() as Map;
                    final texto = data['texto'] as String;
                    final isSelected = _selected == texto;
                    return GestureDetector(
                      onTap: () => setState(() => _selected = texto),
                      onLongPress: () async {
                        await filtered[i].reference.delete();
                        if (_selected == texto) {
                          setState(() => _selected = null);
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFE6F1FB)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? HandWaveTheme.navy
                                : const Color(0xFFE5E7EB),
                            width: isSelected ? 1.5 : 0.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        child: Text(
                          texto,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected
                                ? HandWaveTheme.navy
                                : const Color(0xFF111827),
                            fontWeight: isSelected
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Panel de envío
              if (_selected != null)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F1FB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFFB5D4F4), width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Frase seleccionada',
                          style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF185FA5),
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text('"$_selected"',
                          style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF0C447C),
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: () => _enviarFrase(_selected!),
                        icon: const Icon(Icons.send, size: 16),
                        label: const Text('Enviar al kiosco'),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}