//
//  main.dart
//  JFlutter
//
//  Ponto de entrada que inicializa o binding do Flutter, configura as
//  dependências compartilhadas com o injetor e executa o JFlutterApp como
//  aplicação raiz para iniciar a experiência multiplataforma.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/material.dart';
import 'injection/dependency_injection.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Setup dependency injection
  await setupDependencyInjection();

  runApp(const JFlutterApp());
}
