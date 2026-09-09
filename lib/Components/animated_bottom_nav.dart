import 'package:flutter/material.dart';
import 'package:money_control/Components/bottom_nav_bar.dart';
import 'package:money_control/Config/tab_destinations.dart';

class AnimatedBottomNav extends StatelessWidget {
  final String currentTab;
  final List<TabDestination> destinations;
  final ValueNotifier<bool> isVisible;
  final Key? navBarKey;

  const AnimatedBottomNav({
    super.key,
    required this.currentTab,
    required this.destinations,
    required this.isVisible,
    this.navBarKey,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isVisible,
      builder: (context, visible, child) {
        return AnimatedSlide(
          duration: const Duration(milliseconds: 200),
          offset: visible ? Offset.zero : const Offset(0, 1),
          child: child,
        );
      },
      child: BottomNavBar(
        key: navBarKey,
        currentTab: currentTab,
        destinations: destinations,
      ),
    );
  }
}