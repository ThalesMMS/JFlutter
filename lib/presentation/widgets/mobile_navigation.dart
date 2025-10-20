//
//  mobile_navigation.dart
//  JFlutter
//
//  Fornece a barra inferior de navegação otimizada para dispositivos móveis,
//  apresentando itens configuráveis com ícones, rótulos e descrições para
//  suportar múltiplos módulos do aplicativo em telas compactas.
//  Aplica estética Material 3 com SafeArea, sombras sutis e destaque do item
//  ativo, garantindo acessibilidade e facilidade na expansão do menu.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/material.dart';

/// Mobile-optimized bottom navigation widget
class MobileNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavigationItem> items;

  const MobileNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 70, // Reduced height for better space usage
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = currentIndex == index;

              return Expanded(
                child: _buildNavigationItem(
                  context,
                  item,
                  isSelected,
                  () => onTap(index),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationItem(
    BuildContext context,
    NavigationItem item,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isSelected
        ? colorScheme.primary
        : colorScheme.onSurface.withValues(alpha: 0.6);

    return FocusableActionDetector(
      descendantsAreFocusable: false,
      child: Semantics(
        button: true,
        selected: isSelected,
        hint: item.description,
        onTap: onTap,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.icon,
                  color: color,
                  size: 18, // Smaller icons for better fit
                ),
                const SizedBox(height: 2),
                Text(
                  item.label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 9, // Even smaller text
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Navigation item data class
class NavigationItem {
  final String label;
  final IconData icon;
  final String description;

  const NavigationItem({
    required this.label,
    required this.icon,
    required this.description,
  });
}
