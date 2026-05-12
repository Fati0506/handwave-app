import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme.dart';
import '../auth/auth_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  bool _fuenteGrande = false;
  bool _altoContraste = false;
  bool _vibracion = true;
  bool _modoBolsillo = false;

  // ─── Controladores de identidad del usuario ──────────────────────────────
  final _nombreCtrl = TextEditingController();
  final _apellidosCtrl = TextEditingController();
  final _dniCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();

  // ─── Controladores médicos y SOS ─────────────────────────────────────────
  final _sosNombreCtrl = TextEditingController();
  final _sosTelefonoCtrl = TextEditingController();
  final _sangreCtrl = TextEditingController();
  final _alergiasCtrl = TextEditingController();
  final _condicionCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  @override
  void dispose() {
    // Es importante limpiar la memoria de todos los controladores
    _nombreCtrl.dispose();
    _apellidosCtrl.dispose();
    _dniCtrl.dispose();
    _correoCtrl.dispose();
    _direccionCtrl.dispose();
    _sosNombreCtrl.dispose();
    _sosTelefonoCtrl.dispose();
    _sangreCtrl.dispose();
    _alergiasCtrl.dispose();
    _condicionCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fuenteGrande = prefs.getBool('fuenteGrande') ?? false;
      _altoContraste = prefs.getBool('altoContraste') ?? false;
      _vibracion = prefs.getBool('vibracion') ?? true;
      _modoBolsillo = prefs.getBool('modoBolsillo') ?? false;
    });
  }

  Future<void> _savePref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  // ─── Lógica de guardado en Firebase ──────────────────────────────────────
  Future<void> _guardarSos(BuildContext dialogContext) async {
    final uid = context.read<AuthProvider>().user?.uid;
    if (uid == null) return;

    try {
      await FirebaseFirestore.instance.collection('usuarios').doc(uid).set({
        'nombre': _nombreCtrl.text.trim(),
        'apellidos': _apellidosCtrl.text.trim(),
        'dni': _dniCtrl.text.trim(),
        'correo': _correoCtrl.text.trim(),
        'direccion': _direccionCtrl.text.trim(),
        'contacto_sos_nombre': _sosNombreCtrl.text.trim(),
        'contacto_sos_telefono': _sosTelefonoCtrl.text.trim(),
        'tipo_sangre': _sangreCtrl.text.trim(),
        'alergias': _alergiasCtrl.text.trim(),
        'condicion': _condicionCtrl.text.trim(),
      }, SetOptions(merge: true));

      if (mounted) {
        Navigator.pop(dialogContext);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Datos guardados con éxito'),
            backgroundColor: HandWaveTheme.teal,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al guardar los datos'),
            backgroundColor: HandWaveTheme.danger,
          ),
        );
      }
    }
  }

  // ─── Diálogo de edición de perfil completo ───────────────────────────────
  Future<void> _showSosDialog() async {
    final uid = context.read<AuthProvider>().user?.uid;
    if (uid == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('usuarios').doc(uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _nombreCtrl.text = data['nombre'] ?? '';
        _apellidosCtrl.text = data['apellidos'] ?? '';
        _dniCtrl.text = data['dni'] ?? '';
        _correoCtrl.text = data['correo'] ?? '';
        _direccionCtrl.text = data['direccion'] ?? '';
        _sosNombreCtrl.text = data['contacto_sos_nombre'] ?? '';
        _sosTelefonoCtrl.text = data['contacto_sos_telefono'] ?? '';
        _sangreCtrl.text = data['tipo_sangre'] ?? '';
        _alergiasCtrl.text = data['alergias'] ?? '';
        _condicionCtrl.text = data['condicion'] ?? '';
      } else {
        _nombreCtrl.clear(); _apellidosCtrl.clear(); _dniCtrl.clear();
        _correoCtrl.clear(); _direccionCtrl.clear(); _sosNombreCtrl.clear();
        _sosTelefonoCtrl.clear(); _sangreCtrl.clear(); _alergiasCtrl.clear();
        _condicionCtrl.clear();
      }
    } catch (e) {
      // Ignorar error de red y mostrar campos vacíos
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.manage_accounts_rounded, color: HandWaveTheme.navy),
            SizedBox(width: 8),
            Text('Editar Perfil', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Datos Personales
              const Text('Datos Personales', style: TextStyle(fontSize: 12, color: HandWaveTheme.textSecondary, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              TextFormField(controller: _nombreCtrl, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Nombres')),
              TextFormField(controller: _apellidosCtrl, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Apellidos')),
              TextFormField(controller: _dniCtrl, keyboardType: TextInputType.number, maxLength: 8, decoration: const InputDecoration(labelText: 'DNI', counterText: "")),
              TextFormField(controller: _correoCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Correo electrónico')),
              TextFormField(controller: _direccionCtrl, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Dirección de domicilio')),
              
              const SizedBox(height: 24),
              
              // Contacto de Emergencia
              const Text('Contacto de Emergencia', style: TextStyle(fontSize: 12, color: HandWaveTheme.danger, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              TextFormField(controller: _sosNombreCtrl, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Nombre del contacto')),
              TextFormField(controller: _sosTelefonoCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Teléfono (Ej: 999111222)')),
              
              const SizedBox(height: 24),

              // Datos Médicos
              const Text('Datos Médicos', style: TextStyle(fontSize: 12, color: HandWaveTheme.teal, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              TextFormField(controller: _sangreCtrl, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'Tipo de Sangre (Ej: O+)')),
              TextFormField(controller: _alergiasCtrl, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Alergias conocidas')),
              TextFormField(controller: _condicionCtrl, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Condición médica (Ej: Asma)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => _guardarSos(dialogContext), style: ElevatedButton.styleFrom(backgroundColor: HandWaveTheme.navy), child: const Text('Guardar')),
        ],
      ),
    );
  }

  // ─── Lógica GPS y envío de Alerta ────────────────────────────────────────
  Future<void> _enviarAlertaConOpciones(BuildContext context, String telfSos, String nombreUsuario, Map<String, dynamic> data) async {
    String num = telfSos.replaceAll(RegExp(r'[^0-9]'), '');
    if (num.length == 9) num = '51$num';

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            SizedBox(width: 15),
            Text('Obteniendo ubicación GPS exacta...'),
          ],
        ),
        duration: Duration(seconds: 12),
        backgroundColor: HandWaveTheme.navy,
      ),
    );

    String ubicacionUrl = 'Ubicación no disponible';
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        Position pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.bestForNavigation,
          timeLimit: const Duration(seconds: 10),
        );
        ubicacionUrl = 'https://maps.google.com/?q=${pos.latitude},${pos.longitude}';
      }
    } catch (e) {
      try {
        Position? lastPos = await Geolocator.getLastKnownPosition();
        if (lastPos != null) {
          ubicacionUrl = 'https://maps.google.com/?q=${lastPos.latitude},${lastPos.longitude}';
        }
      } catch (e2) {}
    }

    if (context.mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();

    // Mensaje de emergencia súper completo
    final dni = data['dni'] ?? 'No registrado';
    final msg = '¡S.O.S! Soy $nombreUsuario. Necesito ayuda urgente.\nDNI: $dni\n\nMi ubicación actual es: $ubicacionUrl';

    if (context.mounted) {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('¿Por dónde deseas enviar la alerta S.O.S?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              ListTile(
                leading: const Icon(Icons.wechat_rounded, color: Colors.green, size: 28),
                title: const Text('Enviar por WhatsApp'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final waUri = Uri.parse('https://wa.me/$num?text=${Uri.encodeComponent(msg)}');
                  await launchUrl(waUri, mode: LaunchMode.externalApplication);
                },
              ),
              ListTile(
                leading: const Icon(Icons.sms_rounded, color: Colors.blue, size: 28),
                title: const Text('Enviar por SMS'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final smsUri = Uri.parse('sms:+$num?body=${Uri.encodeComponent(msg)}');
                  await launchUrl(smsUri);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        actions: [
          // Botón directo para editar el perfil en la parte superior
          IconButton(
            icon: const Icon(Icons.edit_note_rounded),
            tooltip: 'Editar perfil completo',
            onPressed: _showSosDialog,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Tarjeta Cabecera de Usuario ──────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: HandWaveTheme.navy,
                    child: Text(
                      auth.initials,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(auth.displayName, style: HWTextStyles.cardTitle.copyWith(fontSize: 15)),
                        const SizedBox(height: 2),
                        Text(auth.user?.email ?? '', style: HWTextStyles.cardSubtitle),
                        const SizedBox(height: 4),
                        const Text('Cuenta activa', style: TextStyle(fontSize: 10, color: Color(0xFF185FA5))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── StreamBuilder para los Datos Dinámicos ────────────────────────
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('usuarios').doc(auth.user?.uid).snapshots(),
            builder: (context, snap) {
              final data = snap.data?.data() as Map<String, dynamic>? ?? {};
              final telfSos = data['contacto_sos_telefono'] ?? '';
              final correoDisplay = data['correo'] != null && data['correo'].toString().isNotEmpty ? data['correo'] : auth.user?.email;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SECCIÓN 1: MIS DATOS PERSONALES
                  const Text('MIS DATOS PERSONALES', style: HWTextStyles.sectionLabel),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _InfoRow(label: 'DNI', value: data['dni'] ?? '-'),
                          const Divider(height: 16),
                          _InfoRow(label: 'Nombres', value: data['nombre'] ?? '-'),
                          const Divider(height: 16),
                          _InfoRow(label: 'Apellidos', value: data['apellidos'] ?? '-'),
                          const Divider(height: 16),
                          _InfoRow(label: 'Correo', value: correoDisplay ?? '-'),
                          const Divider(height: 16),
                          _InfoRow(label: 'Dirección', value: data['direccion'] ?? '-'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // SECCIÓN 2: EMERGENCIA Y SALUD
                  const Text('EMERGENCIA Y SALUD', style: HWTextStyles.sectionLabel),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.medical_services_outlined, color: HandWaveTheme.teal, size: 20),
                              const SizedBox(width: 10),
                              Text('Sangre: ${data['tipo_sangre'] ?? '-'}', style: const TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Alergias: ${data['alergias'] ?? 'Ninguna'}', style: const TextStyle(fontSize: 13, color: HandWaveTheme.textSecondary)),
                          const SizedBox(height: 4),
                          Text('Condición: ${data['condicion'] ?? 'Ninguna'}', style: const TextStyle(fontSize: 13, color: HandWaveTheme.textSecondary)),
                          const Divider(height: 24),
                          
                          Row(
                            children: [
                              const Icon(Icons.contact_emergency_outlined, color: HandWaveTheme.danger, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Contacto SOS', style: TextStyle(fontSize: 11, color: HandWaveTheme.textSecondary)),
                                    Text('${data['contacto_sos_nombre'] ?? 'Sin configurar'}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                    Text(telfSos, style: const TextStyle(fontSize: 13)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Botones de acción SOS
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: telfSos.isEmpty ? null : () => 
                                      _enviarAlertaConOpciones(context, telfSos, auth.displayName, data),
                                  style: ElevatedButton.styleFrom(backgroundColor: HandWaveTheme.green),
                                  icon: const Icon(Icons.emergency_share_rounded, size: 18),
                                  label: const Text('Enviar Alerta', style: TextStyle(fontSize: 12)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: telfSos.isEmpty ? null : () async {
                                    final uri = Uri.parse('tel:$telfSos');
                                    if (await canLaunchUrl(uri)) await launchUrl(uri);
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: HandWaveTheme.danger),
                                  icon: const Icon(Icons.phone_in_talk_rounded, size: 18),
                                  label: const Text('Llamar', style: TextStyle(fontSize: 12)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }
          ),
          const SizedBox(height: 16),

          // ── Accesibilidad ──────────────────────────────────────────────────
          const Text('ACCESIBILIDAD', style: HWTextStyles.sectionLabel),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                _SettingTile(icon: Icons.text_fields, title: 'Fuente grande', subtitle: 'Aumenta el tamaño del texto', value: _fuenteGrande, onChanged: (v) { setState(() => _fuenteGrande = v); _savePref('fuenteGrande', v); }),
                const Divider(height: 0.5, indent: 16),
                _SettingTile(icon: Icons.contrast, title: 'Alto contraste', subtitle: 'Mejora visibilidad del texto', value: _altoContraste, onChanged: (v) { setState(() => _altoContraste = v); _savePref('altoContraste', v); }),
                const Divider(height: 0.5, indent: 16),
                _SettingTile(icon: Icons.vibration, title: 'Vibración al enviar', subtitle: 'Feedback háptico en envíos', value: _vibracion, onChanged: (v) { setState(() => _vibracion = v); _savePref('vibracion', v); }),
                const Divider(height: 0.5, indent: 16),
                _SettingTile(icon: Icons.mic_none, title: 'Modo bolsillo (offline)', subtitle: 'STT sin kiosco disponible', value: _modoBolsillo, onChanged: (v) { setState(() => _modoBolsillo = v); _savePref('modoBolsillo', v); }),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Cerrar sesión ──────────────────────────────────────────────────
          const Text('CUENTA', style: HWTextStyles.sectionLabel),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout, color: HandWaveTheme.danger),
              title: const Text('Cerrar sesión', style: TextStyle(color: HandWaveTheme.danger, fontSize: 13)),
              onTap: () async {
                await auth.signOut();
                if (context.mounted) context.go('/login');
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Widgets Auxiliares ──────────────────────────────────────────────────────

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingTile({required this.icon, required this.title, required this.subtitle, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: HandWaveTheme.navy),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: HWTextStyles.cardTitle),
                Text(subtitle, style: HWTextStyles.cardSubtitle),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeThumbColor: HandWaveTheme.navy),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: HandWaveTheme.textSecondary, fontWeight: FontWeight.w500)),
          const SizedBox(width: 16),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: HandWaveTheme.textPrimary), textAlign: TextAlign.right, maxLines: 2, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}