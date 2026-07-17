import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/active_session_provider.dart';

class ActiveSessionLifecycle extends ConsumerStatefulWidget {
  const ActiveSessionLifecycle({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ActiveSessionLifecycle> createState() =>
      _ActiveSessionLifecycleState();
}

class _ActiveSessionLifecycleState extends ConsumerState<ActiveSessionLifecycle>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      unawaited(
        ref
            .read(activeSessionPersistenceProvider.notifier)
            .flush()
            .catchError((Object error, StackTrace stackTrace) {
          debugPrint(
              'Failed to flush active session on lifecycle change: $error');
          debugPrintStack(stackTrace: stackTrace);
        }),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(activeSessionPersistenceProvider);
    return widget.child;
  }
}
