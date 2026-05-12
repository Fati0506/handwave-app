import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../auth/auth_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: HandWaveTheme.surface,
      body: CustomScrollView(
        slivers: [
          // ── AppBar expandido ────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 130,
            pinned: true,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: HandWaveTheme.navy,
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hola, ${auth.displayName.split(' ').first} 👋',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          const HandWaveLogo(size: 42),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/perfil'),
                      child: HWAvatar(
                          initials: auth.initials,
                          photoUrl: auth.gravatarUrl,
                          radius: 24),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // ── Estado del kiosco ────────────────────────────────
                _KioskCard(onTap: () => context.push('/kiosco')),
                const SizedBox(height: 20),

                // ── Acciones rápidas ─────────────────────────────────
                const Text('ACCIONES RÁPIDAS',
                    style: HWTextStyles.sectionLabel),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _QuickAction(
                      icon: Icons.chat_bubble_rounded,
                      label: 'Frases',
                      color: HandWaveTheme.teal,
                      bg: HandWaveTheme.tealLight,
                      onTap: () => context.go('/frases'),
                    ),
                    const SizedBox(width: 10),
                    _QuickAction(
                      icon: Icons.mic_rounded,
                      label: 'Bolsillo',
                      color: HandWaveTheme.amber,
                      bg: HandWaveTheme.amberLight,
                      onTap: () => context.go('/bolsillo'),
                    ),
                    const SizedBox(width: 10),
                    _QuickAction(
                      icon: Icons.location_on_rounded,
                      label: 'Radar',
                      color: HandWaveTheme.green,
                      bg: HandWaveTheme.greenLight,
                      onTap: () => context.go('/radar'),
                    ),
                    const SizedBox(width: 10),
                    _QuickAction(
                      icon: Icons.history_rounded,
                      label: 'Historial',
                      color: HandWaveTheme.purple,
                      bg: HandWaveTheme.purpleLight,
                      onTap: () => context.go('/perfil/historial'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Módulos completos ────────────────────────────────
                const Text('MÓDULOS', style: HWTextStyles.sectionLabel),
                const SizedBox(height: 10),

                _ModuleCard(
                  icon: Icons.qr_code_scanner_rounded,
                  iconBg: HandWaveTheme.blueLight,
                  iconColor: HandWaveTheme.blue,
                  title: 'Sincronización kiosco',
                  subtitle: 'Escanea el QR del punto de venta',
                  badge: HWBadge.offline(),
                  onTap: () => context.push('/kiosco'),
                ),
                _ModuleCard(
                  icon: Icons.chat_bubble_rounded,
                  iconBg: HandWaveTheme.tealLight,
                  iconColor: HandWaveTheme.teal,
                  title: 'Billetera de frases',
                  subtitle: 'Envía frases rápidas al kiosco',
                  badge: HWBadge.active(),
                  onTap: () => context.go('/frases'),
                ),
                _ModuleCard(
                  icon: Icons.location_on_rounded,
                  iconBg: HandWaveTheme.greenLight,
                  iconColor: HandWaveTheme.green,
                  title: 'Radar inclusivo',
                  subtitle: 'Locales con HandWave cerca de ti',
                  badge: const HWBadge(
                    text: 'Ver mapa',
                    bg: HandWaveTheme.greenLight,
                    color: HandWaveTheme.green,
                  ),
                  onTap: () => context.go('/radar'),
                ),
                _ModuleCard(
                  icon: Icons.mic_rounded,
                  iconBg: HandWaveTheme.amberLight,
                  iconColor: HandWaveTheme.amber,
                  title: 'Modo bolsillo',
                  subtitle: 'Transcripción de voz sin kiosco',
                  badge: const HWBadge(
                    text: 'Offline',
                    bg: HandWaveTheme.amberLight,
                    color: HandWaveTheme.amber,
                  ),
                  onTap: () => context.go('/bolsillo'),
                ),

                const SizedBox(height: 20),

                // ── Historial reciente ───────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('ACTIVIDAD RECIENTE',
                        style: HWTextStyles.sectionLabel),
                    GestureDetector(
                      onTap: () => context.go('/perfil/historial'),
                      child: const Text('Ver todo',
                          style: TextStyle(
                              fontSize: 11,
                              color: HandWaveTheme.blue,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _RecentActivity(uid: auth.user?.uid ?? ''),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widgets internos ─────────────────────────────────────────────────────────

class _KioskCard extends StatelessWidget {
  final VoidCallback onTap;
  const _KioskCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1B3F72), Color(0xFF2563EB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.circle, color: Color(0xFF94A3B8), size: 7),
                    SizedBox(width: 5),
                    Text('Estado del kiosco',
                        style: TextStyle(
                            color: Colors.white60, fontSize: 11)),
                  ]),
                  SizedBox(height: 7),
                  Text('Sin sincronizar',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700)),
                  SizedBox(height: 4),
                  Text('Toca para escanear el QR',
                      style: TextStyle(
                          color: Color(0xFF5DCAA5), fontSize: 12)),
                ],
              ),
            ),
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.qr_code_scanner_rounded,
                  color: Colors.white70, size: 26),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon, required this.label,
    required this.color, required this.bg, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 5),
              Text(label,
                  style: TextStyle(
                      fontSize: 10,
                      color: color,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg, iconColor;
  final String title, subtitle;
  final Widget badge;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.icon, required this.iconBg, required this.iconColor,
    required this.title, required this.subtitle,
    required this.badge, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: HWTextStyles.cardTitle),
                    const SizedBox(height: 3),
                    Text(subtitle, style: HWTextStyles.cardSubtitle),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              badge,
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right,
                  color: HandWaveTheme.textSecondary, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentActivity extends StatelessWidget {
  final String uid;
  const _RecentActivity({required this.uid});

  @override
  Widget build(BuildContext context) {
    if (uid.isEmpty) return const SizedBox();
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .collection('historial')
          .orderBy('fecha', descending: true)
          .limit(3)
          .snapshots(),
      builder: (_, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: HandWaveTheme.border, width: 0.8),
            ),
            child: const Row(
              children: [
                Icon(Icons.history_rounded,
                    color: HandWaveTheme.textSecondary, size: 20),
                SizedBox(width: 12),
                Text('Aún no hay actividad reciente.',
                    style: HWTextStyles.cardSubtitle),
              ],
            ),
          );
        }
        return Column(
          children: snap.data!.docs.map((doc) {
            final d = doc.data() as Map;
            return Card(
              child: ListTile(
                dense: true,
                leading: Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: HandWaveTheme.purpleLight,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(Icons.history_rounded,
                      color: HandWaveTheme.purple, size: 17),
                ),
                title: Text(d['titulo'] ?? 'Sesión',
                    style: HWTextStyles.cardTitle
                        .copyWith(fontSize: 12)),
                subtitle: Text(d['resumen'] ?? '',
                    style: HWTextStyles.cardSubtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                trailing: const Icon(Icons.chevron_right,
                    color: HandWaveTheme.textSecondary, size: 16),
                onTap: () => context.go('/perfil/historial'),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}