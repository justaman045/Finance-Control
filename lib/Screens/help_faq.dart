import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:money_control/Components/bottom_nav_bar.dart';
import 'package:money_control/Components/colors.dart';

class HelpFAQScreen extends StatefulWidget {
  const HelpFAQScreen({super.key});

  @override
  State<HelpFAQScreen> createState() => _HelpFAQScreenState();
}

class _HelpFAQScreenState extends State<HelpFAQScreen> {
  int? openedIndex;

  final List<Map<String, String>> faqs = [
    {
      "q": "How do I add a new transaction?",
      "a":
      "Tap the '+' or 'Add Transaction' button on the Home screen or the Quick Send section. Fill the details and tap 'Save'."
    },
    {
      "q": "How do I edit or delete an existing transaction?",
      "a":
      "Open any transaction in your history and use the edit or delete options on the top right."
    },
    {
      "q": "How do I manage or add custom categories?",
      "a":
      "You can add categories when adding/editing a transaction using the category dropdown."
    },
    {
      "q": "Does the app work offline?",
      "a":
      "Yes! All changes will be saved locally and synced automatically once you're online again."
    },
    {
      "q": "How do I switch between Dark and Light mode?",
      "a": "Go to Settings → Dark Mode to toggle theme appearance."
    },
    {
      "q": "Can I export or download my transaction history?",
      "a":
      "Data export is coming soon! For now, you can share screenshots of individual transactions."
    },
    {
      "q": "How do I reset my password?",
      "a":
      "Go to Settings → Change Password. A reset link will be emailed to you."
    },
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isLight = scheme.brightness == Brightness.light;

    final gradientTop = isLight ? kLightGradientTop : kDarkGradientTop;
    final gradientBottom = isLight ? kLightGradientBottom : kDarkGradientBottom;
    final border = isLight ? kLightBorder : kDarkBorder;
    final surface = scheme.surface;
    final secondaryText =
    isLight ? kLightTextSecondary : kDarkTextSecondary;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [gradientTop, gradientBottom],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text(
            "Help / FAQ",
            style: TextStyle(
              color: scheme.onBackground,
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios,
                color: scheme.onBackground, size: 20.sp),
            onPressed: () => Navigator.pop(context),
          ),
          toolbarHeight: 64.h,
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 8.h),
          child: Column(
            children: [
              ...List.generate(
                faqs.length,
                    (index) => _FAQTile(
                  question: faqs[index]["q"]!,
                  answer: faqs[index]["a"]!,
                  isOpen: openedIndex == index,
                  border: border,
                  surface: surface,
                  onTap: () {
                    setState(() {
                      openedIndex = openedIndex == index ? null : index;
                    });
                  },
                ),
              ),
              SizedBox(height: 30.h),

              // Contact section
              Center(
                child: Text(
                  "Still have questions?\nContact support at:",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: secondaryText,
                    fontSize: 13.sp,
                  ),
                ),
              ),
              SizedBox(height: 6.h),
              SelectableText(
                "work.amanojha30@gmail.com",
                style: TextStyle(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14.sp,
                ),
              ),
              SizedBox(height: 24.h),
            ],
          ),
        ),
        bottomNavigationBar: const BottomNavBar(currentIndex: 2),
      ),
    );
  }
}

class _FAQTile extends StatelessWidget {
  final String question;
  final String answer;
  final bool isOpen;
  final VoidCallback onTap;
  final Color border;
  final Color surface;

  const _FAQTile({
    required this.question,
    required this.answer,
    required this.isOpen,
    required this.onTap,
    required this.border,
    required this.surface,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        margin: EdgeInsets.only(bottom: 14.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question Row
            Row(
              children: [
                Expanded(
                  child: Text(
                    question,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15.sp,
                      color: scheme.primary,
                    ),
                  ),
                ),
                Icon(
                  isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: scheme.primary,
                )
              ],
            ),

            // Animated Answer
            AnimatedCrossFade(
              firstChild: const SizedBox(),
              secondChild: Padding(
                padding: EdgeInsets.only(top: 6.h),
                child: Text(
                  answer,
                  style: TextStyle(
                    color: scheme.onSurface.withOpacity(0.9),
                    fontSize: 13.5.sp,
                    height: 1.38,
                  ),
                ),
              ),
              crossFadeState: isOpen
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 220),
            ),
          ],
        ),
      ),
    );
  }
}
