import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/auth/auth_provider.dart';
import '../features/auth/login_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/home/home_screen.dart';
import '../features/frases/frases_screen.dart';
import '../features/radar/radar_screen.dart';
import '../features/bolsillo/bolsillo_screen.dart';
import '../features/perfil/perfil_screen.dart';
import '../features/historial/historial_screen.dart';
import '../features/kiosco/kiosco_screen.dart';
import '../shared/widgets/main_scaffold.dart';

GoRouter buildRouter(AuthProvider auth) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: auth,
    redirect: (context, state) async {
      final loggedIn = auth.isLoggedIn;
      final loc = state.matchedLocation;

      if (loc == '/splash') {
        final prefs = await SharedPreferences.getInstance();
        final done = prefs.getBool('onboarding_done') ?? false;
        if (!done) return '/onboarding';
        if (!loggedIn) return '/login';
        return '/home';
      }

      if (!loggedIn && loc != '/login' && loc != '/onboarding') {
        return '/login';
      }

      if (loggedIn && loc == '/login') return '/home';

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const _SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (_, __, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (_, __) => const HomeScreen(),
          ),
          GoRoute(
            path: '/frases',
            builder: (_, __) => const FrasesScreen(),
          ),
          GoRoute(
            path: '/radar',
            builder: (_, __) => const RadarScreen(),
          ),
          GoRoute(
            path: '/bolsillo',
            builder: (_, __) => const BolsilloScreen(),
          ),
          GoRoute(
            path: '/perfil',
            builder: (_, __) => const PerfilScreen(),
            routes: [
              GoRoute(
                path: 'historial',
                builder: (_, __) => const HistorialScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/kiosco',
            builder: (_, __) => const KioscoScreen(),
          ),
        ],
      ),
    ],
  );
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF1B3F72),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sign_language_rounded,
                color: Colors.white, size: 64),
            SizedBox(height: 16),
            Text(
              'HandWave',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 8),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.white54,
                strokeWidth: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}