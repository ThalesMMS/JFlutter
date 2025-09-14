import 'package:flutter/material.dart';
import 'common_ui_components.dart';

/// Contextual help system for JFlutter
class ContextualHelp extends StatefulWidget {
  final Widget child;
  final String helpContent;
  final String? title;
  final IconData? icon;
  final HelpPosition position;
  final bool showOnHover;
  final bool showOnTap;

  const ContextualHelp({
    super.key,
    required this.child,
    required this.helpContent,
    this.title,
    this.icon,
    this.position = HelpPosition.top,
    this.showOnHover = true,
    this.showOnTap = false,
  });

  @override
  State<ContextualHelp> createState() => _ContextualHelpState();
}

class _ContextualHelpState extends State<ContextualHelp> {
  bool _showHelp = false;
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showHelpOverlay() {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => _HelpOverlay(
        helpContent: widget.helpContent,
        title: widget.title,
        icon: widget.icon,
        position: widget.position,
        onDismiss: _hideHelp,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideHelp() {
    _removeOverlay();
    setState(() {
      _showHelp = false;
    });
  }

  void _toggleHelp() {
    if (_showHelp) {
      _hideHelp();
    } else {
      _showHelpOverlay();
      setState(() {
        _showHelp = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.showOnTap ? _toggleHelp : null,
      onLongPress: widget.showOnTap ? null : _toggleHelp,
      child: MouseRegion(
        onEnter: widget.showOnHover ? (_) => _showHelpOverlay() : null,
        onExit: widget.showOnHover ? (_) => _hideHelp() : null,
        child: Stack(
          children: [
            widget.child,
            if (widget.showOnTap)
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: _toggleHelp,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.icon ?? Icons.help_outline,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HelpOverlay extends StatefulWidget {
  final String helpContent;
  final String? title;
  final IconData? icon;
  final HelpPosition position;
  final VoidCallback onDismiss;

  const _HelpOverlay({
    required this.helpContent,
    this.title,
    this.icon,
    required this.position,
    required this.onDismiss,
  });

  @override
  State<_HelpOverlay> createState() => _HelpOverlayState();
}

class _HelpOverlayState extends State<_HelpOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: widget.position == HelpPosition.top 
          ? const Offset(0, -0.1)
          : const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: widget.onDismiss,
        child: Container(
          color: Colors.black.withOpacity(0.1),
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: GestureDetector(
                  onTap: () {}, // Prevent dismissal when tapping on help content
                  child: Container(
                    margin: const EdgeInsets.all(32),
                    constraints: const BoxConstraints(
                      maxWidth: 400,
                      maxHeight: 300,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                widget.icon ?? Icons.help_outline,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.title ?? 'Ajuda',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: widget.onDismiss,
                                icon: const Icon(Icons.close),
                                iconSize: 20,
                              ),
                            ],
                          ),
                        ),
                        
                        // Content
                        Flexible(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              widget.helpContent,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum HelpPosition {
  top,
  bottom,
}

/// Help content definitions for different parts of the application
class HelpContent {
  static const String canvasBasics = '''
Canvas do Automaton

• Clique em um estado para selecioná-lo
• Shift+clique para seleção múltipla
• Arraste estados para movê-los
• Delete para remover selecionados
• Duplo-clique em transições para editar
• Box-select: arraste para selecionar múltiplos estados
''';

  static const String mobileCanvas = '''
Canvas Mobile

• Toque para selecionar estados
• Toque longo para menu de contexto
• Duplo-toque para limpar seleção
• Use a barra de ações na parte inferior
• Arraste para mover estados selecionados
''';

  static const String automatonTypes = '''
Tipos de Autômatos

AFD (Determinístico):
• Exatamente uma transição por símbolo
• Sem transições ε (lambda)
• Mais simples de analisar

AFN (Não-Determinístico):
• Múltiplas transições possíveis
• Pode ter transições ε
• Mais expressivo que AFD

Gramática Regular:
• Regras de produção
• Converte automaticamente para AF
''';

  static const String algorithms = '''
Algoritmos Disponíveis

• AFN → AFD: Converte AFN para AFD
• Minimização: Reduz estados desnecessários
• Complemento: Inverte linguagem aceita
• União/Interseção: Combina autômatos
• Equivalência: Verifica se são iguais
''';

  static const String simulation = '''
Simulação

• Digite uma palavra para testar
• Use "Executar" para resultado final
• Use "Passo a passo" para ver detalhes
• Estados ativos são destacados
• Caminho de aceitação é mostrado
''';

  static const String layoutTools = '''
Ferramentas de Layout

• Compacto: Estados em círculo
• Balanceado: Grid organizado
• Espalhar: Distribuição uniforme
• Hierárquico: Organização em níveis
• Automático: Algoritmo inteligente
''';

  static const String keyboardShortcuts = '''
Atalhos de Teclado

Arquivo:
• Ctrl+N: Novo automaton
• Ctrl+O: Abrir
• Ctrl+S: Salvar
• Ctrl+E: Exportar

Edição:
• Ctrl+Z: Desfazer
• Ctrl+C: Copiar
• Ctrl+V: Colar
• Delete: Excluir

Navegação:
• Setas: Mover seleção
• Alt+1/2/3: Trocar abas
''';

  // New help content for advanced features
  static const String llParsing = '''
Parsing LL(1)

O parsing LL(1) é uma técnica de análise descendente que:
• Lê a entrada da esquerda para a direita
• Constrói uma derivação mais à esquerda
• Usa 1 símbolo de lookahead

A tabela LL(1) mostra qual produção usar baseada no símbolo atual e no lookahead.

Conflitos indicam que a gramática não é LL(1).
''';

  static const String lrParsing = '''
Parsing LR(1)

O parsing LR(1) é uma técnica de análise ascendente que:
• Lê a entrada da esquerda para a direita
• Constrói uma derivação mais à direita
• Usa 1 símbolo de lookahead

A tabela LR(1) contém ações (shift/reduce/accept) e transições goto.

Mais poderoso que LL(1), pode analisar mais gramáticas.
''';

  static const String mealyMoore = '''
Máquinas de Mealy e Moore

Máquinas de Mealy:
• Saída nas transições
• Saída depende do estado atual e entrada
• Mais compactas

Máquinas de Moore:
• Saída nos estados
• Saída depende apenas do estado atual
• Mais simples de implementar

Ambas são equivalentes e podem ser convertidas entre si.
''';

  static const String pda = '''
Autômatos com Pilha (PDA)

• Estendem autômatos finitos com uma pilha
• Podem reconhecer linguagens livres de contexto
• Transições podem empilhar/desempilhar símbolos
• Aceitam por estado final ou pilha vazia

Úteis para análise de linguagens de programação.
''';

  static const String turing = '''
Máquinas de Turing

• Modelo computacional mais poderoso
• Suporte a múltiplas fitas (1-5)
• Podem reconhecer linguagens recursivamente enumeráveis
• Transições podem ler/escrever e mover cabeçote

Base teórica para computação.
''';

  static const String cfg = '''
Gramáticas Livres de Contexto (CFG)

• Regras de produção A → α
• Podem gerar linguagens livres de contexto
• Forma Normal de Chomsky (CNF) simplifica análise
• Algoritmo CYK para parsing

Fundamentais para análise sintática.
''';

  static const String pumpingLemmas = '''
Lemas do Bombeamento

Lema Regular:
• Para linguagens regulares
• Decomposição xyz onde y pode ser bombeado

Lema Context-Free:
• Para linguagens livres de contexto
• Decomposição uvwxy onde vwx pode ser bombeado

Usados para provar que linguagens não pertencem a certas classes.
''';

  static const String minimizationInterface = '''
Interface de Minimização de DFA

Esta interface permite minimizar um DFA passo-a-passo, seguindo o algoritmo de minimização clássico.

Como usar:
1. A árvore de minimização mostra os grupos de estados distinguíveis
2. Clique em um nó para selecioná-lo
3. Use "Expandir" para dividir um grupo por um símbolo
4. Use "Verificar" para confirmar uma expansão
5. Use "Finalizar" quando todos os grupos estiverem processados

O resultado será um DFA com o menor número possível de estados equivalente ao original.
''';

  static const String examplesLibrary = '''
Biblioteca de Exemplos

Esta biblioteca contém uma coleção de exemplos educativos para aprender teoria dos autômatos e linguagens formais.

Como usar:
1. Selecione uma categoria (DFA, NFA, Gramática, etc.)
2. Use a busca para encontrar exemplos específicos
3. Clique em um exemplo para ver os detalhes
4. Use "Carregar Exemplo" para abrir no canvas
5. Use "Mais Info" para ver informações detalhadas

Os exemplos incluem:
• Dificuldade (Fácil, Médio, Difícil)
• Conceitos envolvidos
• Objetivos de aprendizado
• Dados prontos para uso

Perfeito para estudantes e educadores!
''';
}

/// Help button widget for easy integration
class HelpButton extends StatelessWidget {
  final String helpContent;
  final String? title;
  final IconData? icon;
  final String? tooltip;

  const HelpButton({
    super.key,
    required this.helpContent,
    this.title,
    this.icon,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return ContextualHelp(
      helpContent: helpContent,
      title: title,
      icon: icon,
      showOnHover: false,
      showOnTap: true,
      child: IconButton(
        onPressed: () {}, // Handled by ContextualHelp
        icon: Icon(icon ?? Icons.help_outline),
        tooltip: tooltip ?? 'Ajuda',
      ),
    );
  }
}

/// Help panel that can be shown in a drawer or dialog
class HelpPanel extends StatelessWidget {
  final String title;
  final List<HelpSection> sections;

  const HelpPanel({
    super.key,
    required this.title,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: ListView.builder(
        padding: CommonUIComponents.getResponsivePadding(context),
        itemCount: sections.length,
        itemBuilder: (context, index) {
          final section = sections[index];
          return StandardCard(
            margin: const EdgeInsets.only(bottom: CommonUIComponents.sectionSpacing),
            child: ExpansionTile(
              title: Text(
                section.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: CommonUIComponents.getResponsiveFontSize(context),
                ),
              ),
              subtitle: section.subtitle != null 
                  ? Text(
                      section.subtitle!,
                      style: TextStyle(
                        fontSize: CommonUIComponents.getResponsiveFontSize(context, mobile: 12, desktop: 14),
                      ),
                    )
                  : null,
              leading: Icon(
                section.icon,
                size: CommonUIComponents.getResponsiveIconSize(context),
              ),
              children: [
                Padding(
                  padding: CommonUIComponents.getResponsivePadding(context),
                  child: Text(
                    section.content,
                    style: TextStyle(
                      fontSize: CommonUIComponents.getResponsiveFontSize(context),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class HelpSection {
  final String title;
  final String content;
  final IconData icon;
  final String? subtitle;

  const HelpSection({
    required this.title,
    required this.content,
    required this.icon,
    this.subtitle,
  });
}

/// Enhanced tooltip widget with help integration
class HelpTooltip extends StatelessWidget {
  final Widget child;
  final String message;
  final String? helpContent;
  final String? helpTitle;
  final IconData? helpIcon;
  final bool showHelpButton;

  const HelpTooltip({
    super.key,
    required this.child,
    required this.message,
    this.helpContent,
    this.helpTitle,
    this.helpIcon,
    this.showHelpButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      child: showHelpButton && helpContent != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                child,
                const SizedBox(width: 4),
                HelpButton(
                  helpContent: helpContent!,
                  title: helpTitle,
                  icon: helpIcon,
                  tooltip: 'Mais informações',
                ),
              ],
            )
          : child,
    );
  }
}

/// Quick help widget for inline help
class QuickHelp extends StatelessWidget {
  final String content;
  final String? title;
  final IconData? icon;
  final bool isExpanded;

  const QuickHelp({
    super.key,
    required this.content,
    this.title,
    this.icon,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return StandardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null || icon != null)
            Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: CommonUIComponents.getResponsiveIconSize(context),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                ],
                if (title != null)
                  Expanded(
                    child: Text(
                      title!,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: CommonUIComponents.getResponsiveFontSize(context),
                      ),
                    ),
                  ),
              ],
            ),
          if (title != null || icon != null) const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: CommonUIComponents.getResponsiveFontSize(context),
            ),
          ),
        ],
      ),
    );
  }
}

/// Help overlay with better positioning and animations
class HelpOverlay extends StatefulWidget {
  final String content;
  final String? title;
  final IconData? icon;
  final Widget? target;
  final HelpPosition position;
  final VoidCallback onDismiss;

  const HelpOverlay({
    super.key,
    required this.content,
    this.title,
    this.icon,
    this.target,
    this.position = HelpPosition.top,
    required this.onDismiss,
  });

  @override
  State<_HelpOverlay> createState() => _HelpOverlayState();
}

