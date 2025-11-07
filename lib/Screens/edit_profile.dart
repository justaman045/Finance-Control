import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:money_control/Components/colors.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool _isLoading = false;

  // Fetch Firestore data for the current user
  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore.collection('users').doc(user.email).get();
      if (doc.exists) {
        final data = doc.data()!;
        _firstNameController.text = data['firstName'] ?? user.displayName;
        _lastNameController.text = data['lastName'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        _addressController.text = data['address'] ?? '';
      }
    } catch (e) {
      debugPrint("Error loading user data: $e");
    }
  }

  Future<void> _saveUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      await _firestore.collection('users').doc(user.email).set({
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'email': user.email, // auto from auth
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // keep existing fields

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error saving user data: $e");
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving profile: $e")),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isLight = scheme.brightness == Brightness.light;
    final hintColor =
    (isLight ? kLightTextSecondary : kDarkTextSecondary).withOpacity(0.85);
    final labelColor = scheme.onSurface;
    final border = BorderSide(
        color: isLight ? kLightBorder : kDarkBorder, width: 1.1.w);

    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: scheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        iconTheme: IconThemeData(color: scheme.onBackground),
        title: Text(
          "Edit Profile",
          style: TextStyle(
              fontWeight: FontWeight.w600,
              color: scheme.onBackground,
              fontSize: 17.sp),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios,
              size: 19.sp, color: scheme.onBackground),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 4.h),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 12.h),

              // Avatar
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 43.r,
                    backgroundColor: scheme.surface,
                    backgroundImage:
                    const AssetImage('assets/profile.png'),
                  ),
                  Positioned(
                    bottom: 5,
                    right: 4,
                    child: GestureDetector(
                      onTap: () {},
                      child: Container(
                        height: 27.r,
                        width: 27.r,
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          border: Border.all(
                              color: scheme.surface, width: 2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.edit,
                            size: 15.sp, color: scheme.onPrimary),
                      ),
                    ),
                  )
                ],
              ),

              SizedBox(height: 32.h),

              // Editable fields
              _buildEditableField(
                  label: "First Name",
                  controller: _firstNameController,
                  hintColor: hintColor,
                  labelColor: labelColor,
                  border: border),
              _buildEditableField(
                  label: "Last Name",
                  controller: _lastNameController,
                  hintColor: hintColor,
                  labelColor: labelColor,
                  border: border),
              _buildEditableField(
                  label: "Email",
                  value: user?.email ?? '',
                  enabled: false,
                  hintColor: hintColor,
                  labelColor: labelColor,
                  border: border),
              _buildEditableField(
                  label: "Phone Number",
                  controller: _phoneController,
                  hintColor: hintColor,
                  labelColor: labelColor,
                  border: border),
              _buildEditableField(
                  label: "Address",
                  controller: _addressController,
                  hintColor: hintColor,
                  labelColor: labelColor,
                  border: border),

              SizedBox(height: 32.h),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: scheme.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r)),
                  ),
                  onPressed: _saveUserData,
                  child: Text(
                    "Save Changes",
                    style: TextStyle(
                      color: scheme.onPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15.sp,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 20.h),

              // Change Password
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: scheme.primary,
                    side: BorderSide(color: scheme.primary, width: 1.4),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r)),
                  ),
                  onPressed: () async {
                    if (user != null) {
                      await _auth.sendPasswordResetEmail(email: user.email!);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Password reset link sent to your email')),
                      );
                    }
                  },
                  child: Text(
                    "Change Password",
                    style: TextStyle(
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15.sp,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 18.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditableField({
    required String label,
    TextEditingController? controller,
    String? value,
    bool enabled = true,
    required Color labelColor,
    required Color hintColor,
    required BorderSide border,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: labelColor,
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w500)),
        Container(
          margin: EdgeInsets.only(top: 4.h, bottom: 12.h),
          child: TextFormField(
            controller: controller,
            enabled: enabled,
            initialValue: controller == null ? value ?? '' : null,
            style: TextStyle(
                fontSize: 14.5.sp, color: hintColor, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              filled: false,
              hintText: '',
              border: UnderlineInputBorder(borderSide: border),
              focusedBorder: UnderlineInputBorder(borderSide: border),
            ),
          ),
        ),
      ],
    );
  }
}
