import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../features/auth/auth_provider.dart';
import '../features/auth/login_screen.dart';
import '../features/home/home_screen.dart';
import '../features/frases/frases_screen.dart';
import '../features/radar/radar_screen.dart';
import '../features/bolsillo/bolsillo_screen.dart';
import '../features/perfil/perfil_screen.dart';
import '../shared/widgets/main_scaffold.dart';

final appRouter = GoRouter(
  initialLocation: '/home',
  redirect: (context, state) {
    final auth = context.read<AuthProvider>();
    final loggedIn = auth.isLoggedIn;
    final onLogin = state.matchedLocation == '/login';

    if (!loggedIn && !onLogin) return '/login';
    if (loggedIn && onLogin) return '/home';
    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => MainScaffold(child: child),
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/frases',
          builder: (context, state) => const FrasesScreen(),
        ),
        GoRoute(
          path: '/radar',
          builder: (context, state) => const RadarScreen(),
        ),
        GoRoute(
          path: '/bolsillo',
          builder: (context, state) => const BolsilloScreen(),
        ),
        GoRoute(
          path: '/perfil',
          builder: (context, state) => const PerfilScreen(),
        ),
      ],
    ),
  ],
);