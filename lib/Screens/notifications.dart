import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:money_control/Components/colors.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  String formatTimestamp(Timestamp ts) {
    final date = ts.toDate();
    return DateFormat('dd/MM/yy | HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final user = FirebaseAuth.instance.currentUser;

    final Color gradientTop =
    scheme.brightness == Brightness.light ? kLightGradientTop : kDarkGradientTop;
    final Color gradientBottom =
    scheme.brightness == Brightness.light ? kLightGradientBottom : kDarkGradientBottom;

    if (user == null) {
      return Scaffold(
        body: Center(
          child: Text(
            "Not logged in",
            style: TextStyle(color: scheme.error, fontSize: 16.sp),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [gradientTop, gradientBottom],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: scheme.onBackground, size: 20.sp),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Text(
            "Notifications",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
              color: scheme.onBackground,
            ),
          ),
          centerTitle: true,
          toolbarHeight: 58.h,
        ),
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: 18.w),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .doc(user.email)
                .collection('user_notifications')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    "No notifications",
                    style: TextStyle(
                      color: scheme.onSurface.withOpacity(0.6),
                      fontSize: 14.sp,
                    ),
                  ),
                );
              }

              final docs = snapshot.data!.docs;

              return ListView.builder(
                padding: EdgeInsets.only(top: 14.h),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data()! as Map<String, dynamic>;

                  final title = data['title'] ?? "Notification";
                  final body = data['body'] ?? "";
                  final timestamp = data['timestamp'] as Timestamp?;

                  return Container(
                    margin: EdgeInsets.only(bottom: 20.h),
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(20.r),
                      boxShadow: [
                        BoxShadow(
                          color: scheme.onSurface.withOpacity(0.03),
                          blurRadius: 30.r,
                          offset: Offset(0, 6.h),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 22.r,
                              backgroundColor: Colors.transparent,
                              backgroundImage: const AssetImage('assets/profile.png'),
                            ),
                            SizedBox(width: 11.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15.sp,
                                      color: scheme.onSurface,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    body,
                                    style: TextStyle(
                                      fontSize: 13.5.sp,
                                      color: scheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10.h),
                        if (timestamp != null)
                          Text(
                            formatTimestamp(timestamp),
                            style: TextStyle(
                              color: scheme.onSurface.withOpacity(0.48),
                              fontSize: 11.5.sp,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
