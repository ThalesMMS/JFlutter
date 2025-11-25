import 'package:flutter/material.dart';

class TabletLayoutContainer extends StatelessWidget {
  final Widget canvas;
  final Widget algorithmPanel;
  final Widget simulationPanel;
  final Widget? infoPanel;

  const TabletLayoutContainer({
    super.key,
    required this.canvas,
    required this.algorithmPanel,
    required this.simulationPanel,
    this.infoPanel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Main Content Area (Canvas/Editor)
        Expanded(
          flex: 3, // 60% width
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: canvas,
          ),
        ),
        
        // Sidebar (Tabs)
        Expanded(
          flex: 2, // 40% width
          child: Container(
            margin: const EdgeInsets.fromLTRB(0, 16, 16, 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: DefaultTabController(
              length: infoPanel != null ? 3 : 2,
              child: Column(
                children: [
                  TabBar(
                    tabs: [
                      const Tab(text: 'Algorithms', icon: Icon(Icons.auto_awesome)),
                      const Tab(text: 'Simulation', icon: Icon(Icons.play_arrow)),
                      if (infoPanel != null)
                        const Tab(text: 'Info', icon: Icon(Icons.info_outline)),
                    ],
                    labelColor: Theme.of(context).colorScheme.primary,
                    unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
                    indicatorColor: Theme.of(context).colorScheme.primary,
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // Algorithms Tab
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: algorithmPanel,
                        ),
                        // Simulation Tab
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: simulationPanel,
                        ),
                        // Info Tab
                        if (infoPanel != null)
                          SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: infoPanel,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
