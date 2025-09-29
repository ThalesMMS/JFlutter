import 'package:flutter/material.dart';
import 'injection/dependency_injection.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Setup dependency injection
  await setupDependencyInjection();

  runApp(const JFlutterApp());
}
