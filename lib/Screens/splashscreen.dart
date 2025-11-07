import 'package:flutter/material.dart';
import 'package:money_control/Components/animated_widget.dart';
import 'package:money_control/Components/methods.dart';
import 'package:money_control/Models/splash_data.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:money_control/Screens/loginscreen.dart';

class AnimatedSplashScreen extends StatefulWidget {
  const AnimatedSplashScreen({super.key});
  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen> {
  static const List<SplashData> splashPages = [
    SplashData(
      bgColor: Color(0xFF2B2B8E),
      image: 'assets/salary.png',
      headline: 'Save your Money',
      subtitle:
          'Discover smart ways to manage your finances and grow your savings—start making your money work for you, effortlessly and securely.',
      buttonText: 'Get Started',
    ),
    SplashData(
      bgColor: Color(0xFF347EA3),
      image: 'assets/accounting.png',
      headline: 'Track Your Expenses',
      subtitle:
          'Monitor your spending habits effortlessly and take control of your financial goals in real time.',
      buttonText: 'Continue',
    ),
    SplashData(
      bgColor: Color(0xFF89BCE6),
      image: 'assets/wallet.png',
      headline: 'Fill Your Wallet not someone else',
      subtitle:
          'Take control of your earnings by working smarter and building your own success story.',
      buttonText: 'Let\'s Start',
    ),
  ];

  int currentIndex = 0;
  void _nextPage() {
    if (currentIndex < splashPages.length - 1) {
      setState(() => currentIndex++);
    } else {
      // Move to the next main screen (e.g., HomeScreen)
      // Get.to(() => BankingHomeScreen());
      // Or: Get.to(() => HomeScreen());
      gotoPage(LoginScreen());
    }
  }


  void _prevPage() {
    if (currentIndex > 0) {
      setState(() => currentIndex--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final splashData = splashPages[currentIndex];
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        color: splashData.bgColor,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 36.h),
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity != null &&
                    details.primaryVelocity! < 0) {
                  _nextPage();
                } else if (details.primaryVelocity != null &&
                    details.primaryVelocity! > 0) {
                  _prevPage();
                }
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      SizedBox(height: 60.h),
                      CAnimatedWidget(image: splashData.image),
                      SizedBox(height: 30.h),
                      CAnimatedWidget(
                        title: splashData.headline,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 33.r,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 20.h),
                      CAnimatedWidget(title: splashData.subtitle),
                    ],
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (child, animation) =>
                        FadeTransition(opacity: animation, child: child),
                    child: ElevatedButton(
                      key: ValueKey(splashData.buttonText),
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Text(
                        splashData.buttonText,
                        style: TextStyle(
                          color: splashData.bgColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
