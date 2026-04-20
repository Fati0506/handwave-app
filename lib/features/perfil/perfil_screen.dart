import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme.dart';
import '../auth/auth_provider.dart';

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

  @override
  void initState() {
    super.initState();
    _loadPrefs();
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

  void _showSosDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.emergency, color: HandWaveTheme.danger),
            SizedBox(width: 8),
            Text('Contacto S.O.S',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration:
                  const InputDecoration(labelText: 'Nombre del contacto'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Teléfono'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Tarjeta de usuario
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
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(auth.displayName,
                            style: HWTextStyles.cardTitle
                                .copyWith(fontSize: 15)),
                        const SizedBox(height: 2),
                        Text(auth.user?.email ?? '',
                            style: HWTextStyles.cardSubtitle),
                        const SizedBox(height: 4),
                        const Text('Cuenta activa',
                            style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF185FA5))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Accesibilidad
          const Text('ACCESIBILIDAD', style: HWTextStyles.sectionLabel),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                _SettingTile(
                  icon: Icons.text_fields,
                  title: 'Fuente grande',
                  subtitle: 'Aumenta el tamaño del texto',
                  value: _fuenteGrande,
                  onChanged: (v) {
                    setState(() => _fuenteGrande = v);
                    _savePref('fuenteGrande', v);
                  },
                ),
                const Divider(height: 0.5, indent: 16),
                _SettingTile(
                  icon: Icons.contrast,
                  title: 'Alto contraste',
                  subtitle: 'Mejora visibilidad del texto',
                  value: _altoContraste,
                  onChanged: (v) {
                    setState(() => _altoContraste = v);
                    _savePref('altoContraste', v);
                  },
                ),
                const Divider(height: 0.5, indent: 16),
                _SettingTile(
                  icon: Icons.vibration,
                  title: 'Vibración al enviar',
                  subtitle: 'Feedback háptico en envíos',
                  value: _vibracion,
                  onChanged: (v) {
                    setState(() => _vibracion = v);
                    _savePref('vibracion', v);
                  },
                ),
                const Divider(height: 0.5, indent: 16),
                _SettingTile(
                  icon: Icons.mic_none,
                  title: 'Modo bolsillo (offline)',
                  subtitle: 'STT sin kiosco disponible',
                  value: _modoBolsillo,
                  onChanged: (v) {
                    setState(() => _modoBolsillo = v);
                    _savePref('modoBolsillo', v);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // S.O.S
          const Text('EMERGENCIA', style: HWTextStyles.sectionLabel),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showSosDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: HandWaveTheme.danger,
              ),
              icon: const Icon(Icons.emergency, size: 18),
              label: const Text('S.O.S — Contacto de emergencia'),
            ),
          ),
          const SizedBox(height: 24),

          // Cerrar sesión
          const Text('CUENTA', style: HWTextStyles.sectionLabel),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout, color: HandWaveTheme.danger),
              title: const Text('Cerrar sesión',
                  style: TextStyle(color: HandWaveTheme.danger, fontSize: 13)),
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

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

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
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: HandWaveTheme.navy,
          ),
        ],
      ),
    );
  }
}