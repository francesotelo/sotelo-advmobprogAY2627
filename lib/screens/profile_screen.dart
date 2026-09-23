import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
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
  bool _isFirebaseUser = false;
  firebase_auth.User? _firebaseUser;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() async {
    final user = await _userService.getUser();
    final currentFbUser = _userService.currentUser;
    setState(() {
      _user = user;
      _firebaseUser = currentFbUser;
      _isFirebaseUser = currentFbUser != null;
    });
  }

  void _handleLogout() async {
    if (_isFirebaseUser) {
      await _userService.signOut();
    } else {
      await _userService.logout();
    }
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/signin');
    }
  }

  void _showUpdateUsernameDialog() {
    final TextEditingController controller = TextEditingController(
      text: _firebaseUser?.displayName ?? '',
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Username'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter new username',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await _userService.updateUsername(
                  username: controller.text.trim(),
                );
                if (mounted) {
                  Navigator.pop(context);
                  _loadUser();
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final TextEditingController currentPassController = TextEditingController();
    final TextEditingController newPassController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPassController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPassController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _userService.resetPasswordFromCurrentPassword(
                  currentPassword: currentPassController.text.trim(),
                  newPassword: newPassController.text.trim(),
                  email: _firebaseUser?.email ?? '',
                );
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password updated successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update password: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    final TextEditingController passController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This action cannot be undone. Enter your password to confirm.',
              style: TextStyle(color: Colors.redAccent),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await _userService.deleteAccount(
                  email: _firebaseUser?.email ?? '',
                  password: passController.text.trim(),
                );
                if (mounted) {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/signin');
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete account: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null && !_isFirebaseUser) {
      return const Center(child: CircularProgressIndicator());
    }

    final displayName = _isFirebaseUser
        ? (_firebaseUser?.displayName ?? 'Firebase User')
        : '${_user?.firstName ?? ''} ${_user?.lastName ?? ''}'.trim();

    final usernameTag = _isFirebaseUser
        ? (_firebaseUser?.email?.split('@').first ?? 'user')
        : (_user?.username ?? '');

    final emailText =
        _isFirebaseUser ? (_firebaseUser?.email ?? '') : (_user?.email ?? '');

    final photoUrl = _isFirebaseUser ? _firebaseUser?.photoURL : _user?.image;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3949AB),
        title: CustomText(
          text: _isFirebaseUser
              ? 'Firebase Profile'
              : (_user?.firstName ?? 'Profile'),
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
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                          ? NetworkImage(photoUrl)
                          : null,
                      child: (photoUrl == null || photoUrl.isEmpty)
                          ? Icon(Icons.person, size: 50.r, color: Colors.grey)
                          : null,
                    ),
                    SizedBox(height: 16.h),
                    CustomText(
                      text: displayName.isNotEmpty ? displayName : 'User',
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    SizedBox(height: 8.h),
                    CustomText(
                      text: '@$usernameTag',
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
                    leading:
                        const Icon(Icons.email, color: Colors.orangeAccent),
                    title: const CustomText(
                        text: 'Email', fontWeight: FontWeight.bold),
                    trailing: CustomText(text: emailText, color: Colors.grey),
                  ),
                  if (!_isFirebaseUser && _user != null) ...[
                    const Divider(height: 1),
                    ListTile(
                      leading:
                          const Icon(Icons.people, color: Colors.orangeAccent),
                      title: const CustomText(
                          text: 'Gender', fontWeight: FontWeight.bold),
                      trailing:
                          CustomText(text: _user!.gender, color: Colors.grey),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading:
                          const Icon(Icons.badge, color: Colors.orangeAccent),
                      title: const CustomText(
                          text: 'User ID', fontWeight: FontWeight.bold),
                      trailing:
                          CustomText(text: '#${_user!.id}', color: Colors.grey),
                    ),
                  ],
                  if (_isFirebaseUser) ...[
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.verified_user,
                          color: Colors.orangeAccent),
                      title: const CustomText(
                          text: 'Auth Provider', fontWeight: FontWeight.bold),
                      trailing: const CustomText(
                          text: 'Firebase', color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
            if (_isFirebaseUser) ...[
              SizedBox(height: 16.h),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.edit, color: Color(0xFF3949AB)),
                      title: const CustomText(
                          text: 'Update Username', fontWeight: FontWeight.w600),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _showUpdateUsernameDialog,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.lock_reset,
                          color: Color(0xFF3949AB)),
                      title: const CustomText(
                          text: 'Change Password', fontWeight: FontWeight.w600),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _showChangePasswordDialog,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading:
                          const Icon(Icons.delete_forever, color: Colors.red),
                      title: const CustomText(
                        text: 'Delete Account',
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                      trailing:
                          const Icon(Icons.chevron_right, color: Colors.red),
                      onTap: _showDeleteAccountDialog,
                    ),
                  ],
                ),
              ),
            ],
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
                label: const CustomText(
                  text: 'Log Out',
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
