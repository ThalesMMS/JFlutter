import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/entities/automaton_entity.dart';
import '../../core/result.dart';
import '../../core/error_handler.dart';
import '../../core/parsers/jflap_xml_parser.dart';

class ExportImportTools extends StatelessWidget {
  const ExportImportTools({
    super.key,
    required this.automaton,
    this.onAutomatonChanged,
  });

  final AutomatonEntity automaton;
  final void Function(AutomatonEntity)? onAutomatonChanged;

  Future<void> _exportAutomaton(BuildContext context) async {
    try {
      final jsonString = jsonEncode(automaton.toJson());
      
      if (Platform.isAndroid || Platform.isIOS) {
        // On mobile, use share functionality
        await Share.share(
          jsonString,
          subject: 'Automaton Export',
        );
        ErrorHandler.showSuccess(context, 'Automaton exportado com sucesso');
      } else {
        // On desktop/web, copy to clipboard
        await Clipboard.setData(ClipboardData(text: jsonString));
        ErrorHandler.showSuccess(context, 'Automaton copiado para a área de transferência');
      }
    } catch (e) {
      ErrorHandler.showError(context, 'Erro ao exportar: $e');
    }
  }

  Future<void> _importAutomaton(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'jff'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          final fileContent = String.fromCharCodes(file.bytes!);
          
          // Verificar se é arquivo JFLAP (.jff) ou JSON
          if (file.extension == 'jff') {
            await _importJFLAPFile(context, fileContent);
          } else {
            // Importar como JSON
            final jsonData = jsonDecode(fileContent) as Map<String, dynamic>;
            final importedAutomaton = Automaton.fromJson(jsonData);
            
            if (onAutomatonChanged != null) {
              onAutomatonChanged!(importedAutomaton);
            }
            
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Automaton importado com sucesso'),
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao importar: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _importJFLAPFile(BuildContext context, String xmlContent) async {
    try {
      final result = JFLAPXMLParser.parseJFLAPFile(xmlContent);
      
      if (result.isSuccess) {
        final importedAutomaton = result.data;
        
        if (onAutomatonChanged != null) {
          onAutomatonChanged!(importedAutomaton);
        }
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Arquivo JFLAP importado com sucesso'),
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao importar arquivo JFLAP: ${result.error}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao processar arquivo JFLAP: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _importFromClipboard(BuildContext context) async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData?.text != null) {
        final jsonData = jsonDecode(clipboardData!.text!) as Map<String, dynamic>;
        final importedAutomaton = Automaton.fromJson(jsonData);
        
        if (onAutomatonChanged != null) {
          onAutomatonChanged!(importedAutomaton);
        }
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Automaton importado da área de transferência'),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao importar da área de transferência: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Exportar / Importar',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _exportAutomaton(context),
                  icon: const Icon(Icons.upload),
                  label: const Text('Exportar AF'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _importAutomaton(context),
                  icon: const Icon(Icons.download),
                  label: const Text('Importar AF'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _importFromClipboard(context),
                  icon: const Icon(Icons.content_paste),
                  label: const Text('Colar da Área de Transferência'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Exporta um JSON com Σ, estados, transições, inicial e nextId. Importar substituirá o AF atual. Suporta arquivos JSON e JFLAP (.jff).',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AutomatonValidator {
  static List<String> validateAutomaton(Automaton automaton) {
    final errors = <String>[];

    // Check for empty automaton
    if (automaton.states.isEmpty) {
      errors.add('Automaton não possui estados');
      return errors;
    }

    // Check for initial state
    if (automaton.initialId == null) {
      errors.add('Automaton não possui estado inicial');
    } else if (automaton.getState(automaton.initialId!) == null) {
      errors.add('Estado inicial "${automaton.initialId}" não existe');
    }

    // Check for final states
    final finalStates = automaton.states.where((s) => s.isFinal).toList();
    if (finalStates.isEmpty) {
      errors.add('Automaton não possui estados finais');
    }

    // Check alphabet
    if (automaton.alphabet.isEmpty) {
      errors.add('Alfabeto está vazio');
    }

    // Check for unreachable states
    final reachableStates = _findReachableStates(automaton);
    final unreachableStates = automaton.states
        .where((s) => !reachableStates.contains(s.id))
        .toList();
    
    if (unreachableStates.isNotEmpty) {
      errors.add('Estados inalcançáveis: ${unreachableStates.map((s) => s.name).join(', ')}');
    }

    // Check for transitions with invalid states
    for (final entry in automaton.transitions.entries) {
      final parts = entry.key.split('|');
      if (parts.length != 2) {
        errors.add('Transição inválida: ${entry.key}');
        continue;
      }
      
      final fromState = parts[0];
      final symbol = parts[1];
      
      if (automaton.getState(fromState) == null) {
        errors.add('Transição de estado inexistente: $fromState');
      }
      
      if (!automaton.alphabet.contains(symbol) && symbol != 'λ') {
        errors.add('Transição com símbolo não pertencente ao alfabeto: $symbol');
      }
      
      for (final toState in entry.value) {
        if (automaton.getState(toState) == null) {
          errors.add('Transição para estado inexistente: $toState');
        }
      }
    }

    return errors;
  }

  static Set<String> _findReachableStates(Automaton automaton) {
    if (automaton.initialId == null) return {};
    
    final reachable = <String>{};
    final queue = <String>[automaton.initialId!];
    
    while (queue.isNotEmpty) {
      final state = queue.removeAt(0);
      if (reachable.contains(state)) continue;
      
      reachable.add(state);
      
      // Find all transitions from this state
      for (final entry in automaton.transitions.entries) {
        final parts = entry.key.split('|');
        if (parts.length == 2 && parts[0] == state) {
          for (final dest in entry.value) {
            if (!reachable.contains(dest)) {
              queue.add(dest);
            }
          }
        }
      }
    }
    
    return reachable;
  }
}

class ValidationCard extends StatelessWidget {
  const ValidationCard({
    super.key,
    required this.automaton,
  });

  final Automaton automaton;

  @override
  Widget build(BuildContext context) {
    final errors = AutomatonValidator.validateAutomaton(automaton);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  errors.isEmpty ? Icons.check_circle : Icons.error,
                  color: errors.isEmpty 
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 8),
                Text(
                  'Validação do Automaton',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (errors.isEmpty)
              Text(
                'Automaton válido',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Problemas encontrados:',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  for (final error in errors)
                    Padding(
                      padding: const EdgeInsets.only(left: 8, top: 2),
                      child: Text(
                        '• $error',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
