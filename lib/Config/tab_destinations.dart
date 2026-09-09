import 'package:flutter/material.dart';
import 'package:money_control/Config/feature_flags.dart';
import 'package:money_control/Services/feature_flag_service.dart';

/// One entry in the app's root bottom navigation / rail. Keyed by [name] (not
/// index) so tabs can be hidden dynamically without renumbering: every nav
/// surface (bottom pill, wide rail, MainShell state) resolves these names.
class TabDestination {
  final String name;
  final String label;
  final IconData icon;

  /// Feature flag that gates this tab. Null = always available (Home/Settings).
  final String? featureKey;

  const TabDestination({
    required this.name,
    required this.label,
    required this.icon,
    this.featureKey,
  });
}

/// Canonical tab order. Renumbering (inserting/removing) is safe here because
/// every consumer is name-keyed.
const List<TabDestination> allTabs = [
  TabDestination(
    name: 'home',
    label: 'Home',
    icon: Icons.grid_view_rounded,
  ),
  TabDestination(
    name: 'analytics',
    label: 'Analytics',
    icon: Icons.pie_chart_outline_rounded,
    featureKey: 'analytics',
  ),
  TabDestination(
    name: 'insights',
    label: 'Insights',
    icon: Icons.auto_awesome_outlined,
    featureKey: 'ai_insights',
  ),
  TabDestination(
    name: 'wealth',
    label: 'Wealth',
    icon: Icons.monetization_on_outlined,
    featureKey: 'wealth',
  ),
  TabDestination(
    name: 'settings',
    label: 'Settings',
    icon: Icons.tune_rounded,
  ),
];

/// The tabs a user actually sees right now. `hidden` features are removed for
/// everyone (including admins) — "as if never there". Coming Soons stay: the
/// tab opens the ComingSoon placeholder when tapped.
List<TabDestination> visibleTabs() {
  final list = <TabDestination>[];
  for (final tab in allTabs) {
    final key = tab.featureKey;
    if (key == null ||
        FeatureFlagService.to.statusOf(key) != FeatureStatus.hidden) {
      list.add(tab);
    }
  }
  return list;
}