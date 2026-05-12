import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'features/auth/auth_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  runApp(const HandWaveApp());
}

class HandWaveApp extends StatelessWidget {
  const HandWaveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: Builder(
        builder: (context) {
          // El router necesita el provider ya montado
          final router = buildRouter(context.read<AuthProvider>());
          return MaterialApp.router(
            title: 'HandWave',
            debugShowCheckedModeBanner: false,
            theme: HandWaveTheme.light(),
            routerConfig: router,
          );
        },
      ),
    );
  }
}