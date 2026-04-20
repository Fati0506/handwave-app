import 'package:flutter/material.dart';
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
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: HandWaveTheme.navy,
                padding:
                    const EdgeInsets.fromLTRB(20, 60, 20, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hola, ${auth.displayName.split(' ').first}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          const Text(
                            'HandWave',
                            style: HWTextStyles.heading,
                          ),
                        ],
                      ),
                    ),
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: Text(
                        auth.initials,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Estado del kiosco
                _KioskStatusCard(),
                const SizedBox(height: 16),

                const Text('MÓDULOS', style: HWTextStyles.sectionLabel),
                const SizedBox(height: 8),

                _ModuleCard(
                  icon: Icons.qr_code_scanner,
                  iconBg: const Color(0xFFE6F1FB),
                  iconColor: const Color(0xFF185FA5),
                  title: 'Sincronización kiosco',
                  subtitle: 'Conectar via QR',
                  badgeText: 'Sin conectar',
                  badgeBg: HandWaveTheme.amberLight,
                  badgeColor: HandWaveTheme.amber,
                  onTap: () {},
                ),
                _ModuleCard(
                  icon: Icons.chat_bubble_outline,
                  iconBg: const Color(0xFFEAF3DE),
                  iconColor: const Color(0xFF3B6D11),
                  title: 'Billetera de frases',
                  subtitle: 'Envía frases al kiosco',
                  badgeText: 'Activo',
                  badgeBg: const Color(0xFFEAF3DE),
                  badgeColor: const Color(0xFF3B6D11),
                  onTap: () => context.go('/frases'),
                ),
                _ModuleCard(
                  icon: Icons.map_outlined,
                  iconBg: const Color(0xFFE1F5EE),
                  iconColor: const Color(0xFF0F6E56),
                  title: 'Radar inclusivo',
                  subtitle: 'Locales con HandWave',
                  badgeText: 'Ver mapa',
                  badgeBg: const Color(0xFFE6F1FB),
                  badgeColor: const Color(0xFF185FA5),
                  onTap: () => context.go('/radar'),
                ),
                _ModuleCard(
                  icon: Icons.mic_none,
                  iconBg: const Color(0xFFFAEEDA),
                  iconColor: HandWaveTheme.amber,
                  title: 'Modo bolsillo',
                  subtitle: 'STT sin kiosco',
                  badgeText: 'Offline',
                  badgeBg: HandWaveTheme.amberLight,
                  badgeColor: HandWaveTheme.amber,
                  onTap: () => context.go('/bolsillo'),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _KioskStatusCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HandWaveTheme.navy,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Estado del kiosco',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                SizedBox(height: 4),
                Text('Sin sincronizar',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500)),
                SizedBox(height: 4),
                Text('Escanea un QR para conectar',
                    style: TextStyle(
                        color: Color(0xFF5DCAA5), fontSize: 11)),
              ],
            ),
          ),
          const Icon(Icons.qr_code_scanner,
              color: Colors.white38, size: 36),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String badgeText;
  final Color badgeBg;
  final Color badgeColor;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.badgeBg,
    required this.badgeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: HWTextStyles.cardTitle),
                    const SizedBox(height: 2),
                    Text(subtitle, style: HWTextStyles.cardSubtitle),
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
      ),
    );
  }
}
