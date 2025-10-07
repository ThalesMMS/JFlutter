//
//  app.dart
//  JFlutter
//
//  Configura o widget raiz do aplicativo com ProviderScope, definindo temas
//  claro e escuro do Material 3 e estabelecendo a HomePage como tela inicial
//  responsiva para todas as plataformas suportadas.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/theme/app_theme.dart';

/// Main application widget with clean architecture
class JFlutterApp extends StatelessWidget {
  const JFlutterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'JFlutter',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const HomePage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
