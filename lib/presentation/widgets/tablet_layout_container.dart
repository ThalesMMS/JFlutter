import 'package:flutter/material.dart';

class TabletLayoutContainer extends StatefulWidget {
  final Widget canvas;
  final Widget algorithmPanel;
  final Widget simulationPanel;
  final Widget? infoPanel;
  final String algorithmTabTitle;
  final String simulationTabTitle;
  final String infoTabTitle;

  const TabletLayoutContainer({
    super.key,
    required this.canvas,
    required this.algorithmPanel,
    required this.simulationPanel,
    this.infoPanel,
    this.algorithmTabTitle = 'Algorithms',
    this.simulationTabTitle = 'Simulation',
    this.infoTabTitle = 'Info',
  });

  @override
  State<TabletLayoutContainer> createState() => _TabletLayoutContainerState();
}

class _TabletLayoutContainerState extends State<TabletLayoutContainer> {
  bool _isSidebarExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Main Content Area (Canvas/Editor)
            Expanded(
              flex: _isSidebarExpanded ? 3 : 1,
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
                child: widget.canvas,
              ),
            ),

            // Sidebar (Tabs)
            if (_isSidebarExpanded)
              Expanded(
                flex: 2,
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
                    length: widget.infoPanel != null ? 3 : 2,
                    child: Column(
                      children: [
                        TabBar(
                          tabs: [
                            Tab(
                              text: widget.algorithmTabTitle,
                              icon: const Icon(Icons.auto_awesome),
                            ),
                            Tab(
                              text: widget.simulationTabTitle,
                              icon: const Icon(Icons.play_arrow),
                            ),
                            if (widget.infoPanel != null)
                              Tab(
                                text: widget.infoTabTitle,
                                icon: const Icon(Icons.info_outline),
                              ),
                          ],
                          labelColor: Theme.of(context).colorScheme.primary,
                          unselectedLabelColor: Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant,
                          indicatorColor: Theme.of(context).colorScheme.primary,
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              // Algorithms Tab
                              SingleChildScrollView(
                                padding: const EdgeInsets.all(16),
                                child: widget.algorithmPanel,
                              ),
                              // Simulation Tab
                              SingleChildScrollView(
                                padding: const EdgeInsets.all(16),
                                child: widget.simulationPanel,
                              ),
                              // Info Tab
                              if (widget.infoPanel != null)
                                SingleChildScrollView(
                                  padding: const EdgeInsets.all(16),
                                  child: widget.infoPanel,
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
        ),

        // Toggle Button
        Positioned(
          right: _isSidebarExpanded ? null : 16,
          left: _isSidebarExpanded
              ? null
              : null, // Handled by right alignment when collapsed
          top: 24,
          child: _isSidebarExpanded
              ? const SizedBox.shrink() // Don't show floating button when expanded, maybe put it inside sidebar?
              : FloatingActionButton.small(
                  onPressed: () => setState(() => _isSidebarExpanded = true),
                  child: const Icon(Icons.menu_open),
                ),
        ),

        // Collapse Button (inside sidebar if expanded)
        if (_isSidebarExpanded)
          Positioned(
            right: 24,
            top: 24,
            child: IconButton(
              icon: const Icon(Icons.close_fullscreen),
              tooltip: 'Collapse Sidebar',
              onPressed: () => setState(() => _isSidebarExpanded = false),
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
      ],
    );
  }
}
