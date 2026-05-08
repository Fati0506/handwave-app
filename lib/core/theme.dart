import 'package:flutter/material.dart';

class HandWaveTheme {
  // Paleta principal — más viva y didáctica
  static const Color navy       = Color(0xFF1B3F72);
  static const Color blue       = Color(0xFF2563EB);
  static const Color blueLight  = Color(0xFFEFF6FF);
  static const Color teal       = Color(0xFF0D9488);
  static const Color tealLight  = Color(0xFFF0FDFA);
  static const Color amber      = Color(0xFFD97706);
  static const Color amberLight = Color(0xFFFFFBEB);
  static const Color danger     = Color(0xFFDC2626);
  static const Color dangerLight= Color(0xFFFEF2F2);
  static const Color green      = Color(0xFF16A34A);
  static const Color greenLight = Color(0xFFF0FDF4);
  static const Color purple     = Color(0xFF7C3AED);
  static const Color purpleLight= Color(0xFFF5F3FF);
  static const Color surface    = Color(0xFFF1F5F9);
  static const Color border     = Color(0xFFE2E8F0);
  static const Color textPrimary   = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto',
      colorScheme: ColorScheme.fromSeed(
        seedColor: blue,
        primary: blue,
        secondary: teal,
        surface: Colors.white,
        error: danger,
      ),
      scaffoldBackgroundColor: surface,
      appBarTheme: const AppBarTheme(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: border, width: 0.8),
        ),
        margin: const EdgeInsets.only(bottom: 10),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: blue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: blue,
          side: const BorderSide(color: blue),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: blue, width: 1.8),
        ),
        labelStyle: const TextStyle(color: textSecondary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: blue,
        unselectedItemColor: Color(0xFF94A3B8),
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle:
            TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 10),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: navy,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? blue : Colors.white),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? blue.withOpacity(0.3)
                : border),
      ),
    );
  }
}

class HWTextStyles {
  static const TextStyle displayLarge = TextStyle(
    fontSize: 28, fontWeight: FontWeight.w700,
    color: Colors.white, letterSpacing: -0.5,
  );
  static const TextStyle heading = TextStyle(
    fontSize: 22, fontWeight: FontWeight.w600,
    color: Colors.white, letterSpacing: -0.3,
  );
  static const TextStyle subheading = TextStyle(
    fontSize: 13, color: Colors.white70, height: 1.4,
  );
  static const TextStyle sectionLabel = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w600,
    color: HandWaveTheme.textSecondary, letterSpacing: 0.8,
  );
  static const TextStyle cardTitle = TextStyle(
    fontSize: 13, fontWeight: FontWeight.w600,
    color: HandWaveTheme.textPrimary,
  );
  static const TextStyle cardSubtitle = TextStyle(
    fontSize: 11, color: HandWaveTheme.textSecondary, height: 1.4,
  );
}

// ─── Logo widget reutilizable ────────────────────────────────────────────────
class HandWaveLogo extends StatelessWidget {
  final double size;
  final bool showText;
  const HandWaveLogo({super.key, this.size = 48, this.showText = true});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(size * 0.26),
            border: Border.all(
              color: Colors.white.withOpacity(0.25),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Icon(
              Icons.sign_language_rounded,
              color: Colors.white,
              size: size * 0.54,
            ),
          ),
        ),
        if (showText) ...[
          SizedBox(width: size * 0.22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'HandWave',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.40,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Comunicación sin barreras',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: size * 0.21,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ─── Avatar de perfil con iniciales o foto ──────────────────────────────────
class HWAvatar extends StatelessWidget {
  final String initials;
  final String? photoUrl;
  final double radius;

  const HWAvatar({
    super.key,
    required this.initials,
    this.photoUrl,
    this.radius = 22,
  });

  @override
  Widget build(BuildContext context) {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(photoUrl!),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: HandWaveTheme.blue.withOpacity(0.15),
      child: Text(
        initials,
        style: TextStyle(
          color: HandWaveTheme.blue,
          fontSize: radius * 0.7,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Badge de estado reutilizable ────────────────────────────────────────────
class HWBadge extends StatelessWidget {
  final String text;
  final Color bg;
  final Color color;

  const HWBadge({
    super.key,
    required this.text,
    required this.bg,
    required this.color,
  });

  factory HWBadge.online() => const HWBadge(
    text: 'En línea',
    bg: HandWaveTheme.greenLight,
    color: HandWaveTheme.green,
  );

  factory HWBadge.offline() => const HWBadge(
    text: 'Sin conectar',
    bg: HandWaveTheme.amberLight,
    color: HandWaveTheme.amber,
  );

  factory HWBadge.active() => const HWBadge(
    text: 'Activo',
    bg: HandWaveTheme.blueLight,
    color: HandWaveTheme.blue,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}