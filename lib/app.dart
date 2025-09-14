import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'injection/dependency_injection.dart';
import 'presentation/providers/automaton_provider.dart';
import 'presentation/pages/home_page.dart';
import 'core/error_handler.dart';

/// Main application widget with clean architecture
class JFlutterApp extends StatelessWidget {
  const JFlutterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => getIt<AutomatonProvider>(),
        ),
      ],
      child: MaterialApp(
        title: 'JFlutter',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        home: const HomePage(),
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: ErrorHandler.scaffoldMessengerKey,
      ),
    );
  }
}
