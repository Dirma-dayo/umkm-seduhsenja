
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

class MouseNavigation extends StatelessWidget {
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;
  final bool enabled;

  const MouseNavigation({
    super.key,
    required this.child,
    required this.navigatorKey,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    return Listener(
      onPointerDown: (event) {
        if (event.kind != PointerDeviceKind.mouse) return;

        if ((event.buttons & kBackMouseButton) != 0) {
          navigatorKey.currentState?.maybePop();
        }
      },
      child: child,
    );
  }
}
