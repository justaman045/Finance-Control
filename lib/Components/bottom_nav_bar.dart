import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:money_control/Components/methods.dart';
import 'package:money_control/Components/nav_item.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  const BottomNavBar({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 13.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 16.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          NavItem(
            active: currentIndex == 0,
            icon: Icons.home_rounded,
            label: 'Home',
            onTap: () => gotoScreen(0, currentIndex),
          ),
          NavItem(
            active: currentIndex == 1,
            icon: Icons.analytics_outlined,
            label: 'Analysis',
            onTap: () => gotoScreen(1, currentIndex),
          ),
          NavItem(
            active: currentIndex == 2,
            icon: Icons.insights_rounded,
            label: 'AI Insights',
            onTap: () => gotoScreen(2, currentIndex),
          ),
          NavItem(
            active: currentIndex == 3,
            icon: Icons.settings,
            label: 'Settings',
            onTap: () => gotoScreen(3, currentIndex),
          ),
        ],
      ),
    );
  }
}
