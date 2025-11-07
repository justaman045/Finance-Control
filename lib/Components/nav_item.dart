import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class NavItem extends StatelessWidget {
  final bool active;
  final IconData icon;
  final String? label;
  final VoidCallback? onTap;

  const NavItem({
    super.key,
    required this.active,
    required this.icon,
    this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: onTap,
        child: Container(
          height: 38.h,
          padding: EdgeInsets.symmetric(horizontal: active ? 12.w : 0),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFE9F1FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Row(
            children: [
              Padding(
                padding: EdgeInsetsGeometry.symmetric(vertical: 10.h,  horizontal:  !active ? 15.w : 0),
                child: Icon(
                  icon,
                  color: active ? const Color(0xFF2F80ED) : Colors.grey,
                  size: 22.sp,
                ),
              ),
              if (active && label != null) ...[
                SizedBox(width: 6.w),
                Text(
                  label!,
                  style: TextStyle(
                    color: const Color(0xFF2F80ED),
                    fontWeight: FontWeight.w600,
                    fontSize: 13.sp,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
