import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../auth/auth_provider.dart';
import 'package:shimmer/shimmer.dart';

class FrasesScreen extends StatefulWidget {
  const FrasesScreen({super.key});

  @override
  State<FrasesScreen> createState() => _FrasesScreenState();
}

class _FrasesScreenState extends State<FrasesScreen> {
  final _db = FirebaseFirestore.instance;
  String? _seleccionada;
  String _categoria = 'Todas';

  final List<Map<String, String>> _defaults = [
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
    {'texto': 'Necesito un médico', 'categoria': 'Emergencia'},
    {'texto': 'Llama a seguridad', 'categoria': 'Emergencia'},
  ];

  CollectionReference _frasesRef(String uid) =>
      _db.collection('usuarios').doc(uid).collection('frases');

  Future<void> _initFrases(String uid) async {
    final snap = await _frasesRef(uid).limit(1).get();
    if (snap.docs.isEmpty) {
      final batch = _db.batch();
      for (final f in _defaults) {
        batch.set(_frasesRef(uid).doc(), f);
      }
      await batch.commit();
    }
  }

  void _enviar(String texto) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.send_rounded, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text('"$texto" enviado')),
          ],
        ),
        backgroundColor: HandWaveTheme.teal,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showAddDialog(String uid) {
    final ctrl = TextEditingController();
    String cat = 'Frecuentes';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Nueva frase',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              const Text('Se guardará en tu billetera personal.',
                  style: TextStyle(
                      fontSize: 12, color: HandWaveTheme.textSecondary)),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'Escribe la frase',
                  prefixIcon:
                      Icon(Icons.chat_bubble_outline, size: 20),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: cat,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  prefixIcon: Icon(Icons.label_outline, size: 20),
                ),
                items: ['Frecuentes', 'Compras', 'Navegación', 'Emergencia']
                    .map((c) =>
                        DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setModal(() => cat = v!),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () async {
                  if (ctrl.text.trim().isNotEmpty) {
                    await _frasesRef(uid).add({
                      'texto': ctrl.text.trim(),
                      'categoria': cat,
                    });
                    if (mounted) Navigator.pop(context);
                  }
                },
                icon: const Icon(Icons.save_rounded, size: 16),
                label: const Text('Guardar frase'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(String docId, Map<String, dynamic> data) {
    final ctrl = TextEditingController(text: data['texto']);
    String cat = data['categoria'] ?? 'Frecuentes';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Editar frase', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'Texto de la frase',
                  prefixIcon: Icon(Icons.edit_note, size: 20),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: cat,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  prefixIcon: Icon(Icons.label_outline, size: 20),
                ),
                items: ['Frecuentes', 'Compras', 'Navegación', 'Emergencia']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setModal(() => cat = v!),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () async {
                  if (ctrl.text.trim().isNotEmpty) {
                    await _db.collection('usuarios').doc(context.read<AuthProvider>().user?.uid)
                        .collection('frases').doc(docId).update({
                      'texto': ctrl.text.trim(),
                      'categoria': cat,
                    });
                    if (mounted) Navigator.pop(context);
                  }
                },
                icon: const Icon(Icons.save_rounded, size: 16),
                label: const Text('Actualizar cambios'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _catColor(String cat) {
    switch (cat) {
      case 'Frecuentes':
        return HandWaveTheme.blue;
      case 'Compras':
        return HandWaveTheme.teal;
      case 'Navegación':
        return HandWaveTheme.green;
      case 'Emergencia':
        return HandWaveTheme.danger;
      default:
        return HandWaveTheme.textSecondary;
    }
  }

  Color _catBg(String cat) {
    switch (cat) {
      case 'Frecuentes':
        return HandWaveTheme.blueLight;
      case 'Compras':
        return HandWaveTheme.tealLight;
      case 'Navegación':
        return HandWaveTheme.greenLight;
      case 'Emergencia':
        return HandWaveTheme.dangerLight;
      default:
        return HandWaveTheme.surface;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthProvider>().user?.uid ?? '';

    return FutureBuilder(
      future: _initFrases(uid),
      builder: (_, __) => Scaffold(
        backgroundColor: HandWaveTheme.surface,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Billetera de frases'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: () => _showAddDialog(uid),
              tooltip: 'Agregar frase',
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(46),
            child: StreamBuilder<QuerySnapshot>(
              stream: _frasesRef(uid).snapshots(),
              builder: (_, snap) {
                final cats = ['Todas'];
                if (snap.hasData) {
                  final found = snap.data!.docs
                      .map((d) =>
                          (d.data() as Map)['categoria'] as String? ??
                          '')
                      .toSet()
                      .toList()
                    ..sort();
                  cats.addAll(found);
                }
                return SizedBox(
                  height: 46,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    children: cats.map((c) {
                      final active = _categoria == c;
                      return GestureDetector(
                        onTap: () =>
                            setState(() {
                              _categoria = c;
                              _seleccionada = null;
                            }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 5),
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
                              fontWeight: active
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: active
                                  ? HandWaveTheme.navy
                                  : Colors.white,
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
          onPressed: () => _showAddDialog(uid),
          backgroundColor: HandWaveTheme.navy,
          child: const Icon(Icons.add, color: Colors.white),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: _frasesRef(uid).orderBy('categoria').snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.1,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: 6, // Mostramos 6 tarjetas fantasma
                  itemBuilder: (_, __) => Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              );
            }

            final docs = snap.data?.docs ?? [];
            final filtered = _categoria == 'Todas'
                ? docs
                : docs
                    .where((d) =>
                        (d.data() as Map)['categoria'] == _categoria)
                    .toList();

            if (filtered.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.chat_bubble_outline_rounded,
                        size: 42, color: Color(0xFFCBD5E1)),
                    const SizedBox(height: 12),
                    const Text('No hay frases aquí todavía.',
                        style: TextStyle(
                            color: HandWaveTheme.textSecondary,
                            fontSize: 14)),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _showAddDialog(uid),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Agregar frase'),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                // Grid de frases
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2.1,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final data =
                          filtered[i].data() as Map<String, dynamic>;
                      final texto = data['texto'] as String;
                      final cat =
                          data['categoria'] as String? ?? 'Frecuentes';
                      final isSel = _seleccionada == texto;

                      return GestureDetector(
                        onTap: () =>
                            setState(() => _seleccionada =
                                isSel ? null : texto),
                        onLongPress: () {
                          HapticFeedback.lightImpact();
                          showModalBottomSheet(
                            context: context,
                            builder: (_) => SafeArea(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.edit_rounded, color: HandWaveTheme.blue),
                                    title: const Text('Editar frase y categoría'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _showEditDialog(filtered[i].id, data);
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.delete_outline_rounded, color: HandWaveTheme.danger),
                                    title: const Text('Eliminar frase'),
                                    onTap: () async {
                                      Navigator.pop(context);
                                      await filtered[i].reference.delete();
                                      if (_seleccionada == texto) setState(() => _seleccionada = null);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          decoration: BoxDecoration(
                            color: isSel ? _catBg(cat) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSel
                                  ? _catColor(cat)
                                  : HandWaveTheme.border,
                              width: isSel ? 1.5 : 0.8,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                texto,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSel
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: isSel
                                      ? _catColor(cat)
                                      : HandWaveTheme.textPrimary,
                                  height: 1.3,
                                ),
                              ),
                              if (isSel) ...[
                                const SizedBox(height: 3),
                                Text(cat,
                                    style: TextStyle(
                                        fontSize: 9,
                                        color: _catColor(cat)
                                            .withOpacity(0.7))),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Panel envío
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  child: _seleccionada == null
                      ? const SizedBox.shrink()
                      : Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: HandWaveTheme.blueLight,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: HandWaveTheme.blue
                                    .withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                      Icons.chat_bubble_rounded,
                                      color: HandWaveTheme.blue,
                                      size: 16),
                                  const SizedBox(width: 6),
                                  const Text('Frase seleccionada',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: HandWaveTheme.blue,
                                          fontWeight:
                                              FontWeight.w600)),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: () => setState(
                                        () => _seleccionada = null),
                                    child: const Icon(Icons.close,
                                        color: HandWaveTheme.blue,
                                        size: 16),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('"$_seleccionada"',
                                  style: const TextStyle(
                                      fontSize: 15,
                                      color: HandWaveTheme.navy,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: () =>
                                    _enviar(_seleccionada!),
                                icon: const Icon(
                                    Icons.send_rounded,
                                    size: 16),
                                label: const Text('Enviar al kiosco'),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}