import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TutorialController extends GetxController {
  late TutorialCoachMark tutorialCoachMark;

  // Global Keys for targets
  final keyBalance = GlobalKey();
  final keyQuickSend = GlobalKey();
  final keyRecentTx = GlobalKey();
  final keyDailyLimit = GlobalKey();

  Future<void> showTutorial(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final bool isDone = prefs.getBool('onboarding_done') ?? false;

    if (isDone) return; // Already triggered

    // Delay to let UI build
    await Future.delayed(const Duration(seconds: 1));
    if (!context.mounted) return;

    _initTutorial(context);
    tutorialCoachMark.show(context: context);

    // Mark as done
    await prefs.setBool('onboarding_done', true);
  }

  void _initTutorial(BuildContext context) {
    tutorialCoachMark = TutorialCoachMark(
      targets: _createTargets(),
      colorShadow: Colors.black,
      textSkip: "SKIP",
      paddingFocus: 10,
      opacityShadow: 0.8,
      onSkip: () {
        return true;
      },
    );
  }

  List<TargetFocus> _createTargets() {
    List<TargetFocus> targets = [];

    // Balance Card Target
    targets.add(
      TargetFocus(
        identify: "Target 1",
        keyTarget: keyBalance,
        alignSkip: Alignment.topRight,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return _buildTutorialText(
                "Total Balance",
                "Your total combined balance from all wallets is shown here. Tap to investigate deeply.",
              );
            },
          ),
        ],
      ),
    );

    // Quick Send Target
    targets.add(
      TargetFocus(
        identify: "Target 2",
        keyTarget: keyQuickSend,
        alignSkip: Alignment.topRight,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return _buildTutorialText(
                "Quick Send",
                "Tap a friend to instantly send money.",
              );
            },
          ),
        ],
      ),
    );

    // Recent Tx Target
    targets.add(
      TargetFocus(
        identify: "Target 3",
        keyTarget: keyRecentTx,
        alignSkip: Alignment.topRight,
        contents: [
          TargetContent(
            align: ContentAlign.top, // Show above
            builder: (context, controller) {
              return _buildTutorialText(
                "Recent Activity",
                "See your latest transactions here. Tap 'See All' for full history.",
              );
            },
          ),
        ],
      ),
    );

    return targets;
  }

  Widget _buildTutorialText(String title, String content) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: const Color(0xFF000000), // Solid Black
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: const Color(0xFF00E5FF),
            width: 2,
          ), // Neon Border
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 20.sp,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              content,
              style: TextStyle(
                color: Colors.white,
                fontSize: 15.sp,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
