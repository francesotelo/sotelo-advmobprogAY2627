import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  User? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() async {
    final user = await _userService.getUser();
    setState(() {
      _user = user;
    });
  }

  void _handleLogout() async {
    await _userService.logout();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/signin');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3949AB),
        title: CustomText(
          text: _user!.firstName,
          color: Colors.white,
          fontSize: 20.sp,
          fontWeight: FontWeight.bold,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.r),
        child: Column(
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Padding(
                padding: EdgeInsets.all(24.r),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50.r,
                      backgroundImage: NetworkImage(_user!.image),
                      backgroundColor: Colors.transparent,
                    ),
                    SizedBox(height: 16.h),
                    CustomText(
                      text: '${_user!.firstName} ${_user!.lastName}',
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    SizedBox(height: 8.h),
                    CustomText(
                      text: '@${_user!.username}',
                      color: Colors.orangeAccent,
                      fontSize: 14.sp,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.email, color: Colors.orangeAccent),
                    title: CustomText(text: 'Email', fontWeight: FontWeight.bold),
                    trailing: CustomText(text: _user!.email, color: Colors.grey),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.people, color: Colors.orangeAccent),
                    title: CustomText(text: 'Gender', fontWeight: FontWeight.bold),
                    trailing: CustomText(text: _user!.gender, color: Colors.grey),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.badge, color: Colors.orangeAccent),
                    title: CustomText(text: 'User ID', fontWeight: FontWeight.bold),
                    trailing: CustomText(text: '#${_user!.id}', color: Colors.grey),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              height: 50.h,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6347),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                onPressed: _handleLogout,
                icon: const Icon(Icons.logout, color: Colors.white),
                label: CustomText(
                  text: 'Log Out',
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}